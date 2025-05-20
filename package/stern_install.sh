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
echo "  stern Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/2] Resolving latest stern version..."
VERSION=$(curl -sI https://github.com/stern/stern/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="1.32.0"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> stern v$VERSION"
fi

echo ""
echo "[2/2] Downloading and installing..."
curl -fsSL -o /tmp/stern.tar.gz "https://github.com/stern/stern/releases/download/v${VERSION}/stern_${VERSION}_linux_${GOARCH}.tar.gz"
tar xf /tmp/stern.tar.gz -C /tmp/ stern
sudo mv /tmp/stern "$PREFIX"/stern
sudo chmod +x "$PREFIX"/stern
rm /tmp/stern.tar.gz
echo "  -> Installed to "$PREFIX"/stern"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
stern --version
