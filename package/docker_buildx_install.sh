#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=${HOME}/.docker/cli-plugins}"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GOARCH="amd64" ;;
  aarch64) GOARCH="arm64" ;;
  *)       echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  Docker Buildx Plugin Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/3] Resolving latest buildx version..."
VERSION=$(curl -sI https://github.com/docker/buildx/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="0.22.0"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> buildx v$VERSION"
fi

echo ""
echo "[2/3] Downloading buildx..."
mkdir -p "$PREFIX"
curl -fsSL -o "$PREFIX/docker-buildx" \
  "https://github.com/docker/buildx/releases/download/v${VERSION}/buildx-v${VERSION}.linux-${GOARCH}"
chmod +x "$PREFIX/docker-buildx"
echo "  -> Installed to $PREFIX/docker-buildx"

echo ""
echo "[3/3] Verifying..."
docker buildx version
echo ""

echo "============================================"
echo "  Done!"
echo "============================================"
