#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Preferences Manager"
echo "============================================"

echo ""
echo "Select mode:"
echo "  I) Init   - apply gitconfig & vimrc"
echo "  R) Reset  - remove config files, reset shell"
echo ""
read -r -p "Choice [I/r]: " mode

case "${mode:-i}" in
  i|I|init|Init|"")
    echo ""
    echo "============================================"
    echo "  Init: Applying preferences..."
    echo "============================================"

    echo ""
    echo "[1/2] Copy gitconfig..."
    cp "$SCRIPT_DIR/../resources/.gitconfig" ~/.gitconfig

    # Windows 홈으로도 복사
    WIN_USER=$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r')
    if [ -n "$WIN_USER" ] && [ -d "/mnt/c/Users/$WIN_USER" ]; then
      cp "$SCRIPT_DIR/../resources/.gitconfig" "/mnt/c/Users/$WIN_USER/.gitconfig" 2>/dev/null || true
      echo "  -> Gitconfig copied (Windows: $WIN_USER)"
    fi
    echo "  -> Gitconfig copied"

    echo ""
    echo "[2/2] Copy vimrc..."
    cp "$SCRIPT_DIR/../resources/.vimrc" ~/.vimrc
    echo "  -> Vimrc copied"
    ;;

  r|R|reset|Reset)
    echo ""
    echo "============================================"
    echo "  Reset: Removing preferences..."
    echo "============================================"

    echo ""
    echo "[1/2] Resetting shell to sh..."
    sudo usermod --shell "$(which sh)" "$(whoami)"
    echo "  -> Shell reset to sh"

    echo ""
    echo "[2/2] Removing config files..."
    sudo rm -f ~/.gitconfig ~/.vimrc
    echo "  -> Config files removed"
    ;;

  *)
    echo ""
    echo "  Invalid choice. Run again and select I or R."
    exit 1
    ;;
esac

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
