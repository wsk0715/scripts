#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Bash Prompt Style Setup"
echo "============================================"
echo ""

# 현재 사용자 정보
EXEC_USER=$(whoami)
echo "  -> 현재 사용자: $EXEC_USER"
USER_HOME=$(eval echo "~$EXEC_USER")
echo "  -> 현재 홈 디렉토리: $USER_HOME"

# [사용자명@호스트명] 현재경로$
PROMPT='export PS1="\[\e[32m\][\u@\h]\[\e[0m\] \[\e[33m\]\W\[\e[0m\]\[\e[37m\]\$\[\e[0m\] "'

if ! grep -Fxq "$PROMPT" ~/.bashrc; then
  echo -e "\n$PROMPT" >> ~/.bashrc
fi

# 기본 쉘 bash로 변경
sudo usermod --shell "$(which bash)" "$EXEC_USER"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
