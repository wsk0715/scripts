#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  SSL renew scheduler setup"
echo "============================================"

SCHEDULER_DIR="/scheduler"
SCRIPT_PATH="$SCHEDULER_DIR/ssl_renew.sh"
LOG_FILE="$SCHEDULER_DIR/ssl_renew.log"

sudo mkdir -p "$SCHEDULER_DIR"

echo ""
echo "[1/3] Checking certbot..."
CERTBOT=$(which certbot)
if [ -z "$CERTBOT" ]; then
  echo "  -> ERROR: certbot not installed!"
  exit 1
fi
echo "  -> certbot found at $CERTBOT"

echo ""
echo "[2/3] Creating renew script..."
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
echo "[📆 \$(date)] certbot 갱신 시작" >> "$LOG_FILE"
$CERTBOT renew --quiet --deploy-hook "systemctl reload nginx" >> "$LOG_FILE" 2>&1
echo "[📆 \$(date)] certbot 갱신 종료" >> "$LOG_FILE"
EOF
chmod +x "$SCRIPT_PATH"
echo "  -> script created at $SCRIPT_PATH"

echo ""
echo "[3/3] Registering crontab (monthly 1st, 03:00)..."
CRON_JOB="0 3 1 * * sudo bash $SCRIPT_PATH"
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
