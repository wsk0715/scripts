#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Docker daemon config for Kubernetes"
echo "============================================"

DAEMON_FILE_NAME="/etc/docker/daemon.json"

echo ""
echo "[1/2] Configuring daemon.json..."
if [ -f "$DAEMON_FILE_NAME" ]; then
  sudo cp "$DAEMON_FILE_NAME" "${DAEMON_FILE_NAME}.bak.$(date +%s)"
  echo "  -> existing daemon.json backed up"
fi

sudo tee "$DAEMON_FILE_NAME" > /dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
echo "  -> daemon.json written"

echo ""
echo "[2/2] Restarting Docker service..."
sudo systemctl restart docker

echo ""
echo "============================================"
echo "  Done! Docker daemon configured for K8s."
echo "============================================"
