#!/bin/bash

# ------------------------------------------------------------
# APT 패키지 관리 모듈
# ------------------------------------------------------------

# APT 패키지 목록 업데이트
# example: apt_update
apt_update() {
    echo "📦 패키지 목록 업데이트 중..."
    sudo apt update
    echo "✅ 패키지 목록 업데이트 완료"
}

# APT 패키지 업그레이드
# example: apt_upgrade_packages <패키지1> <패키지2> ...
apt_upgrade_packages() {
    echo "⬆️ 패키지 업그레이드 중..."
    apt_update
    sudo apt upgrade -y
    echo "✅ 패키지 업그레이드 완료"
}

# 패키지 설치 함수
# example: apt_install_packages <패키지1> <패키지2> ...
apt_install_packages() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        echo "❌ 설치할 패키지를 지정해주세요"
        return 1
    fi
    
    local IFS=", "
    echo "🔧 패키지 설치 중: $*"
    sudo apt install -y "${packages[@]}"
    echo "✅ 패키지 설치 완료: $*"
}

# 패키지 제거 함수
# example: apt_remove_packages <패키지1> <패키지2> ...
apt_remove_packages() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        echo "❌ 제거할 패키지를 지정해주세요"
        return 1
    fi
    
    local IFS=", "
    echo "🗑️ 패키지 제거 중: $*"
    sudo apt remove --purge -y "${packages[@]}"
    echo "✅ 패키지 제거 완료: $*"
}

# APT 캐시 정리
# example: apt_cleanup_cache
apt_cleanup_cache() {
    echo "🧹 APT 캐시 정리 중..."
    sudo rm -rf /var/lib/apt/lists/*
    sudo apt autoclean
    sudo apt clean
    echo "✅ APT 캐시 정리 완료"
}

# APT 패키지 정리
# example: apt_cleanup
apt_cleanup() {
    echo "🧹 불필요한 패키지 정리 중..."
    sudo apt autoremove -y
    sudo apt clean
    echo "✅ 패키지 정리 완료"
}