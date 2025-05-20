#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=/usr/local/bin}"

# 아키텍처 감지
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  GOARCH="amd64" ;;
  aarch64) GOARCH="arm64" ;;
  *)       echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  Cloudflare CLI setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/3] Resolving latest cloudflared version..."
VERSION=$(curl -sI https://github.com/cloudflare/cloudflared/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\///' | tr -d '\r\n')
if [ -z "$VERSION" ]; then
  VERSION="2025.5.0"
  echo "  -> API unavailable, fallback: v$VERSION"
else
  echo "  -> cloudflared v$VERSION"
fi

echo ""
echo "[2/3] Downloading cloudflared..."
URL="https://github.com/cloudflare/cloudflared/releases/download/${VERSION}/cloudflared-linux-${GOARCH}"
curl -fsSL -o /tmp/cloudflared "$URL"
chmod +x /tmp/cloudflared
echo "  -> Downloaded"

echo ""
echo "[3/3] Installing..."
sudo mv /tmp/cloudflared "$PREFIX"/cloudflared
echo "  -> Installed to "$PREFIX"/cloudflared"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

echo ""
echo "Next step — authenticate:"
echo "  1. Get an API token from https://dash.cloudflare.com/profile/api-tokens"
echo "     (minimum: Zone:DNS:Edit for your domain)"
echo "  2. Run: cloudflared tunnel login"
echo "     OR set env var: export CLOUDFLARE_API_KEY=your_api_token"
echo ""
cloudflared version
