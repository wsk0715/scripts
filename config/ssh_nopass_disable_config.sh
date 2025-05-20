#!/usr/bin/env bash
set -euo pipefail

# SSH nopass 설정을 원복: 비밀번호 복구 + PermitEmptyPasswords 해제

echo "============================================"
echo "  SSH nopass disable — restore password"
echo "============================================"

USERNAME="$(whoami)"
SSH_CONFIG="/etc/ssh/sshd_config"

# 최근 백업 찾기
BACKUP=$(ls -t "$SSH_CONFIG.bak.nopass".* 2>/dev/null | head -1)

echo ""
echo "[1/4] Restoring sshd_config from backup..."
if [ -n "$BACKUP" ] && [ -f "$BACKUP" ]; then
  sudo cp "$BACKUP" "$SSH_CONFIG"
  echo "  -> restored from $BACKUP"
else
  echo "  -> no backup found, manually reverting setting..."
  if grep -q "^PermitEmptyPasswords" "$SSH_CONFIG"; then
    sudo sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSH_CONFIG"
  fi
  echo "  -> PermitEmptyPasswords set to no"
fi

echo ""
echo "[2/4] Setting a password for $USERNAME..."
CURRENT_STATE=$(sudo passwd -S "$USERNAME" 2>/dev/null | awk '{print $2}')
if [ "$CURRENT_STATE" = "NP" ]; then
  echo "  -> 현재 비밀번호 없음. 새 비밀번호를 설정합니다."
  sudo passwd "$USERNAME"
else
  echo "  -> already has a password"
fi

echo ""
echo "[3/4] Restarting SSH..."
sudo systemctl restart ssh
echo "  -> SSH restarted"

echo ""
echo "[4/4] Verification..."
echo "  PermitEmptyPasswords:"
sudo sshd -T 2>/dev/null | grep -i permitemptypasswords || echo "  (not set)"
echo "  Password status:"
sudo passwd -S "$USERNAME" 2>/dev/null | awk '{print $2}' | grep -q 'P' && echo "  ✅ password set" || echo "  ⚠️  no password"

echo ""
echo "============================================"
echo "  Done! SSH password login restored."
echo "============================================"
