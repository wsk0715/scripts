#!/usr/bin/env bash
# ===================================================
# Nginx — stop host nginx service
# Stops and disables the host nginx service,
# frees ports 80/443 for nginx-host container.
# ===================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Nginx stop"
echo "============================================"

echo ""
echo "[1/3] Stopping nginx service..."
sudo systemctl stop nginx
echo "  ✅ nginx stopped"

echo ""
echo "[2/3] Disabling nginx autostart..."
sudo systemctl disable nginx
echo "  ✅ nginx autostart disabled"

echo ""
echo "[3/3] Verifying port 80/443..."
if sudo ss -tlnp | grep -qE ':80 |:443 '; then
  echo "  ⚠ Port still in use"
  sudo ss -tlnp | grep -E ':80 |:443 '
else
  echo "  ✅ Port 80/443 available"
fi

echo ""
echo "============================================"
echo "  Done! nginx-host container can start."
echo "============================================"
