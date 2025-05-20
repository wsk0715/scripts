#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Kakao mirror server setup"
echo "============================================"

NEW_SOURCES="/etc/apt/sources.list.d/ubuntu.sources"
OLD_SOURCES="/etc/apt/sources.list"

echo ""
echo "[1/3] Updating new-style sources ($NEW_SOURCES)..."
if [ -f "$NEW_SOURCES" ]; then
    sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$NEW_SOURCES"
    sudo sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$NEW_SOURCES"
    echo "  -> $NEW_SOURCES updated"
else
    echo "  -> new-style sources file not found"
fi

echo ""
echo "[2/3] Updating old-style sources ($OLD_SOURCES)..."
if [ -f "$OLD_SOURCES" ]; then
    sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$OLD_SOURCES"
    sudo sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$OLD_SOURCES"
    echo "  -> $OLD_SOURCES updated"
else
    echo "  -> old-style sources file not found"
fi

echo ""
echo "[3/3] Updating package lists..."
sudo apt update

echo ""
echo "============================================"
echo "  Done! Mirror server changed to Kakao."
echo "============================================"
