#!/usr/bin/env bash
# ===================================================
# Docker Engine — bare installation
# Installs: docker-ce, docker-ce-cli, containerd.io,
#           docker-buildx-plugin, docker-compose-plugin
# ===================================================
set -euo pipefail

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|aarch64) ;;
  *)  echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  Docker Engine install ($ARCH)"
echo "============================================"

echo ""
echo "[1/4] Removing old Docker packages..."
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
echo "  -> old packages removed"

echo ""
echo "[2/4] Installing dependencies..."
sudo apt update -qq
sudo apt install -y -qq ca-certificates curl gnupg lsb-release
echo "  -> dependencies installed"

echo ""
echo "[3/4] Adding Docker GPG key and repository..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "  -> GPG key and repository added"

echo ""
echo "[4/4] Installing Docker..."
sudo apt update -qq
sudo apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
echo "  -> Docker installed"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
