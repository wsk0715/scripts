#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Set Zsh as Default Shell"
echo "============================================"

echo ""
echo "[1/1] Set zsh as default shell..."
sudo usermod --shell "$(which zsh)" "$(whoami)"
echo "  -> Default shell set to zsh"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
