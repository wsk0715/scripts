#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=/usr/local/bin}"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GOARCH="amd64" ;;
  aarch64) GOARCH="arm64" ;;
  *)       echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  kubectl setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/2] Resolving latest kubectl version..."
KUBE_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
echo "  -> kubectl $KUBE_VERSION"

echo ""
echo "[2/2] Downloading and installing..."
curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${GOARCH}/kubectl"
sudo install -o root -g root -m 0755 /tmp/kubectl "$PREFIX"/kubectl
rm /tmp/kubectl
echo "  -> Installed to "$PREFIX"/kubectl"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

kubectl version --client
