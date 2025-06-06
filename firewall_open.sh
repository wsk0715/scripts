#!/bin/bash

set -e

echo "🔓 80, 443 포트 허용"
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT

echo "💾 룰 저장 및 영구 적용"
sudo netfilter-persistent save
sudo netfilter-persistent reload

echo "✅ 포트 설정 완료"
