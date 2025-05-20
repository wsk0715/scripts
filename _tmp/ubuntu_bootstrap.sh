#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Ubuntu Bootstrap"
echo "============================================"
echo ""

# 베이스 디렉토리 계산
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌐 시간대 설정 중..."
sudo bash "$SCRIPT_DIR/snippets/timezone_change.sh"

echo "📦 패키지 업그레이드 중..."
sudo bash "$SCRIPT_DIR/snippets/package_upgrade.sh"

echo "🟢 Node.js & npm 설치 중..."
sudo bash "$SCRIPT_DIR/bin/node_npm_setup.sh"

echo "🐳 Docker 설치 중..."
sudo bash "$SCRIPT_DIR/bin/docker_setup.sh"

echo "🔓 방화벽 설정 중..."

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
