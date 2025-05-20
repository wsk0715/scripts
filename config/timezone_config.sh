#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Change Timezone"
echo "============================================"

echo ""
echo "[1/1] Set timezone to Asia/Seoul..."
sudo timedatectl set-timezone Asia/Seoul
echo "  -> Timezone set to Asia/Seoul"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
