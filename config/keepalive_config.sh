#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  keep_alive scheduler setup"
echo "============================================"

SCHEDULER_DIR="/scheduler"
SCRIPT_PATH="$SCHEDULER_DIR/keep_alive.sh"
LOG_FILE="$SCHEDULER_DIR/keep_alive.log"

echo ""
echo "[1/2] Creating keep_alive script..."
sudo mkdir -p "$SCHEDULER_DIR"
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
echo "[📆 \$(date)] keepalive 실행" >> "$LOG_FILE"
ping -c 2 8.8.8.8 >> "$LOG_FILE" 2>&1
curl -s https://www.google.com >> "$LOG_FILE" 2>&1
timeout 5s yes > /dev/null 2>&1
echo "[📆 \$(date)] keepalive 종료" >> "$LOG_FILE"
EOF
chmod +x "$SCRIPT_PATH"
echo "  -> script created at $SCRIPT_PATH"

echo ""
echo "[2/2] Registering crontab (daily 04:00)..."
CRON_JOB="0 4 * * * sudo bash $SCRIPT_PATH"
if crontab -l 2>/dev/null | grep -Fq "$SCRIPT_PATH"; then
  echo "  -> already registered in crontab"
else
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "  -> crontab registered"
fi

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
