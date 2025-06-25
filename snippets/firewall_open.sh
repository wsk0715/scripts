#!/bin/bash

# ------------------------------------------------------------
# 방화벽 설정 스크립트
# ------------------------------------------------------------

set -e

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../libs/network_lib.sh"
source "$SCRIPT_DIR/../libs/service_lib.sh"
source "$SCRIPT_DIR/../libs/apt_lib.sh"

# ------------------------------------------------------------

echo "🛡️ 방화벽 설정 중..."

# 1. iptables 직접 사용을 위해 UFW 서비스 중지 (실패해도 중단하지 않음)
systemctl_service_stop ufw 2>/dev/null || true

# 2. UFW 패키지 완전 제거 (실패해도 중단하지 않음)
apt_remove_packages ufw 2>/dev/null || true

# 2. 웹 포트 허용(HTTP, HTTPS)
network_iptables_allow_tcp \
    80 \
    443 

# 3. 룰 저장(영구 적용)
network_iptables_save_rules

echo "✅ 방화벽 설정 완료"
