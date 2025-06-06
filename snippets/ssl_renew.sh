#!/bin/bash

# SSL 인증서 갱신 스크립트 생성 + 크론탭 등록

set -e

SCHEDULER_DIR="/scheduler"
SCRIPT_PATH="$SCHEDULER_DIR/ssl_renew.sh"
LOG_FILE="$SCHEDULER_DIR/ssl_renew.log"

mkdir -p "$SCHEDULER_DIR"

# 1. certbot 경로 확인
CERTBOT=$(which certbot)
if [ -z "$CERTBOT" ]; then
  echo "❌ certbot이 설치되어 있지 않습니다."
  exit 1
fi

# 2. 실행 스크립트 작성
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
echo "[📆 \$(date)] certbot 갱신 시작" >> "$LOG_FILE"
$CERTBOT renew --quiet --deploy-hook "systemctl reload nginx" >> "$LOG_FILE" 2>&1
echo "[📆 \$(date)] certbot 갱신 종료" >> "$LOG_FILE"
EOF

chmod +x "$SCRIPT_PATH"

# 3. 크론탭 등록 (매월 1일 03:00)
CRON_JOB="0 3 1 * * sudo bash $SCRIPT_PATH"

if crontab -l 2>/dev/null | grep -Fq "$SCRIPT_PATH"; then
  echo "ℹ️ 이미 크론탭에 등록되어 있습니다."
else
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "✅ 크론탭 등록 완료: 매월 1일 03:00에 인증서 갱신 실행"
fi
