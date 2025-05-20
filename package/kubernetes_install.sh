#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Kubernetes setup"
echo "============================================"

echo ""
echo "[1/5] Installing APT prerequisites..."
sudo apt update
sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  gnupg \
  curl
echo "  -> prerequisites installed"

echo ""
echo "[2/5] Resolving latest stable Kubernetes version..."
KUBE_MINOR=$(curl -sL https://dl.k8s.io/release/stable.txt | sed 's/^v//' | cut -d. -f1-2)
if [ -z "$KUBE_MINOR" ]; then
  KUBE_MINOR="1.33"
  echo "  -> API unavailable, fallback: v$KUBE_MINOR"
else
  echo "  -> Kubernetes v$KUBE_MINOR"
fi

echo ""
echo "[3/5] Registering GPG key..."
KEYRING_PATH="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
if [ -f "$KEYRING_PATH" ]; then
  BACKUP="$KEYRING_PATH.bak.$(date +%s)"
  sudo cp "$KEYRING_PATH" "$BACKUP"
  echo "  -> existing key backed up to $BACKUP"
fi
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR}/deb/Release.key" | \
  sudo gpg --dearmor -o "$KEYRING_PATH"
echo "  -> GPG key registered"

echo ""
echo "[4/5] Adding Kubernetes APT repository..."
SOURCE_LIST="/etc/apt/sources.list.d/kubernetes.list"
if [ -f "$SOURCE_LIST" ]; then
  BACKUP="$SOURCE_LIST.bak.$(date +%s)"
  sudo cp "$SOURCE_LIST" "$BACKUP"
  echo "  -> existing repo list backed up to $BACKUP"
fi
sudo rm -f "$SOURCE_LIST"
echo "deb [signed-by=$KEYRING_PATH] https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR}/deb/ /" | \
  sudo tee "$SOURCE_LIST" > /dev/null
echo "  -> repository added (v$KUBE_MINOR)"

echo ""
echo "[5/5] Updating and installing Kubernetes components..."
sudo apt update
KUBEADM_VER=$(apt-cache madison kubeadm 2>/dev/null | head -1 | awk '{print $3}' | sed 's/-.*//' || echo "latest")
sudo apt install kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl
echo "  -> kubelet, kubeadm, kubectl installed (${KUBEADM_VER})"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
