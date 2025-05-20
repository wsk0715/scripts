#!/bin/bash

# 1. 대상 파일 정의
NEW_SOURCES="/etc/apt/sources.list.d/ubuntu.sources"
OLD_SOURCES="/etc/apt/sources.list"

echo "🔍 업데이트 서버 확인 중..."

# 2. 최신 방식 (24.04+)
if [ -f "$NEW_SOURCES" ]; then
    echo "✅ 설정 파일 발견: $NEW_SOURCES"
    sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$NEW_SOURCES"
    sudo sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$NEW_SOURCES"
    echo "🚀 $NEW_SOURCES 수정 완료!"
fi

# 3. 기존 방식
if [ -f "$OLD_SOURCES" ]; then
    echo "✅ 설정 파일 발견: $OLD_SOURCES"
    sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$OLD_SOURCES"
    sudo sed -i 's|http://security.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' "$OLD_SOURCES"
    echo "🚀 $OLD_SOURCES 수정 완료!"
fi

# 4. 결과 확인
echo "🔄 패키지 목록 업데이트 시도..."
sudo apt update

echo "✨ 미러 서버 변경 작업이 완료되었습니다!"