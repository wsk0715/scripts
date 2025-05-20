#!/usr/bin/env bash
set -euo pipefail

SWAP_PATH="/swapfile"

echo "============================================"
echo "  Swap file setup (auto: max(RAM/2, 2GB))"
echo "============================================"

echo ""
echo "[1/4] Calculating swap size..."
TOTAL_RAM_KB=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
TOTAL_RAM_GB=$(( TOTAL_RAM_KB / 1024 / 1024 ))
RAM_QUARTER_GB=$(( TOTAL_RAM_GB / 2 ))
MIN_SWAP_GB=2
SWAP_SIZE_GB=$(( RAM_QUARTER_GB > MIN_SWAP_GB ? RAM_QUARTER_GB : MIN_SWAP_GB ))
echo "  -> RAM: ${TOTAL_RAM_GB}GB, RAM/4: ${RAM_QUARTER_GB}GB"
echo "  -> Swap size: ${SWAP_SIZE_GB}GB"

echo ""
echo "[2/4] Creating ${SWAP_SIZE_GB}G swap file..."
# 기존 swap이 활성화되어 있으면 해제 후 생성 (Text file busy 방지)
if swapon --show=name --noheadings 2>/dev/null | grep -qxF "${SWAP_PATH}"; then
  echo "  -> existing swap detected, turning off..."
  sudo swapoff "${SWAP_PATH}"
fi
sudo dd if=/dev/zero of=${SWAP_PATH} bs=1M count=$(( SWAP_SIZE_GB * 1024 )) status=progress
sudo chmod 600 ${SWAP_PATH}
echo "  -> swap file created"

echo ""
echo "[3/4] Initializing and enabling swap..."
sudo mkswap ${SWAP_PATH}
sudo swapon ${SWAP_PATH}
echo "  -> swap enabled"

echo ""
echo "[4/4] Registering in fstab and tuning..."
# fstab — 주석처리된 항목 복원 또는 새로 추가
if grep -q "^#${SWAP_PATH}" /etc/fstab 2>/dev/null; then
  sudo sed -i "s|^#${SWAP_PATH}|${SWAP_PATH}|" /etc/fstab
  echo "  -> fstab entry uncommented"
elif ! grep -q "^${SWAP_PATH}" /etc/fstab 2>/dev/null; then
  echo "${SWAP_PATH} none swap sw 0 0" | sudo tee -a /etc/fstab
  echo "  -> fstab entry added"
else
  echo "  -> already in fstab"
fi

# swappiness=10
if [ "$(cat /proc/sys/vm/swappiness)" -ne 10 ]; then
  echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swap.conf > /dev/null
  sudo sysctl -w vm.swappiness=10 > /dev/null
  echo "  -> swappiness=10 set"
else
  echo "  -> swappiness already 10"
fi

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
swapon --show
free -h
