#!/bin/bash
set -e

echo "📦 Installing Node.js & npm..."

# NodeSource에서 22 버전(LTS) 설치
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# npm이 누락된 경우를 대비해 명시적으로 설치 시도
if ! command -v npm &> /dev/null; then
  echo "⚠️ npm not found, installing separately..."
  sudo apt install -y npm
fi

# 버전 확인
echo "✅ Installation complete!"
echo "node version: $(node -v)"
echo "npm version: $(npm -v)"
