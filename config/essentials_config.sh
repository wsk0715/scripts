#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  Essential system packages"
echo "============================================"

echo ""
echo "[1/1] Updating package lists and installing essentials..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl wget ca-certificates gnupg lsb-release software-properties-common \
  build-essential pkg-config \
  unzip zip xz-utils \
  git vim bash-completion \
  htop tree tmux rsync net-tools iproute2 dnsutils lsof strace sysstat \
  cron file \
  iptables-persistent \
  python3 python3-pip python3-venv \
  eza
echo "  -> packages installed"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
