#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=/usr/local/bin}"

echo "============================================"
echo "  dnsutils Setup (dig, nslookup)"
echo "============================================"

echo ""
echo "[1/1] Installing dnsutils..."
sudo apt-get update -qq
sudo apt-get install -y -qq dnsutils
echo "  -> Installed"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
dig -v 2>&1 | head -1
