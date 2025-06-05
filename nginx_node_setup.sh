#!/bin/bash

set -e

# Nginx 설치
echo "Installing nginx..."
sudo apt update
sudo apt install -y nginx

# 리버스 프록시 설정(Node)
echo "Configuring nginx reverse proxy..."
sudo tee /etc/nginx/sites-available/node-app >/dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# 설정 적용
echo "Enabling nginx config..."
sudo ln -sf /etc/nginx/sites-available/node-app /etc/nginx/sites-enabled/node-app
sudo rm -f /etc/nginx/sites-enabled/default

# Nginx 재시작
echo "Restarting nginx..."
sudo systemctl restart nginx

echo "Nginx is now reverse proxying :80 → :3000"
