#!/usr/bin/env bash
# ===================================================
# Docker Engine — full setup (install + user config)
# Installs Docker, adds current user to docker group,
# and runs a verification.
# ===================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Docker setup"
echo "============================================"

echo ""
echo "[1/2] Installing Docker Engine..."
bash "$SCRIPT_DIR/../package/docker_install.sh"
echo ""

echo "[2/2] Adding user to docker group..."
sudo usermod -aG docker "$USER"
echo "  -> User added to docker group"

# 현재 세션에 docker 그룹 즉시 적용 (재로그인 불필요)
if sg docker -c "docker ps" &>/dev/null; then
  echo "  -> Docker group activated in current session"
else
  echo "  -> Re-login required: newgrp docker  (or log out/in)"
fi
echo ""

echo "============================================"
echo "  Done!"
echo "============================================\n"
sg docker -c "docker run hello-world" 2>&1 | tail -3
sudo docker run hello-world 2>&1 | tail -3
