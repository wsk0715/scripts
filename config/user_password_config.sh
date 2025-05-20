#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  User password setup"
echo "============================================"
echo ""

EXEC_USER=$(whoami)

# 비밀번호 입력 (입력 안 하면 유저명)
while true; do
  read -s -r -p "Enter password (default: $EXEC_USER): " USER_PASS
  echo ""
  USER_PASS="${USER_PASS:-$EXEC_USER}"

  read -s -r -p "Confirm password: " CONFIRM_PASS
  echo ""

  if [ "$USER_PASS" != "$CONFIRM_PASS" ]; then
    echo "❌ Passwords do not match. Try again."
    echo ""
    USER_PASS=""
    continue
  fi
  break
done

echo ""
echo "[1/1] Setting password for $EXEC_USER..."
echo "$EXEC_USER:$USER_PASS" | sudo chpasswd
echo "  -> password updated"

echo ""
echo "============================================"
echo "  Done!"
echo "============================================"
