#!/usr/bin/env bash
set -euo pipefail

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/file_lib.sh"

echo "============================================"
echo "  Zsh & oh-my-zsh setup (with p10k)"
echo "============================================"

# 현재 사용자 정보
EXEC_USER=$(whoami)
USER_HOME=$(eval echo "~$EXEC_USER")

# 경로 설정
ZSHRC="$USER_HOME/.zshrc"
THEME_DIR="$USER_HOME/.oh-my-zsh/custom/themes"
PLUGINS_DIR="$USER_HOME/.oh-my-zsh/custom/plugins"

echo ""
echo "[1/7] Backing up existing .zshrc..."
file_backup "$ZSHRC"

echo ""
echo "[2/7] Installing zsh..."
sudo apt update
sudo apt install -y zsh

echo ""
echo "[3/7] Installing oh-my-zsh..."
file_remove "$USER_HOME/.oh-my-zsh"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo ""
echo "[4/7] Installing powerlevel10k theme..."
file_remove "$THEME_DIR/powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR/powerlevel10k"

echo ""
echo "[5/7] Installing plugins..."
file_remove "${PLUGINS_DIR}/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-autosuggestions ${PLUGINS_DIR}/zsh-autosuggestions
file_remove "${PLUGINS_DIR}/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${PLUGINS_DIR}/zsh-syntax-highlighting

echo ""
echo "[6/7] Applying configuration files..."
cp "$SCRIPT_DIR/resources/.zshrc" "$ZSHRC"
cp "$SCRIPT_DIR/resources/.p10k.zsh" "$USER_HOME/.p10k.zsh"
cp "$SCRIPT_DIR/resources/.alias.sh" "$USER_HOME/.alias.sh"
sed -i '1i [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' "$ZSHRC"
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
echo "" >> "$ZSHRC"
sed -i '$a export TERM=xterm-256color' "$ZSHRC"
sed -i '$a export COLORTERM=truecolor' "$ZSHRC"

echo ""
echo "[7/7] Fixing file ownership..."
sudo chown "$EXEC_USER":"$EXEC_USER" "$ZSHRC"
sudo chown "$EXEC_USER":"$EXEC_USER" "$USER_HOME/.alias.sh"
sudo chown "$EXEC_USER":"$EXEC_USER" "$USER_HOME/.p10k.zsh"

echo ""
echo "============================================"
echo "  Done! Run 'exec zsh' to apply."
echo "============================================"
