#!/bin/bash

# certbot 갱신 + nginx reload + 로그 기록
LOG_FILE="/letsencrypt-renew.log"
CERTBOT=$(which certbot)

if [ -z "$CERTBOT" ]; then
  echo "❌ certbot이 설치되어 있지 않습니다."
  exit 1
fi

# 1. certbot 갱신 시도
echo "[📆 $(date)] certbot 갱신 시작" >> "$LOG_FILE"
$CERTBOT renew --quiet --deploy-hook "systemctl reload nginx" >> "$LOG_FILE" 2>&1
echo "[📆 $(date)] certbot 갱신 종료" >> "$LOG_FILE"

# 2. 크론탭 등록 (현재 스크립트 경로 기준)
SCRIPT_PATH="$(realpath "$0")"
CRON_EXPRESSION="0 3 1 * * sudo bash $SCRIPT_PATH"

# 크론탭에 이미 등록돼 있는지 확인
if crontab -l 2>/dev/null | grep -Fq "$SCRIPT_PATH"; then
  echo "ℹ️ 이미 crontab에 등록되어 있습니다."
else
  (crontab -l 2>/dev/null; echo "$CRON_EXPRESSION") | crontab -
  echo "✅ crontab에 등록 완료: 매월 1일 03:00에 자동 실행"
fi
