#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  OCI CLI Setup (no-sudo)"
echo "============================================"

echo ""
echo "[0/1] Cleaning previous installation..."
sudo rm -rf /root/lib/oracle-cli /root/bin/oci 2>/dev/null || true
echo "  -> Cleaned"

echo ""
echo "[1/1] Installing OCI CLI..."
curl -fsSL -o /tmp/oci-install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod +x /tmp/oci-install.sh
/tmp/oci-install.sh --accept-all-defaults
rm /tmp/oci-install.sh

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
echo ""
echo "  Add to PATH: export PATH=\"\$HOME/bin:\$PATH\""
echo ""
~/bin/oci --version 2>&1 || echo "  Run 'exec -l \$SHELL' and retry"
