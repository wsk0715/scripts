#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/apt_lib.sh"

echo "============================================"
echo "  Firewall setup — whitelist mode"
echo "============================================"

echo ""
echo "[1/6] Removing UFW..."
sudo systemctl stop ufw 2>/dev/null || true
apt_remove_packages ufw 2>/dev/null || true
echo "  -> UFW removed"

echo ""
echo "[2/6] Flushing existing INPUT rules..."
sudo iptables -F INPUT
echo "  -> INPUT rules flushed"

echo ""
echo "[3/6] Setting default INPUT policy to DROP..."
sudo iptables -P INPUT DROP
echo "  -> Default INPUT policy: DROP (block everything by default)"

echo ""
echo "[4/6] Allowing whitelisted traffic..."
# Loopback (localhost 통신)
sudo iptables -A INPUT -i lo -j ACCEPT
echo "  -> loopback allowed"

# Established connections (기존 SSH 세션 유지)
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
echo "  -> established/related allowed"

# SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
echo "  -> SSH (22) allowed"

# HTTP
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
echo "  -> HTTP (80) allowed"

# HTTPS
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
echo "  -> HTTPS (443) allowed"

# ICMP (ping)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
echo "  -> ICMP (ping) allowed"

echo ""
echo "[5/6] Securing Docker published ports..."
# DOCKER-USER: Docker publish된 포트는 INPUT이 아닌 FORWARD/DOCKER-USER를 탐
# 순서 중요: 위에서부터 아래로 평가 → 응답 우선, 사설망, HTTP/S, 나머지 차단
sudo iptables -F DOCKER-USER 2>/dev/null || true
# 1. 응답 패킷 우선 허용 (DNS 응답, established connections — 없으면 외부 통신 불가)
sudo iptables -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# 2. 사설망 전면 허용 (컨테이너 간 통신, VCN 내부 통신)
sudo iptables -A DOCKER-USER -s 10.0.0.0/8 -j ACCEPT
sudo iptables -A DOCKER-USER -s 172.16.0.0/12 -j ACCEPT
sudo iptables -A DOCKER-USER -s 192.168.0.0/16 -j ACCEPT
# 3. 80/443은 외부에서 ingress-nginx 접근을 위해 허용
sudo iptables -A DOCKER-USER -p tcp --dport 80 -j ACCEPT
sudo iptables -A DOCKER-USER -p tcp --dport 443 -j ACCEPT
# 4. 나머지 Docker published ports 전부 차단
sudo iptables -A DOCKER-USER -j DROP
echo "  -> Docker published ports secured"

echo ""
echo "[6/6] Saving rules..."
sudo netfilter-persistent save
sudo netfilter-persistent reload

echo ""
echo "============================================"
echo "  Done! Firewall configured (whitelist)."
echo "  Allowed: SSH(22), HTTP(80), HTTPS(443)"
echo "============================================"
echo ""
sudo iptables -L INPUT --line-numbers -n
echo ""
sudo iptables -L DOCKER-USER --line-numbers -n
