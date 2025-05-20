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
echo "  yq Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/2] Resolving latest yq version..."
VERSION=$(curl -sI https://github.com/mikefarah/yq/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="4.44.6"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> yq v$VERSION"
fi

echo ""
echo "[2/2] Downloading and installing..."
curl -fsSL -o /tmp/yq "https://github.com/mikefarah/yq/releases/download/v${VERSION}/yq_linux_${GOARCH}"
sudo mv /tmp/yq "$PREFIX"/yq
sudo chmod +x "$PREFIX"/yq
echo "  -> Installed to "$PREFIX"/yq"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
yq --version
