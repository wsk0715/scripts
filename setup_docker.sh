#!/bin/bash

set -e

# 1. 기존 docker 관련 패키지 제거 (있을 경우)
sudo apt remove -y docker docker-engine docker.io containerd runc

# 2. 필수 패키지 설치
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 3. Docker 공식 GPG 키 추가
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Docker stable 저장소 등록
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 패키지 인덱스 업데이트 및 Docker 설치
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. 도커 서비스 활성화
sudo systemctl enable docker
sudo systemctl start docker

# 7. 현재 사용자에 docker 그룹 권한 부여
sudo usermod -aG docker $USER

# 8. 설치 확인
sudo docker run hello-world
