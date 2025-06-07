#!/bin/bash

source ./libs/replace_or_append_line.sh

set -e

echo "🌀 Zsh & oh-my-zsh 설치 중..."

# 현재 사용자 정보
EXEC_USER=$(whoami)
echo "👉 현재 사용자: $EXEC_USER"
USER_HOME=$(eval echo "~$EXEC_USER")
echo "👉 현재 홈 디렉토리: $USER_HOME"

# 경로 설정
ZSHRC="$USER_HOME/.zshrc"
THEME_DIR="$USER_HOME/.oh-my-zsh/custom/themes"
PLUGINS_DIR="$USER_HOME/.oh-my-zsh/custom/plugins"

# 기존 .zshrc 백업
if [ -f "$ZSHRC" ]; then
  cp "$ZSHRC" "$HOME/.zshrc.backup.$(date +%Y%m%d)"
fi

# zsh 설치
sudo apt update
sudo apt install -y zsh

# 기본 쉘 zsh로 변경
echo "🛠️ 기본 쉘을 zsh로 설정: $EXEC_USER"
sudo usermod --shell "$(which zsh)" "$EXEC_USER"

# oh-my-zsh 설치
echo "🌟 oh-my-zsh 설치..."
sudo rm -rf "$USER_HOME/.oh-my-zsh"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# powerlevel10k 설치
echo "⬇️ powerlevel10k 다운로드 중..."
sudo rm -rf "$THEME_DIR/powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR/powerlevel10k"

# 플러그인 설치
git clone https://github.com/zsh-users/zsh-autosuggestions ${PLUGINS_DIR}/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${PLUGINS_DIR}/zsh-syntax-highlighting
sudo apt install -y autojump


# .zshrc 설정
# oh-my-zsh
replace_or_append_line "$ZSHRC" '^export ZSH=' 'export ZSH="$HOME/.oh-my-zsh"'
replace_or_append_line "$ZSHRC" '^ZSH_THEME=' 'ZSH_THEME=""'
echo "" >> "$ZSHRC"

# 플러그인
replace_or_append_line "$ZSHRC" '^plugins=' 'plugins=(git sudo history z command-not-found zsh-autosuggestions zsh-syntax-highlighting)'
echo "" >> "$ZSHRC"

echo "" >> "$ZSHRC"

# Git 브랜치 정보
echo "autoload -Uz vcs_info" >> "$ZSHRC"
echo "precmd() { vcs_info }" >> "$ZSHRC"
echo "setopt prompt_subst" >> "$ZSHRC"
echo "zstyle ':vcs_info:git:*' formats '(%b)'" >> "$ZSHRC"
echo "" >> "$ZSHRC"

# 오타 자동 수정 옵션
replace_or_append_line "$ZSHRC" '^setopt correct' 'setopt correct'
echo "" >> "$ZSHRC"

# 키 바인딩
echo "bindkey '^[[1~' beginning-of-line      # Home" >> "$ZSHRC"
echo "bindkey '^[[4~' end-of-line            # End" >> "$ZSHRC"
echo "bindkey '^[[5~' up-line-or-history     # PageUp" >> "$ZSHRC"
echo "bindkey '^[[6~' down-line-or-history   # PageDown" >> "$ZSHRC"
echo "" >> "$ZSHRC"

# alias
sudo cp ./resources/aliases.sh $HOME/.aliases.sh

# source 설정
echo "source $HOME/.aliases.sh" >> "$ZSHRC"
echo "source /usr/share/autojump/autojump.sh" >> "$ZSHRC"
echo "source $THEME_DIR/powerlevel10k/powerlevel10k.zsh-theme" >> "$ZSHRC"

# 컬러 터미널 설정(powerlevel10k)
echo "export TERM=xterm-256color" >> "$ZSHRC"
echo "export COLORTERM=truecolor" >> "$ZSHRC"


# 파일 소유권 재조정
sudo chown "$EXEC_USER":"$EXEC_USER" "$ZSHRC"

echo "✅ zsh 및 oh-my-zsh 설정 완료!"
echo "👉 다음 로그인 시 zsh로 전환됩니다."
