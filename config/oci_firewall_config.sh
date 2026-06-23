#!/usr/bin/env bash
set -euo pipefail
# ===================================================
# oci_firewall.sh — OCI VM 방화벽 관리 인터페이스
# ===================================================
# OCI VM의 iptables 방화벽 상태를 확인하고
# 화이트리스트 모드로 설정/해제합니다.
#
# 사용법:
#   sudo bash config/oci_firewall_config.sh          # 대화형 메뉴
#   sudo bash config/oci_firewall_config.sh status   # 상태 확인
#   sudo bash config/oci_firewall_config.sh on       # 방화벽 켜기
#   sudo bash config/oci_firewall_config.sh off      # 방화벽 끄기
# ===================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅${NC} $1"; }
fail() { echo -e "  ${RED}❌${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC} $1"; }
info() { echo -e "  ${CYAN}ℹ️${NC} $1"; }

# nsenter wrapper
ipt()   { nsenter -t 1 -n -- iptables-legacy "$@"; }
ipt_save() { nsenter -t 1 -n -- netfilter-persistent save 2>/dev/null || \
             nsenter -t 1 -n -- iptables-save > /etc/iptables/rules.v4; }

# ============================================================
# 진단
# ============================================================
diagnose() {
  echo ""
  echo "============================================="
  echo "  🔍 방화벽 상태 진단"
  echo "============================================="
  echo ""

  # INPUT 정책
  local input_policy
  input_policy=$(ipt -L INPUT -n 2>/dev/null | head -1 | awk '{print $4}')
  if [[ "$input_policy" == "DROP" ]]; then
    ok "INPUT 정책: DROP (화이트리스트 모드)"
  else
    warn "INPUT 정책: ACCEPT (모든 인바운드 허용)"
  fi

  echo "  INPUT 규칙:"
  ipt -L INPUT -v -n --line-numbers 2>/dev/null | while IFS= read -r line; do echo "    $line"; done
  echo ""

  # DOCKER-USER 체인
  echo "  DOCKER-USER 규칙:"
  local rule_count
  rule_count=$(ipt -L DOCKER-USER -n --line-numbers 2>/dev/null | grep -c "^[0-9]" || echo 0)
  if [[ "$rule_count" -gt 0 ]]; then
    ok "DOCKER-USER 규칙 $rule_count 개 활성"
  else
    warn "DOCKER-USER 규칙 없음 (Docker 포트 모두 개방)"
  fi
  ipt -L DOCKER-USER -v -n --line-numbers 2>/dev/null | while IFS= read -r line; do echo "    $line"; done
  echo ""

  # NAT MASQUERADE
  echo "  NAT MASQUERADE:"
  ipt -t nat -L POSTROUTING -v -n 2>/dev/null | grep MASQUERADE | while IFS= read -r line; do echo "    $line"; done
  echo ""

  # netfilter-persistent
  local np_status np_enabled
  np_status=$(nsenter -t 1 -n -- systemctl is-active netfilter-persistent 2>/dev/null || echo "inactive")
  np_enabled=$(nsenter -t 1 -n -- systemctl is-enabled netfilter-persistent 2>/dev/null || echo "disabled")
  if [[ "$np_status" == "active" ]]; then
    ok "netfilter-persistent: $np_status / $np_enabled"
  else
    warn "netfilter-persistent: $np_status / $np_enabled"
  fi

  # rules.v4 존재 확인
  if [[ -f /etc/iptables/rules.v4 ]]; then
    local saved_time
    saved_time=$(stat -c "%y" /etc/iptables/rules.v4 2>/dev/null | cut -d. -f1)
    ok "rules.v4 저장됨 (${saved_time})"
  else
    fail "rules.v4 없음 — 재부팅 시 규칙 소멸"
  fi

  # Docker DNS
  if docker run --rm alpine:3.19 nslookup files.pythonhosted.org &>/dev/null; then
    ok "컨테이너 DNS 정상"
  else
    fail "컨테이너 DNS 실패"
  fi
  echo ""
}

# ============================================================
# 방화벽 켜기 (화이트리스트 모드)
# ============================================================
firewall_on() {
  echo ""
  echo "🔒 방화벽 화이트리스트 모드 활성화"
  echo ""

  # 1. INPUT 정책 DROP
  ipt -P INPUT DROP
  ok "INPUT 정책: DROP"

  # 2. INPUT 규칙 (이미 flush되어 있을 수 있으니 다시 추가)
  ipt -F INPUT 2>/dev/null || true
  ipt -A INPUT -i lo -j ACCEPT
  ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ipt -A INPUT -p tcp --dport 22 -j ACCEPT
  ipt -A INPUT -p tcp --dport 80 -j ACCEPT
  ipt -A INPUT -p tcp --dport 443 -j ACCEPT
  ipt -A INPUT -p tcp --dport 6443 -j ACCEPT
  ipt -A INPUT -p tcp --dport 5000 -j ACCEPT
  ipt -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
  ok "INPUT: loopback, established, SSH(22), HTTP(80), HTTPS(443), K3s(6443), Registry(5000), ICMP 허용"

  # 3. DOCKER-USER: DNS 응답을 위한 RELATED,ESTABLISHED
  ipt -F DOCKER-USER 2>/dev/null || true
  ipt -I DOCKER-USER 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  ok "DOCKER-USER #1: RELATED,ESTABLISHED (DNS 응답 등)"

  # 4. DOCKER-USER: 사설망 (컨테이너 간 통신, 내부망)
  ipt -I DOCKER-USER 2 -s 10.0.0.0/8 -j ACCEPT
  ipt -I DOCKER-USER 3 -s 172.16.0.0/12 -j ACCEPT
  ipt -I DOCKER-USER 4 -s 192.168.0.0/16 -j ACCEPT
  ok "DOCKER-USER: 사설망(10/8, 172.16/12, 192.168/16) 허용"

  # 5. DOCKER-USER: HTTP/HTTPS (외부 → ingress)
  ipt -I DOCKER-USER 5 -p tcp --dport 80 -j ACCEPT
  ipt -I DOCKER-USER 6 -p tcp --dport 443 -j ACCEPT
  ok "DOCKER-USER: HTTP(80), HTTPS(443) 허용"

  # 6. DOCKER-USER: 나머지 DROP
  ipt -A DOCKER-USER -j DROP
  ok "DOCKER-USER: 나머지 DROP (published ports 차단)"

  # 7. 저장
  ipt_save
  ok "iptables 규칙 저장 완료"
  echo ""
  echo "  최종 DOCKER-USER 상태:"
  ipt -L DOCKER-USER -v -n --line-numbers 2>/dev/null | while IFS= read -r line; do echo "    $line"; done
  echo ""
}

# ============================================================
# 방화벽 끄기 (모든 허용)
# ============================================================
firewall_off() {
  echo ""
  echo "🔓 방화벽 해제 (모든 트래픽 허용)"
  echo ""

  # 1. INPUT 정책 ACCEPT
  ipt -P INPUT ACCEPT
  ipt -F INPUT
  ok "INPUT 정책: ACCEPT, 규칙 초기화"

  # 2. DOCKER-USER 초기화 (Docker 기본값: 빈 체인)
  ipt -F DOCKER-USER 2>/dev/null || true
  ok "DOCKER-USER: 규칙 초기화 (Docker 포트 개방)"

  # 3. 저장
  ipt_save
  ok "iptables 규칙 저장 완료"
  echo ""
}

# ============================================================
# rules.v4 복원 (저장된 규칙 재적용)
# ============================================================
restore_rules() {
  echo ""
  echo "📦 저장된 규칙(rules.v4) 복원"
  echo ""

  if [[ ! -f /etc/iptables/rules.v4 ]]; then
    fail "/etc/iptables/rules.v4 없음"
    return 1
  fi

  # netfilter-persistent reload로 복원
  nsenter -t 1 -n -- netfilter-persistent reload 2>&1
  ok "netfilter-persistent reload 완료"

  # DOCKER-USER 재확인 (Docker가 리셋할 수 있으므로)
  # RELATED,ESTABLISHED 규칙이 없으면 다시 추가
  if ! ipt -C DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then
    # Docker 재시작 후 DOCKER-USER가 초기화되었을 수 있음
    ipt -I DOCKER-USER 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    ok "DOCKER-USER: RELATED,ESTABLISHED 보강 추가"
    ipt_save
  fi
  echo ""
}

# ============================================================
# 대화형 메뉴
# ============================================================
interactive_menu() {
  while true; do
    clear
    echo ""
    echo "============================================="
    echo "  🛡️  OCI VM 방화벽 관리"
    echo "============================================="
    echo ""
    echo "  (s) status  — 현재 방화벽 상태 진단"
    echo "  (1) on      — 방화벽 화이트리스트 모드 ON"
    echo "  (2) off     — 방화벽 OFF (모두 허용)"
    echo "  (3) restore — 저장된 rules.v4 복원"
    echo "  (q) quit    — 종료"
    echo ""
    read -rp "  선택: " choice

    case "$choice" in
      s|status)  diagnose ;;
      1|on)      firewall_on ;;
      2|off)     firewall_off ;;
      3|restore) restore_rules ;;
      q|quit)    echo ""; echo "  종료합니다."; break ;;
      *)         warn "올바른 옵션을 선택하세요"; sleep 1 ;;
    esac

    echo ""
    echo "  (Enter 누르면 메뉴로 돌아갑니다)"
    read -r
  done
}

# ============================================================
# 메인
# ============================================================
main() {
  if [[ $EUID -ne 0 ]]; then
    fail "root 권한이 필요합니다 (sudo)"
    exit 1
  fi

  case "${1:-}" in
    status|--status|-s)   diagnose ;;
    on|--on|-1)           firewall_on ;;
    off|--off|-0)         firewall_off ;;
    restore|--restore|-r) restore_rules ;;
    ""|menu|--menu|-m)    interactive_menu ;;
    *)                    echo "사용법: $0 {status|on|off|restore|menu}"; exit 1 ;;
  esac
}

main "$@"
