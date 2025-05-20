#!/usr/bin/env bash

# ------------------------------------------------------------
# APT 패키지 관리 모듈
# ------------------------------------------------------------

# APT 패키지 목록 업데이트
# example: apt_update
apt_update() {
    sudo apt update
}

# APT 패키지 업그레이드
# example: apt_upgrade_packages <패키지1> <패키지2> ...
apt_upgrade_packages() {
    apt_update
    sudo apt upgrade -y
}

# 패키지 설치 함수
# example: apt_install_packages <패키지1> <패키지2> ...
apt_install_packages() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        echo "❌ 설치할 패키지를 지정해주세요"
        return 1
    fi

    sudo apt install -y "${packages[@]}"
}

# 패키지 제거 함수
# example: apt_remove_packages <패키지1> <패키지2> ...
apt_remove_packages() {
    local packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        echo "❌ 제거할 패키지를 지정해주세요"
        return 1
    fi

    sudo apt remove --purge -y "${packages[@]}"
}

# APT 캐시 정리
# example: apt_cleanup_cache
apt_cleanup_cache() {
    sudo rm -rf /var/lib/apt/lists/*
    sudo apt autoclean
    sudo apt clean
}

# APT 패키지 정리
# example: apt_cleanup
apt_cleanup() {
    sudo apt autoremove -y
    sudo apt clean
}
