#!/bin/bash

set -e

# 베이스 디렉토리 계산
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/resources/kind-config.yaml"

echo "🐳 kind & kubectl 설치 중..."
sudo bash "$SCRIPT_DIR/snippets/kind_setup.sh"

echo "✅  kind & kubectl 설치 완료!"
echo "🏗️  kind 클러스터 생성 중..."

# 0. 로컬 레지스트리 실행
echo "🐳 로컬 레지스트리 설정 중..."
sudo usermod -aG docker $USER
if [ "$(docker inspect -f '{{.State.Running}}' kind-registry 2>/dev/null || true)" != 'true' ]; then
    docker run -d --restart=always -p 5001:5000 --name kind-registry registry:2
    echo "✅ 로컬 레지스트리가 실행되었습니다. (Port: 5001)"
else
    echo "ℹ️  로컬 레지스트리가 이미 실행 중입니다."
fi

# 1. 설정 파일 존재 여부 확인
if [ ! -f "$CONFIG_PATH" ]; then
    echo "❌ 에러: $CONFIG_PATH 파일을 찾을 수 없습니다."
    exit 1
fi

# 2. 데이터 디렉토리 초기화
KIND_DIR="$HOME/kind"
echo "🧹 데이터 디렉토리 초기화 중: $KIND_DIR"
if [ -d "$KIND_DIR" ]; then
    # 기존 데이터가 있으면 삭제
    sudo rm -rf "$KIND_DIR"
fi
mkdir -p "$KIND_DIR/data"
chmod -R 777 "$KIND_DIR"
echo "✅ 데이터 디렉토리 준비 완료."

# 3. 새 클러스터 초기화 (기본값: kind)
if kind get clusters | grep -q "^kind$"; then
    echo "⚠️  기존 'kind' 클러스터가 발견되었습니다. 삭제 후 재설치합니다..."
    kind delete cluster --name kind
    echo "✅ 기존 클러스터 삭제 완료."
fi
kind create cluster --config "$CONFIG_PATH"
echo "✅ 클러스터 생성 완료!"
# 클러스터 네트워크와 레지스트리 연결
docker network connect kind kind-registry 2>/dev/null || true
echo "✅ 레지스트리-클러스터 네트워크 연결 완료!"

# 현재 컨텍스트 확인
kubectl cluster-info --context kind-kind
