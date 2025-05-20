#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Sudo nopass — passwordless sudo"
echo "============================================"

echo ""
echo "[1/1] Configuring passwordless sudo..."
SUDOERS_FILE="/etc/sudoers.d/99-nopasswd"
if [ -f "$SUDOERS_FILE" ]; then
  echo "  -> already configured"
else
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  echo "  -> passwordless sudo enabled for $USER"
fi

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
