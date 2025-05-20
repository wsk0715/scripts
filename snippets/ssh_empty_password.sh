#!/bin/bash

# SSH Empty Password 허용 및 사용자 비밀번호 제거 스크립트
# VMWare 등, 로컬 환경에서만 사용할 것


set -e # 에러 발생 시 스크립트 중단

echo "🔧 [1/3] SSH 설정 수정 중..."
USERNAME="$(whoami)" # 현재 접속한 사용자명
SSH_CONFIG="/etc/ssh/sshd_config"

# 기존 설정 백업
BACKUP="$SSH_CONFIG.bak.$(date +%s)"
sudo cp "$SSH_CONFIG" "$BACKUP"
echo "✅ sshd_config 백업 완료: $BACKUP"

# PermitEmptyPasswords 설정 (있으면 수정, 없으면 추가)
if grep -q "^PermitEmptyPasswords" "$SSH_CONFIG"; then
  sudo sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords yes/' "$SSH_CONFIG"
else
  echo "PermitEmptyPasswords yes" | sudo tee -a "$SSH_CONFIG" > /dev/null
fi


echo "🔄 [2/3] SSH 서비스 재시작 중..."
sudo systemctl restart ssh


echo "❌ [3/3] 사용자 '$USERNAME'의 비밀번호 제거 중..."
sudo passwd -d "$USERNAME"


echo "✅ 완료: 빈 비밀번호 SSH 로그인 허용 + 비밀번호 제거"
