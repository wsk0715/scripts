#!/bin/bash

# 인스턴스 유지 스크립트 생성 + 크론탭 등록

set -e

SCHEDULER_DIR="/scheduler"
SCRIPT_PATH="$SCHEDULER_DIR/keep_alive.sh"
LOG_FILE="$SCHEDULER_DIR/keep_alive.log"

sudo mkdir -p "$SCHEDULER_DIR"

# 1. 실행 스크립트 작성
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
echo "[📆 \$(date)] keepalive 실행" >> "$LOG_FILE"
ping -c 2 8.8.8.8 >> "$LOG_FILE" 2>&1
curl -s https://www.google.com >> "$LOG_FILE" 2>&1
timeout 5s yes > /dev/null 2>&1
echo "[📆 \$(date)] keepalive 종료" >> "$LOG_FILE"
EOF

chmod +x "$SCRIPT_PATH"

# 2. 크론탭 등록 (매일 04:00)
CRON_JOB="0 4 * * * sudo bash $SCRIPT_PATH"

if crontab -l 2>/dev/null | grep -Fq "$SCRIPT_PATH"; then
  echo "ℹ️ 이미 크론탭에 등록되어 있습니다."
else
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "✅ 크론탭 등록 완료: 매일 04:00에 keepalive 실행"
fi
