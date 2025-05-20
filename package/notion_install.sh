#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=/usr/local/bin}"

echo "============================================"
echo "  Notion CLI (ntn) Setup"
echo "============================================"

echo ""
echo "[1/2] Installing ntn via npm..."
sudo npm install -g ntn --unsafe-perm 2>&1 | tail -2
echo "  -> Installed"

echo ""
echo "[2/2] Configuring..."
echo "  -> Run 'ntn init' to link your Notion integration token"
echo "  -> Or set NOTION_API_KEY env var"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
ntn --version 2>&1 | head -1
