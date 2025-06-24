#!/bin/bash

# Docker 데몬 설정 파일(/etc/docker/daemon.json) 에 K8s 권장 설정 추가

DAEMON_FILE_NAME="/etc/docker/daemon.json"

# 기존 파일 백업
if [ -f "$DAEMON_FILE_NAME" ]; then
  sudo cp "$DAEMON_FILE_NAME" "${DAEMON_FILE_NAME}.bak.$(date +%s)"
  echo "기존 daemon.json 백업 완료: ${DAEMON_FILE_NAME}.bak.*"
fi

# 내용 작성
sudo tee "$DAEMON_FILE_NAME" > /dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

echo "설정이 적용되었습니다: $DAEMON_FILE_NAME"

# Docker 데몬 재시작
echo "Docker 서비스를 재시작합니다..."
sudo systemctl restart docker

echo "✅ Docker Daemon 설정 완료"
