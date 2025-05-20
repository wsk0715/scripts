#!/bin/bash

# ------------------------------------------------------------
# Zsh & oh-my-zsh 설치 스크립트
# ------------------------------------------------------------

set -e

# 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/libs/string_lib.sh"
source "$SCRIPT_DIR/libs/file_lib.sh"

# ------------------------------------------------------------

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


# 1. 기존 .zshrc 백업
file_backup "$ZSHRC"


# 2. zsh 설치
sudo apt update
sudo apt install -y zsh


# 3. 기본 쉘 zsh로 변경 (필요 시 주석 해제)
# sudo usermod --shell "$(which zsh)" "$EXEC_USER"


# 4. oh-my-zsh 설치
echo "🌟 oh-my-zsh 설치..."
file_remove "$USER_HOME/.oh-my-zsh"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


# 5. powerlevel10k 테마 다운로드
# echo "⬇️ powerlevel10k 다운로드 중..."
# file_remove "$THEME_DIR/powerlevel10k"
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR/powerlevel10k"


# 6. 플러그인 설치
echo "🔌 플러그인 설치 중..."
# zsh-autosuggestions
file_remove "${PLUGINS_DIR}/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-autosuggestions ${PLUGINS_DIR}/zsh-autosuggestions
# zsh-syntax-highlighting
file_remove "${PLUGINS_DIR}/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${PLUGINS_DIR}/zsh-syntax-highlighting


# 7. 설정 파일 적용
echo "📝 설정 파일(zshrc, alias) 적용 중..."
# 리소스 파일 존재 여부 확인 후 복사
cp "$SCRIPT_DIR/resources/.zshrc" "$ZSHRC"
cp "$SCRIPT_DIR/resources/.alias.sh" "$USER_HOME/.alias.sh"


# 8. 파일 소유권 및 권한 재조정
sudo chown "$EXEC_USER":"$EXEC_USER" "$ZSHRC"
sudo chown "$EXEC_USER":"$EXEC_USER" "$USER_HOME/.alias.sh"


echo "✅ zsh 및 oh-my-zsh 설정 완료!"
