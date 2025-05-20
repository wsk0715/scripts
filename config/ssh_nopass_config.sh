#!/usr/bin/env bash
set -euo pipefail

# SSH 키 로그인 환경에서 비밀번호 없이 접속하도록 설정
# WARNING: 클라우드 공인IP 인스턴스에서는 사용하지 말 것

echo "============================================"
echo "  SSH nopass — empty password login"
echo "============================================"
echo ""

# ⚠️ y/N 확인
read -r -p "Are you sure? SSH 비밀번호를 제거합니다. (y/N): " confirm
case "$confirm" in
  y|Y|yes|Yes)
    ;;
  *)
    echo "  -> Aborted."
    exit 0
    ;;
esac

USERNAME="$(whoami)"
SSH_CONFIG="/etc/ssh/sshd_config"

echo ""
echo "[1/4] Backing up sshd_config..."
BACKUP="$SSH_CONFIG.bak.nopass.$(date +%s)"
sudo cp "$SSH_CONFIG" "$BACKUP"
echo "  -> backed up to $BACKUP"

echo ""
echo "[2/4] Enabling PermitEmptyPasswords..."
if grep -q "^PermitEmptyPasswords" "$SSH_CONFIG"; then
  sudo sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords yes/' "$SSH_CONFIG"
else
  echo "PermitEmptyPasswords yes" | sudo tee -a "$SSH_CONFIG" > /dev/null
fi
echo "  -> PermitEmptyPasswords set to yes"

echo ""
echo "[3/4] Removing password for $USERNAME..."
sudo passwd -d "$USERNAME"
echo "  -> password removed"

echo ""
echo "[4/4] Restarting SSH..."
sudo systemctl restart ssh
echo "  -> SSH restarted"

echo ""
echo "============================================"
echo "  Done! SSH empty password enabled."
echo "  Revert: bash config/ssh_nopass_disable_config.sh"
echo "============================================"
