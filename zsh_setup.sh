#!/bin/bash
set -e

echo "🌀 Zsh & Oh My Zsh 설치 중..."

# 현재 사용자 정보
EXEC_USER=$(whoami)
USER_HOME=$(eval echo "~$EXEC_USER")

# zsh 설치
sudo apt update
sudo apt install -y zsh

# 기본 쉘 zsh로 변경
echo "🛠️ 기본 쉘을 zsh로 설정: $EXEC_USER"
sudo chsh -s "$(which zsh)" "$EXEC_USER"

# oh-my-zsh 설치
echo "🌟 oh-my-zsh 설치..."
sudo rm -rf "$USER_HOME/.oh-my-zsh"
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# .zshrc 경로
ZSHRC="$USER_HOME/.zshrc"

# plugins 설정(git, sudo, history, z, command-not-found)
echo "🧩 플러그인 설정..."
if grep -q '^plugins=' "$ZSHRC"; then
  sed -i 's/^plugins=(.*)$/plugins=(git sudo history z command-not-found)/' "$ZSHRC"
else
  echo 'plugins=(git sudo history z command-not-found)' >> "$ZSHRC"
fi

cat << 'EOF' >> "$ZSHRC"

# alias 적용
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# Git 브랜치 정보 설정
autoload -Uz vcs_info
precmd() { vcs_info }
setopt prompt_subst
zstyle ':vcs_info:git:*' formats '(%b)'

# 사용자 정의 프롬프트
export PROMPT='%F{green}[%n@%m]%f %F{yellow}%1~%f %F{cyan}${vcs_info_msg_0_}%f%F{white}$%f '

# 오타 자동 수정 옵션
setopt correct

# 키 바인딩
bindkey "^[[1~" beginning-of-line  # Home
bindkey "^[[4~" end-of-line        # End
bindkey "^[[5~" up-line-or-history     # PageUp
bindkey "^[[6~" down-line-or-history   # PageDown
EOF

# 파일 소유권 재조정
sudo chown "$EXEC_USER":"$EXEC_USER" "$ZSHRC"

echo "✅ zsh 및 oh-my-zsh 설정 완료!"
echo "👉 다음 로그인 시 zsh로 전환됩니다."
