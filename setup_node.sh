#!/bin/bash
set -e

echo "📦 Installing Node.js & npm..."

# NodeSource에서 22 버전(LTS) 설치
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

echo "node version: $(node -v)"
echo "npm version: $(npm -v)"
