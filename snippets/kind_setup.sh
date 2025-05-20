#!/bin/bash

# kind 및 kubectl 설치 스크립트

set -e

echo "📦 [1/3] kind 바이너리 다운로드 (v0.22.0)"
# 1. kind 바이너리 다운로드 (현재 최신 v0.22.0 기준)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64

echo "🔑 [2/3] kind 실행 권한 부여 및 이동"
# 2. 실행 권한 부여
chmod +x ./kind

# 3. /usr/local/bin으로 이동 (어디서나 실행 가능하게)
sudo mv ./kind /usr/local/bin/kind

echo "📥 [3/3] kubectl 설치"
# curl 방식을 사용하여 최신 버전의 kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm ./kubectl

echo "✅ 완료! kind 및 kubectl 설치됨"
