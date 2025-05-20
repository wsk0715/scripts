#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  SDKMAN Setup"
echo "============================================"

echo ""
echo "[1/2] Install dependencies..."
sudo apt install zip unzip
echo "  -> Dependencies installed"

echo ""
echo "[2/2] Install SDKMAN..."
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
echo "  -> SDKMAN installed"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
