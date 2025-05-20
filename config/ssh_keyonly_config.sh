#!/usr/bin/env bash
set -euo pipefail

# SSH 키 인증만 허용, 비밀번호 인증 차단

echo "============================================"
echo "  SSH key-only — disable password auth"
echo "============================================"

SSH_CONFIG="/etc/ssh/sshd_config"

echo ""
echo "[1/4] Backing up sshd_config..."
BACKUP="$SSH_CONFIG.bak.keyonly.$(date +%s)"
sudo cp "$SSH_CONFIG" "$BACKUP"
echo "  -> backed up to $BACKUP"

echo ""
echo "[2/4] Disabling password authentication..."
# PasswordAuthentication
if grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
  sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
else
  echo "PasswordAuthentication no" | sudo tee -a "$SSH_CONFIG" > /dev/null
fi
echo "  -> PasswordAuthentication no"

# ChallengeResponseAuthentication (비밀번호 우회 경로 차단)
if grep -q "^ChallengeResponseAuthentication" "$SSH_CONFIG"; then
  sudo sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSH_CONFIG"
else
  echo "ChallengeResponseAuthentication no" | sudo tee -a "$SSH_CONFIG" > /dev/null
fi
echo "  -> ChallengeResponseAuthentication no"

# PermitEmptyPasswords (안전장치)
if grep -q "^PermitEmptyPasswords" "$SSH_CONFIG"; then
  sudo sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSH_CONFIG"
else
  echo "PermitEmptyPasswords no" | sudo tee -a "$SSH_CONFIG" > /dev/null
fi
echo "  -> PermitEmptyPasswords no"

echo ""
echo "[3/4] Ensuring pubkey authentication..."
if grep -q "^PubkeyAuthentication" "$SSH_CONFIG"; then
  sudo sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
else
  echo "PubkeyAuthentication yes" | sudo tee -a "$SSH_CONFIG" > /dev/null
fi
echo "  -> PubkeyAuthentication yes"

echo ""
echo "[4/4] Restarting SSH..."
sudo systemctl restart ssh
echo "  -> SSH restarted"

echo ""
echo "============================================"
echo "  Done! SSH key-only mode."
echo "  Password auth disabled."
echo "============================================"
