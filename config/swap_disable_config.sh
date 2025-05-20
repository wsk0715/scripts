#!/usr/bin/env bash
set -euo pipefail

SWAP_PATH="/swapfile"

echo "============================================"
echo "  Disable Swap"
echo "============================================"

echo ""
echo "[1/3] Current swap state..."
if swapon --show 2>/dev/null | grep -q .; then
  swapon --show
else
  echo "  -> No active swap"
fi

echo ""
echo "[2/3] Disabling swap..."
sudo swapoff -a
echo "  -> swap disabled"

echo ""
echo "[3/3] Persisting in fstab..."
if grep -q "^${SWAP_PATH}" /etc/fstab 2>/dev/null; then
  sudo sed -i "s|^${SWAP_PATH}|#${SWAP_PATH}|" /etc/fstab
  echo "  -> fstab entry commented out"
elif grep -q "^#${SWAP_PATH}" /etc/fstab 2>/dev/null; then
  echo "  -> already commented in fstab"
else
  echo "  -> no swap entry in fstab"
fi

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
if swapon --show 2>/dev/null | grep -q .; then
  swapon --show
else
  echo "  No active swap"
fi
