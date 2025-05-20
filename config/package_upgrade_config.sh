#!/usr/bin/env bash
set -euo pipefail

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/apt_lib.sh"

echo "============================================"
echo "  Package upgrade"
echo "============================================"

echo ""
echo "[1/1] Upgrading packages..."
apt_upgrade_packages
echo "  -> packages upgraded"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
