#!/usr/bin/env bash
# ===================================================
# Nginx — default SPA site config
# Creates a default nginx site with:
#   - SPA fallback (Vue/React history mode)
#   - /api/ reverse proxy to localhost:8080
# Run after setup/nginx_setup.sh
# ===================================================
set -euo pipefail

SITE_NAME="default"
NGINX_CONF="/etc/nginx/sites-available/$SITE_NAME"
API_PORT="${API_PORT:-8080}"

echo "============================================"
echo "  Nginx default SPA site config"
echo "============================================"

echo ""
echo "[1/3] Writing nginx config..."
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:$API_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
echo "  -> Config created: $NGINX_CONF"
echo "  -> API proxy -> localhost:$API_PORT"

echo ""
echo "[2/3] Enabling site..."
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
echo "  -> Site enabled"

echo ""
echo "[3/3] Testing config and reloading..."
sudo nginx -t
sudo systemctl reload nginx
echo "  -> Nginx reloaded"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
echo ""
echo "  SPA fallback : / → /index.html"
echo "  API proxy    : /api/ → localhost:$API_PORT/"
echo "  Static root  : /var/www/html"
echo ""
echo "  To change API port: export API_PORT=3000"
echo "  Custom SSL/domain : config/nginx_config.sh"
echo ""
