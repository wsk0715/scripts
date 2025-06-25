#!/bin/bash

# ------------------------------------------------------------
# 패키지 업그레이드 스크립트
# ------------------------------------------------------------

set -e

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../libs/apt_lib.sh"

# ------------------------------------------------------------

echo "🎯 Ubuntu 패키지 업그레이드 시작..."

# 1. APT 캐시 정리
apt_cleanup_cache

# 2. 패키지 목록 업데이트 & 업그레이드
apt_upgrade_packages

# 3. 필수 유틸리티 설치
echo "🔧 필수 유틸리티 패키지 설치 중..."
apt_install_packages \
    curl \
    wget \
    cron \
    file \
    unzip \
    git \
    vim \
    bash-completion \
    build-essential \
    software-properties-common \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    gnupg \
    net-tools \
    iptables-persistent

# 4. 패키지 정리
apt_cleanup

echo "🎉 Ubuntu 패키지 업그레이드 완료!"
