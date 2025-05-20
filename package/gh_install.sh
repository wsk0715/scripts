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
echo "  GitHub CLI setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/3] Resolving latest gh version..."
VERSION=$(curl -sI https://github.com/cli/cli/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="2.45.0"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> gh v$VERSION"
fi

echo ""
echo "[2/3] Downloading gh..."
curl -fsSL -o /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_${GOARCH}.tar.gz"
echo "  -> Downloaded"

echo ""
echo "[3/3] Installing..."
tar xf /tmp/gh.tar.gz -C /tmp/
sudo cp "/tmp/gh_${VERSION}_linux_${GOARCH}/bin/gh" "$PREFIX"/gh
sudo chmod +x "$PREFIX"/gh
rm -rf "/tmp/gh_${VERSION}_linux_${GOARCH}" /tmp/gh.tar.gz
echo "  -> Installed to "$PREFIX"/gh"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

gh --version
