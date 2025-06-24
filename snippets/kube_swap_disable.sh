#!/bin/bash

# Kubernetes를 실행하기 위해 스왑 메모리를 비활성화


# 현재 스왑 영역 비활성화
sudo swapoff -a
# 스왑 메모리 설정 주석처리(영구 적용)
sudo sed -i '/ swap / s/^/#/' /etc/fstab
