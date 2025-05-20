#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  inotify Limits Tuning"
echo "============================================"
echo ""
echo "Docker 컨테이너가 많으면 inotify watch 한도 초과 가능."
echo "기본값: max_user_watches=8192 → 1048576"
echo ""

echo "[1/4] Checking current values..."
echo "  max_user_watches:  $(cat /proc/sys/fs/inotify/max_user_watches)"
echo "  max_user_instances: $(cat /proc/sys/fs/inotify/max_user_instances)"

echo ""
echo "[2/4] Writing sysctl config..."
echo 'fs.inotify.max_user_watches = 1048576' | sudo tee /etc/sysctl.d/90-inotify.conf > /dev/null
echo 'fs.inotify.max_user_instances = 512' | sudo tee -a /etc/sysctl.d/90-inotify.conf > /dev/null
echo "  -> /etc/sysctl.d/90-inotify.conf written"

echo ""
echo "[3/4] Applying..."
sudo sysctl --system > /dev/null 2>&1
echo "  -> Applied"

echo ""
echo "[4/4] Verification..."
echo "  max_user_watches:  $(cat /proc/sys/fs/inotify/max_user_watches)"
echo "  max_user_instances: $(cat /proc/sys/fs/inotify/max_user_instances)"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
