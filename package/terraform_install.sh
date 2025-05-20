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
echo "  Terraform setup ($GOARCH)"
echo "============================================"

echo ""
echo "[1/3] Resolving latest Terraform version..."
TERRAFORM_VERSION=$(curl -sI https://github.com/hashicorp/terraform/releases/latest 2>/dev/null | grep -i '^location:' | sed 's/.*\/tag\/v//' | tr -d '\r\n')
if [ -z "$TERRAFORM_VERSION" ]; then
  TERRAFORM_VERSION="1.10.5"
  echo "  -> API unavailable, fallback: v$TERRAFORM_VERSION"
else
  echo "  -> Terraform v$TERRAFORM_VERSION"
fi

echo ""
echo "[2/3] Downloading Terraform..."
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${GOARCH}.zip"
curl -fsSL -o /tmp/terraform.zip "$DOWNLOAD_URL"
echo "  -> Downloaded"

echo ""
echo "[3/3] Installing Terraform..."
unzip -o /tmp/terraform.zip -d /tmp/ >/dev/null 2>&1
sudo mv /tmp/terraform "$PREFIX"/terraform
sudo chmod +x "$PREFIX"/terraform
rm /tmp/terraform.zip
echo "  -> Installed to "$PREFIX"/terraform"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"

terraform version
