#!/bin/bash

# 스왑 파일 크기 설정 (GB 단위)
SWAP_SIZE_GB=2
SWAP_PATH="/swapfile"

echo "Creating ${SWAP_SIZE_GB}GB swap file at ${SWAP_PATH}..."

# 1. 스왑 파일 생성
sudo fallocate -l ${SWAP_SIZE_GB}G ${SWAP_PATH} || {
  echo "fallocate failed. Trying dd..."
  sudo dd if=/dev/zero of=${SWAP_PATH} bs=1G count=${SWAP_SIZE_GB}
}

# 2. 권한 설정
sudo chmod 600 ${SWAP_PATH}

# 3. 스왑 영역 초기화
sudo mkswap ${SWAP_PATH}

# 4. 스왑 활성화
sudo swapon ${SWAP_PATH}

# 5. fstab 등록 (중복 방지)
if ! grep -q "${SWAP_PATH}" /etc/fstab; then
  echo "${SWAP_PATH} none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# 6. 확인
echo "Swap enabled:"
swapon --show
free -h
