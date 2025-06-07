#!/bin/bash

set -e

# 베이스 디렉토리 계산
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 패키지 업그레이드 중..."
sudo bash "$SCRIPT_DIR/snippets/package_upgrade.sh"

echo "🟢 Node.js & npm 설치 중..."
sudo bash "$SCRIPT_DIR/snippets/node_npm_setup.sh"

echo "🐳 Docker 설치 중..."
sudo bash "$SCRIPT_DIR/snippets/docker_setup.sh"

echo "🔓 방화벽 설정 중..."
sudo bash "$SCRIPT_DIR/snippets/firewall_open.sh"

echo "🛡️ 인스턴스 유지(keep_alive) 설정 중..."
sudo bash "$SCRIPT_DIR/snippets/keep_alive.sh"

echo "🔒 사용자 비밀번호 설정 중..."
sudo bash "$SCRIPT_DIR/snippets/user_password_setup.sh"

echo "✅ Ubuntu 부트스트랩 완료!"
