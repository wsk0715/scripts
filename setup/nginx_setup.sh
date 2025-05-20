#!/usr/bin/env bash
# ===================================================
# Nginx — web server + reverse proxy installation
# Installs nginx and certbot from apt.
# Config is handled separately via snippets/nginx_config.sh
# ===================================================
set -euo pipefail

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|aarch64) ;;
  *)  echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  Nginx install ($ARCH)"
echo "============================================"

echo ""
echo "[1/2] Installing nginx & certbot..."
sudo apt update -qq
sudo apt install -y -qq nginx certbot python3-certbot-nginx
echo "  -> nginx and certbot installed"

echo ""
echo "[2/2] Enabling and starting nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx
echo "  -> nginx enabled and started"

echo ""
echo "============================================"
echo "  Done! Use 'snippets/nginx_config.sh' to"
echo "  configure a reverse proxy site with SSL."
echo "============================================"
