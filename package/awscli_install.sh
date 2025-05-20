#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=/usr/local/bin}"

# 아키텍처 감지
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
  aarch64) AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
  *)       echo "  -> Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "============================================"
echo "  AWS CLI v2 Setup ($ARCH)"
echo "============================================"

echo ""
echo "[1/3] Downloading AWS CLI v2..."
curl -fsSL -o /tmp/awscliv2.zip "$AWS_URL"
echo "  -> Downloaded"

echo ""
echo "[2/3] Extracting..."
unzip -q /tmp/awscliv2.zip -d /tmp/awscli
echo "  -> Extracted"

echo ""
echo "[3/3] Installing..."
sudo /tmp/awscli/aws/install --update --bin-dir "$PREFIX"
rm -rf /tmp/awscliv2.zip /tmp/awscli
echo "  -> Installed to "$PREFIX"/aws"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

aws --version
