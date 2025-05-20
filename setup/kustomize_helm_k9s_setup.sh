#!/usr/bin/env bash
set -euo pipefail

# 아키텍처 감지
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GOARCH="amd64" ;;
  aarch64) GOARCH="arm64" ;;
  *)       echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  Kustomize, Helm & K9s setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/3] Installing Kustomize..."
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/
echo "  -> Kustomize installed"

echo ""
echo "[2/3] Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sudo rm get_helm.sh
echo "  -> Helm installed"

echo ""
echo "[3/3] Installing K9s..."
K9S_VERSION=$(curl -sI https://github.com/derailed/k9s/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$K9S_VERSION" ]; then
  K9S_VERSION="0.40.5"
  echo "  -> API unavailable, fallback: v$K9S_VERSION"
else
  echo "  -> K9s v$K9S_VERSION"
fi
curl -sL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${GOARCH}.tar.gz" | tar xfz - k9s
sudo mv k9s /usr/local/bin/
echo "  -> K9s installed ($GOARCH)"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

kustomize version
helm version
k9s version
