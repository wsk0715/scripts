#!/bin/bash

# ------------------------------------------------------------
# Node.js & npm 설치 스크립트
# ------------------------------------------------------------

set -e

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../libs/nodejs_lib.sh"

# ------------------------------------------------------------

echo "🎯 Node.js & npm 설치 시작..."

# 1. Node.js 설치
install_nodejs

# 2. npm 설치 실행
install_npm

echo "🎉 Node.js & npm 설치 완료!"
