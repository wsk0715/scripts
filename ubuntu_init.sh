#!/bin/bash

set -e

echo "📦 Updating package list..."
sudo apt update

echo "⬆️ Upgrading existing packages..."
sudo apt upgrade -y

echo "🔧 Installing essential utilities..."
sudo apt install -y \
  curl \
  wget \
  cron \
  file \
  unzip \
  git \
  vim \
  bash-completion \
  build-essential \
  software-properties-common \
  ca-certificates \
  lsb-release \
  gnupg \
  ufw \
  net-tools \
  iptables-persistent

echo "✅ utilities installed successfully!"

echo "🕒 Enabling cron service..."
sudo systemctl enable cron
sudo systemctl start cron

echo "🧹 Cleaning up..."
sudo apt autoremove -y
sudo apt clean

echo "🎉 All set! Ubuntu base setup complete."