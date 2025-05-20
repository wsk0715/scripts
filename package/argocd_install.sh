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
echo "  ArgoCD CLI Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/2] Resolving latest ArgoCD version..."
VERSION=$(curl -sI https://github.com/argoproj/argo-cd/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="2.14.0"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> ArgoCD v$VERSION"
fi

echo ""
echo "[2/2] Downloading and installing..."
curl -fsSL -o /tmp/argocd "https://github.com/argoproj/argo-cd/releases/download/v${VERSION}/argocd-linux-${GOARCH}"
sudo mv /tmp/argocd "$PREFIX"/argocd
sudo chmod +x "$PREFIX"/argocd
echo "  -> Installed to "$PREFIX"/argocd"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
argocd version --client 2>&1 | head -2
