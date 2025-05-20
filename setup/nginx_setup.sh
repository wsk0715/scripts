#!/usr/bin/env bash
# ===================================================
# Nginx — full setup (install + default config)
# Installs nginx + certbot, then applies the default
# SPA site config with /api/ reverse proxy.
# ===================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Nginx setup"
echo "============================================"
echo ""

echo "[1/2] Installing Nginx + certbot..."
bash "$SCRIPT_DIR/../package/nginx_install.sh"
echo ""

echo "[2/2] Applying default SPA site config..."
bash "$SCRIPT_DIR/../config/nginx_default_config.sh"
echo ""

echo "============================================"
echo "  Done!"
echo "============================================"
echo ""
echo "  To customize:     config/nginx_config.sh"
echo "  For SSL/domain:   config/nginx_config.sh"
echo ""
