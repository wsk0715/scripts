#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  asdf setup"
echo "============================================"

echo ""
echo "[0/4] Resolving latest asdf version..."
ASDF_VERSION=$(curl -sI https://github.com/asdf-vm/asdf/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$ASDF_VERSION" ]; then
  ASDF_VERSION="0.14.1"
  echo "  -> API unavailable, fallback: v$ASDF_VERSION"
else
  echo "  -> asdf v$ASDF_VERSION"
fi

# ------ 1. dependencies ------
echo ""
echo "[1/4] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl git

# ------ 2. install asdf ------
echo ""
echo "[2/4] Installing asdf..."
if [ -d "$HOME/.asdf" ]; then
  echo "  -> already installed"
else
  git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch "v$ASDF_VERSION"
  echo "  -> installed"
fi

# ------ 3. shell config ------
echo ""
echo "[3/4] Adding to shell config..."

export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"

if grep -sq "asdf.sh" "$HOME/.zshrc" 2>/dev/null; then
  echo "  -> .zshrc: already configured"
else
  cat >> "$HOME/.zshrc" << 'ZSHRC_EOF'

# asdf version manager
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
ZSHRC_EOF
  echo "  -> .zshrc: configured (run 'exec zsh' to apply)"
fi

# ------ 4. usage guide ------
echo ""
echo "[4/4] Setup complete! Next steps:"
echo ""
echo "  Install plugin:"
echo "    asdf plugin add golang"
echo ""
echo "  Install Go:"
echo "    asdf list-all golang     # check available versions"
echo "    asdf install golang 1.26.4"
echo "    asdf global golang 1.26.4"
echo ""
echo "  Apply shell:"
echo "    exec zsh"
echo ""

echo "============================================"
echo "  Done! Run 'asdf plugin list' to verify."
echo "============================================"
