#!/usr/bin/env bash
# ===================================================
# Nginx — reverse proxy site configuration
# Creates an nginx site config and optionally issues
# Let's Encrypt SSL certificate via certbot.
# Prerequisites: nginx installed (package/nginx_install.sh)
# ===================================================
set -euo pipefail

echo "============================================"
echo "  Nginx site configuration"
echo "============================================"

echo ""
echo "[1/3] Configuring site..."
read -rp "$(echo '  App name (default: default-app): ')" APP_NAME
read -rp "$(echo '  Reverse proxy target port (default: 3000): ')" APP_PORT
APP_NAME=${APP_NAME:-default-app}
APP_PORT=${APP_PORT:-3000}

NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
echo "  -> Config created: $NGINX_CONF"

echo ""
echo "[2/3] Enabling site..."
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
echo "  -> Site enabled and nginx reloaded"

echo ""
echo "[3/3] SSL certificate (optional)..."
read -rp "$(echo '  Issue SSL certificate? (y/N): ')" ENABLE_SSL
if [[ "$ENABLE_SSL" == "Y" || "$ENABLE_SSL" == "y" ]]; then
  read -rp "$(echo '  Domain name (e.g. example.com): ')" DOMAIN
  while [ -z "$DOMAIN" ]; do
    echo "  ❌ Domain is required"
    read -rp "$(echo '  Domain name (e.g. example.com): ')" DOMAIN
  done

  read -rp "$(echo '  Email for Let'\''s Encrypt: ')" EMAIL
  while [ -z "$EMAIL" ]; do
    echo "  ❌ Email is required"
    read -rp "$(echo '  Email for Let'\''s Encrypt: ')" EMAIL
  done

  echo "  -> Issuing certificate for $DOMAIN..."
  sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect
  echo "  -> SSL certificate issued: https://$DOMAIN"
fi

echo ""
echo "============================================"
echo "  Done! Nginx is running with $APP_NAME"
echo "============================================"
