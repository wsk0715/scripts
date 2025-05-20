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
echo "  k6 Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/2] Resolving latest k6 version..."
VERSION=$(curl -sI https://github.com/grafana/k6/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="0.58.0"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> k6 v$VERSION"
fi

echo ""
echo "[2/2] Downloading and installing..."
curl -fsSL -o /tmp/k6.tar.gz "https://github.com/grafana/k6/releases/download/v${VERSION}/k6-v${VERSION}-linux-${GOARCH}.tar.gz"
tar xf /tmp/k6.tar.gz -C /tmp/
sudo mv "/tmp/k6-v${VERSION}-linux-${GOARCH}/k6" "$PREFIX"/k6
sudo chmod +x "$PREFIX"/k6
rm -rf "/tmp/k6-v${VERSION}-linux-${GOARCH}" /tmp/k6.tar.gz
echo "  -> Installed to "$PREFIX"/k6"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
k6 version
