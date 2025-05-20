#!/usr/bin/env bash
set -euo pipefail

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/file_lib.sh"

echo "============================================"
echo "  Zsh & oh-my-zsh setup"
echo "============================================"

# 현재 사용자 정보
EXEC_USER=$(whoami)
USER_HOME=$(eval echo "~$EXEC_USER")

# 경로 설정
ZSHRC="$USER_HOME/.zshrc"
THEME_DIR="$USER_HOME/.oh-my-zsh/custom/themes"
PLUGINS_DIR="$USER_HOME/.oh-my-zsh/custom/plugins"

echo ""
echo "[1/6] Backing up existing .zshrc..."
file_backup "$ZSHRC"

echo ""
echo "[2/6] Installing zsh..."
sudo apt update
sudo apt install -y zsh

echo ""
echo "[3/6] Installing oh-my-zsh..."
file_remove "$USER_HOME/.oh-my-zsh"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo ""
echo "[4/6] Installing plugins..."
file_remove "${PLUGINS_DIR}/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-autosuggestions ${PLUGINS_DIR}/zsh-autosuggestions
file_remove "${PLUGINS_DIR}/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${PLUGINS_DIR}/zsh-syntax-highlighting

echo ""
echo "[5/6] Applying configuration files..."
cp "$SCRIPT_DIR/resources/.zshrc" "$ZSHRC"
cp "$SCRIPT_DIR/resources/.alias.sh" "$USER_HOME/.alias.sh"

echo ""
echo "[6/6] Fixing file ownership..."
sudo chown "$EXEC_USER":"$EXEC_USER" "$ZSHRC"
sudo chown "$EXEC_USER":"$EXEC_USER" "$USER_HOME/.alias.sh"

echo ""
echo "============================================"
echo "  Done! Run 'exec zsh' to apply."
echo "============================================"
