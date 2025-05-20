#!/bin/bash

# Kubernetes APT 저장소 및 패키지 설치 스크립트 (Docker 기반)


set -e  # 에러 발생 시 스크립트 중단

echo "📦 [1/5] APT 필수 패키지 설치"
sudo apt update
sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  gnupg \
  curl


echo "🔑 [2/5] GPG 키 등록"
KEYRING_PATH="/etc/apt/keyrings/kubernetes-apt-keyring.gpg"
# 기존 키 백업
if [ -f "$KEYRING_PATH" ]; then
  BACKUP="$KEYRING_PATH.bak.$(date +%s)"
  sudo cp "$KEYRING_PATH" "$BACKUP"
  echo "📁 기존 키 백업 완료 → $BACKUP"
fi

# 새로운 키 등록
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | \
  sudo gpg --dearmor -o "$KEYRING_PATH"


echo "🗂 [3/5] Kubernetes APT 저장소 등록"
# 기존 저장소 백업
SOURCE_LIST="/etc/apt/sources.list.d/kubernetes.list"
if [ -f "$SOURCE_LIST" ]; then
  BACKUP="$SOURCE_LIST.bak.$(date +%s)"
  sudo cp "$SOURCE_LIST" "$BACKUP"
  echo "📁 기존 저장소 리스트 백업 완료 → $BACKUP"
fi

# 새로운 저장소 등록
sudo rm -f "$SOURCE_LIST"
echo "deb [signed-by=$KEYRING_PATH] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" | \
  sudo tee "$SOURCE_LIST" > /dev/null


echo "🔄 [4/5] APT 패키지 목록 갱신"
sudo apt update


echo "📥 [5/5] Kubernetes 구성 요소 설치"
sudo apt install kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl


echo "✅ 완료! kubelet, kubeadm, kubectl 설치됨"
