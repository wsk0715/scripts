#!/bin/bash

set -e

echo "📦 Updating package list..."
sudo apt update

echo "⬆️ Upgrading existing packages..."
sudo apt upgrade -y

echo "🔧 Installing essential utilities..."
sudo apt install -y curl git build-essential software-properties-common

echo "✅ utilities installed successfully!"
