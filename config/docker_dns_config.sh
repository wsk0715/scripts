#!/usr/bin/env bash
set -euo pipefail
# ===================================================
# oci_docker_dns_resolve.sh — OCI VM Docker DNS 진단/수리
# ===================================================
# OCI VM에서 Docker 컨테이너 DNS가 동작하지 않는 문제를
# 진단하고 수정합니다.
#
# 문제 원인:
#   Docker 재시작 시 DOCKER-USER 체인이 초기화되어
#   RELATED,ESTABLISHED 규칙이 사라짐 → DNS 응답 차단
#
# 사용법:
#   sudo bash config/docker_dns_config.sh        # 진단+수리
#   sudo bash config/docker_dns_config.sh --check # 진단만
#   sudo bash config/docker_dns_config.sh --fix   # 수리만
# ===================================================
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅${NC} $1"; }
fail() { echo -e "  ${RED}❌${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC} $1"; }
info() { echo -e "  ${CYAN}ℹ️${NC} $1"; }

DO_FIX=true
if [[ "${1:-}" == "--check" ]]; then DO_FIX=false; fi
if [[ "${1:-}" == "--fix" ]]; then DO_FIX=true; fi

# nsenter wrapper: 호스트 netns에서 iptables 실행
ipt() { nsenter -t 1 -n -- iptables-legacy "$@"; }
ipt_save() { nsenter -t 1 -n -- netfilter-persistent save 2>/dev/null || \
             nsenter -t 1 -n -- iptables-save > /etc/iptables/rules.v4; }

echo "============================================="
echo "  OCI Docker DNS 진단/수리 스크립트"
echo "============================================="
echo ""

# ----- 1. 환경 진단 -----
echo "[1/5] 환경 진단"
echo ""

# Docker 실행 확인
if pidof dockerd &>/dev/null; then
  ok "Docker daemon 실행 중"
else
  fail "Docker daemon 실행 안 됨"
  exit 1
fi

# iptables 모드 확인
IPT_MODE=$(ipt --version 2>/dev/null || echo "unknown")
info "iptables 모드: $IPT_MODE"

# DOCKER-USER 체인 존재 확인
if ipt -L DOCKER-USER -n &>/dev/null; then
  ok "DOCKER-USER 체인 존재"
else
  fail "DOCKER-USER 체인 없음 (Docker iptables 문제)"
fi

# DOCKER-USER 규칙 수
RULE_COUNT=$(ipt -L DOCKER-USER -n --line-numbers 2>/dev/null | grep -c "^[0-9]" || true)
info "DOCKER-USER 규칙 수: $RULE_COUNT"

# RELATED,ESTABLISHED 규칙 확인
if ipt -C DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then
  ok "DOCKER-USER: RELATED,ESTABLISHED 허용됨"
  RETEST_OK=true
else
  fail "DOCKER-USER: RELATED,ESTABLISHED 규칙 없음"
  RETEST_OK=false
fi

# 기본 DROP 규칙 확인
if ipt -C DOCKER-USER -j DROP 2>/dev/null; then
  ok "DOCKER-USER: 기본 DROP 있음 (방화벽 활성)"
else
  warn "DOCKER-USER: 기본 DROP 없음 (방화벽 미적용)"
fi

# INPUT 정책 확인
INPUT_POLICY=$(ipt -L INPUT -n 2>/dev/null | head -1 | awk '{print $4}')
info "INPUT 정책: $INPUT_POLICY"

# NAT MASQUERADE 확인
if ipt -t nat -C POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE 2>/dev/null; then
  ok "NAT MASQUERADE 정상"
else
  warn "NAT MASQUERADE 규칙 없음 (Docker 네트워크 문제)"
fi

# netfilter-persistent 서비스 확인
NP_STATUS=$(nsenter -t 1 -n -- systemctl is-active netfilter-persistent 2>/dev/null || echo "inactive")
NP_ENABLED=$(nsenter -t 1 -n -- systemctl is-enabled netfilter-persistent 2>/dev/null || echo "disabled")
info "netfilter-persistent: $NP_STATUS / $NP_ENABLED"

echo ""

# ----- 2. DNS 연결성 테스트 -----
echo "[2/5] DNS 연결성 테스트"
echo ""

# 호스트 DNS
if host files.pythonhosted.org 8.8.8.8 &>/dev/null; then
  ok "호스트 → 8.8.8.8:53"
else
  warn "호스트 → 8.8.8.8:53 실패"
fi

# 컨테이너 DNS
CID=$(docker run -d --rm alpine:3.19 sleep 30 2>/dev/null || true)
if [[ -n "$CID" ]]; then
  if docker exec "$CID" nslookup files.pythonhosted.org 8.8.8.8 &>/dev/null; then
    ok "컨테이너 → 8.8.8.8:53 (bridge)"
  else
    fail "컨테이너 → 8.8.8.8:53 타임아웃"
  fi
  docker kill "$CID" &>/dev/null || true
else
  warn "테스트 컨테이너 실행 실패"
fi

# Docker embedded DNS
if docker run --rm alpine:3.19 nslookup files.pythonhosted.org &>/dev/null; then
  ok "Docker embedded DNS (127.0.0.11)"
else
  fail "Docker embedded DNS 실패"
fi

echo ""

# ----- 3. Docker daemon DNS 설정 진단 -----
echo "[3/5] Docker daemon DNS 설정"
echo ""

DAEMON_JSON=$(nsenter -t 1 -n -- cat /etc/docker/daemon.json 2>/dev/null || echo "{}")
info "daemon.json: $DAEMON_JSON"

# VCN internal DNS 확인
VCN_ROUTER=$(curl -s --connect-timeout 2 http://169.254.169.254/opc/v1/vnics/ 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0].get('virtualRouterIp','unknown'))" 2>/dev/null || echo "unknown")
info "VCN 라우터 IP: $VCN_ROUTER"

echo ""

# ----- 4. 수리 (--check면 스킵) -----
echo "[4/5] 수리"
echo ""

if [[ "$DO_FIX" == "true" ]]; then
  NEED_SAVE=false

  # DOCKER-USER: RELATED,ESTABLISHED 추가
  if ! ipt -C DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then
    ipt -I DOCKER-USER 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    ok "DOCKER-USER #1: RELATED,ESTABLISHED 허용 추가"
    NEED_SAVE=true
  fi

  # DOCKER-USER: 사설망 허용
  for net in "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"; do
    if ! ipt -C DOCKER-USER -s "$net" -j ACCEPT 2>/dev/null; then
      # I 규칙보다 앞에 추가 (순서: 2,3,4)
      ipt -I DOCKER-USER 2 -s "$net" -j ACCEPT 2>/dev/null || true
      ok "DOCKER-USER: $net 허용 추가"
      NEED_SAVE=true
    fi
  done

  # DOCKER-USER: HTTP/HTTPS 허용
  for port in 80 443; do
    if ! ipt -C DOCKER-USER -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
      ipt -A DOCKER-USER -p tcp --dport "$port" -j ACCEPT 2>/dev/null || true
      ok "DOCKER-USER: tcp/$port 허용 추가"
      NEED_SAVE=true
    fi
  done

  # DOCKER-USER: 기본 DROP (마지막)
  if ! ipt -C DOCKER-USER -j DROP 2>/dev/null; then
    ipt -A DOCKER-USER -j DROP 2>/dev/null || true
    ok "DOCKER-USER: 기본 DROP 추가"
    NEED_SAVE=true
  fi

  # INPUT 정책이 ACCEPT면 설정 스킵 (방화벽 끈 상태로 유지)
  # (firewall_setup.sh에서 관리)

  if [[ "$NEED_SAVE" == "true" ]]; then
    ipt_save
    ok "iptables 규칙 저장 완료"
  else
    info "수정할 규칙 없음 (이미 정상)"
  fi
else
  info "--check 모드: 수리 생략"
fi

echo ""

# ----- 5. 최종 검증 -----
echo "[5/5] 최종 검증"
echo ""

echo "  DOCKER-USER 체인:"
ipt -L DOCKER-USER -v -n --line-numbers 2>&1 | while IFS= read -r line; do
  echo "    $line"
done
echo ""

CID2=$(docker run -d --rm alpine:3.19 sleep 10 2>/dev/null || true)
if [[ -n "$CID2" ]]; then
  if docker exec "$CID2" nslookup files.pythonhosted.org 8.8.8.8 &>/dev/null; then
    ok "✅ DNS 최종 테스트 통과"
  else
    fail "❌ DNS 최종 테스트 실패"
  fi
  docker kill "$CID2" &>/dev/null || true
fi

echo ""
echo "============================================="
echo "  완료"
echo "============================================="
