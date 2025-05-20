#!/usr/bin/env bash
set -euo pipefail
: "${PREFIX:=/usr/local/bin}"

echo "============================================"
echo "  Helm Setup"
echo "============================================"

echo ""
echo "[1/2] Downloading Helm installer..."
curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 /tmp/get_helm.sh
echo "  -> Downloaded"

echo ""
echo "[2/2] Installing Helm..."
/tmp/get_helm.sh
sudo rm /tmp/get_helm.sh
echo "  -> Installed"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
helm version
