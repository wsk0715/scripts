#!/bin/bash

# 사용자 비밀번호 설정

set -e

EXEC_USER=$(whoami)

# 사용자 비밀번호를 사용자명과 동일하게 설정
echo "$EXEC_USER:$EXEC_USER" | sudo chpasswd

echo "✅ 사용자 비밀번호 설정 완료"
