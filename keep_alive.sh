#!/bin/bash

# 네트워크 트래픽 + CPU 부하 발생 (인스턴스 회수 방지)

# 1. 네트워크 트래픽 발생 (ping + curl)
ping -c 2 8.8.8.8 > /dev/null 2>&1
curl -s https://www.google.com > /dev/null 2>&1

# 2. CPU 부하 유발 (5초 동안 yes 실행)
timeout 5s yes > /dev/null 2>&1

# 3. 로그 기록
echo "$(date): keepalive executed" >> ~/keepalive.log

# 4. 크론탭 표현식 등록 (매일 새벽 4시)
SCRIPT_PATH="$(realpath "$0")"
CRON_EXPRESSION="0 4 * * * sudo bash $SCRIPT_PATH"

# 크론탭에 이미 등록돼 있는지 확인
if crontab -l 2>/dev/null | grep -Fq "$SCRIPT_PATH"; then
  echo "[*] 크론탭에 이미 등록되어 있음."
else
  (crontab -l 2>/dev/null; echo "$CRON_EXPRESSION") | crontab -
  echo "[+] 크론탭에 등록 완료: 매일 새벽 4시에 자동 실행됩니다."
fi
