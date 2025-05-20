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
echo "  LogCLI Setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/3] Resolving latest Loki version..."
LOKI_VERSION=$(curl -sI https://github.com/grafana/loki/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$LOKI_VERSION" ]; then
  LOKI_VERSION="3.4.2"
  echo "  -> API unavailable, fallback: v$LOKI_VERSION"
else
  echo "  -> Loki v$LOKI_VERSION"
fi

echo ""
echo "[2/3] Downloading logcli..."
curl -fLO "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/logcli-linux-${GOARCH}.zip" --output-dir /tmp/
echo "  -> downloaded"

echo ""
echo "[3/3] Installing logcli..."
cd /tmp
unzip -o "logcli-linux-${GOARCH}.zip"
chmod +x "logcli-linux-${GOARCH}"
sudo mv "logcli-linux-${GOARCH}" "$PREFIX"/logcli
rm -f "logcli-linux-${GOARCH}.zip"
cd - > /dev/null
echo "  -> installed (v$LOKI_VERSION)"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
