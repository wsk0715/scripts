#!/usr/bin/env bash
# ===================================================
# kind + kubectl — local Kubernetes cluster
# Installs kind and kubectl binaries, then starts a
# local registry container for development.
# ===================================================
set -euo pipefail

: "${PREFIX:=/usr/local/bin}"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GOARCH="amd64" ;;
  aarch64) GOARCH="arm64" ;;
  *)       echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  kind & kubectl ($GOARCH)"
echo "============================================"

echo ""
echo "[1/4] Resolving latest kind version..."
KIND_VERSION=$(curl -sI https://github.com/kubernetes-sigs/kind/releases/latest \
  | grep -i '^location:' | sed 's/.*\/v//' | tr -d '\r\n')
if [ -z "$KIND_VERSION" ]; then
  KIND_VERSION="0.32.0"
  echo "  -> API unavailable, fallback: v$KIND_VERSION"
else
  echo "  -> kind v$KIND_VERSION"
fi

echo ""
echo "[2/4] Downloading kind binary..."
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${GOARCH}"
chmod +x ./kind
sudo mv ./kind "$PREFIX/kind"
echo "  -> kind installed (v$KIND_VERSION)"

echo ""
echo "[3/4] Installing kubectl (latest stable)..."
KUBE_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${GOARCH}/kubectl"
sudo install -o root -g root -m 0755 kubectl "$PREFIX/kubectl"
rm ./kubectl
echo "  -> kubectl installed ($KUBE_VERSION)"

echo ""
echo "[4/4] Setting up local registry..."
sudo usermod -aG docker "$USER" 2>/dev/null || true
if [ "$(docker inspect -f '{{.State.Running}}' kind-registry 2>/dev/null || true)" != 'true' ]; then
  docker run -d --restart=always -p 5001:5000 --name kind-registry registry:2
  echo "  -> local registry started (port 5001)"
else
  echo "  -> local registry already running"
fi

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
