#!/bin/bash

# ------------------------------------------------------------
# Node.js 관리 모듈
# ------------------------------------------------------------

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/apt_lib.sh"
source "$SCRIPT_DIR/http_lib.sh"

# Node.js 설치
# example: install_nodejs
install_nodejs() {
    echo "📦 Node.js & npm 설치 중..."

    # NodeSource에서 저장소 불러오기
    echo "🔑 Nodejs 저장소 불러오는 중..."
    http_curl_get "https://deb.nodesource.com/setup_22.x" | sudo -E bash -
    
    # Node.js 설치
    apt_install_packages nodejs

    # 버전 확인
    echo "✅ Node.js 설치 완료!"
    echo "  - Node.js: $(node -v)"
} 

# npm 설치
# example: install_npm
install_npm() {
    echo "🔍 npm 설치 확인 중..."    
    if ! command -v npm &> /dev/null; then
        echo "⚠️ npm이 누락되었습니다. 별도 설치 중..."
        apt_install_packages "npm"
        echo "✅ npm 설치 완료!"
    else
        echo "✅ npm이 이미 설치되어 있습니다"
    fi

    echo "  - npm: $(npm -v)"
}