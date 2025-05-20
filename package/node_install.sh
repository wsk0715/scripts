#!/usr/bin/env bash
set -euo pipefail

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|aarch64) ;;
  *)  echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  Node.js & npm setup ($ARCH)"
echo "============================================"

echo ""
echo "[1/3] Resolving latest Node.js LTS version..."
NODE_MAJOR=$(curl -s https://nodejs.org/dist/index.json 2>/dev/null \
  | python3 -c "import sys,json; vers=[v for v in json.load(sys.stdin) if v['lts']]; print(vers[0]['version'].split('.')[0].lstrip('v'))" 2>/dev/null || echo "22")
echo "  -> Node.js ${NODE_MAJOR}.x LTS"

echo ""
echo "[2/3] Adding NodeSource repository..."
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
echo "  -> NodeSource repo added"

echo ""
echo "[3/3] Installing Node.js & npm..."
sudo apt-get install -y -qq nodejs
echo "  -> Node.js installed"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

node --version
npm --version
