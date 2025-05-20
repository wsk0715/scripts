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
echo "  jq Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/2] Resolving latest jq version..."
VERSION=$(curl -sI https://github.com/jqlang/jq/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/jq-//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="1.7.1"
  echo "  -> API unavailable, fallback: $VERSION"
else
  echo "  -> jq $VERSION"
fi

echo ""
echo "[2/2] Downloading and installing..."
curl -fsSL -o /tmp/jq "https://github.com/jqlang/jq/releases/download/jq-${VERSION}/jq-linux-${GOARCH}"
sudo mv /tmp/jq "$PREFIX"/jq
sudo chmod +x "$PREFIX"/jq
echo "  -> Installed to "$PREFIX"/jq"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
jq --version
