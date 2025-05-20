#!/bin/bash

set -e

# Nginx 설치
echo "📦 Installing nginx..."
sudo apt update
sudo apt install -y nginx

# Nginx 서비스 상태 확인 및 활성화
echo "🔄 Enabling and starting nginx service..."
sudo systemctl enable nginx
sudo systemctl start nginx

# 상태 확인
echo "✅ nginx 설치 완료"
echo "sudo systemctl status nginx"
