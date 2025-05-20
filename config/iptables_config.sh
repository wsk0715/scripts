#!/usr/bin/env bash
# ===================================================
# iptables_setup.sh — Restrictive host firewall
#
# Drops all inbound traffic EXCEPT:
#   SSH (22), HTTP (80), HTTPS (443)
#   RELATED,ESTABLISHED connections
#   Loopback interface
#   Kind/Docker bridge internal rules (br-132f9502f529)
#
# Docker FORWARD traffic is handled by DOCKER-USER chain
# and is NOT modified.
#
# Usage:
#   sudo ./iptables_setup.sh          — show current status
#   sudo ./iptables_setup.sh apply    — apply rules + persist
#   sudo ./iptables_setup.sh backup   — save current rules
#   sudo ./iptables_setup.sh restore  — restore from backup
# ===================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/etc/iptables}"
TIMESTAMP="$(date +%s)"

# Allowed inbound TCP ports
ALLOW_TCP_PORTS=(22 80 443)

# Kind control-plane bridge (for internal cluster comms)
KIND_BRIDGE="br-132f9502f529"

# ── Status ──────────────────────────────────────────────
status() {
  echo "━━━ INPUT Chain ──────────────────────────"
  sudo iptables -L INPUT -n -v --line-numbers 2>/dev/null | head -20
  echo ""
  echo "━━━ DOCKER-USER Chain ────────────────────"
  sudo iptables -L DOCKER-USER -n -v --line-numbers 2>/dev/null | head -10
  echo ""
  echo "━━━ Listening on 0.0.0.0 ─────────────────"
  ss -tlnp 4 2>/dev/null | awk '$4 ~ /^0\\.0\\.0\\.0:/ || $4 ~ /^\\*:/ {print "  " $4}' | head -10
}

# ── Backup ──────────────────────────────────────────────
backup() {
  local path="${BACKUP_DIR}/rules.v4.backup.${TIMESTAMP}"
  sudo mkdir -p "${BACKUP_DIR}"
  sudo iptables-save > "${path}"
  echo "  -> Backup saved: ${path}"
}

# ── Restore ─────────────────────────────────────────────
restore() {
  local latest
  latest="$(ls -t "${BACKUP_DIR}"/rules.v4.backup.* 2>/dev/null | head -1)"
  if [[ -z "${latest}" ]]; then
    echo "  -> No backup found in ${BACKUP_DIR}"
    exit 1
  fi
  sudo iptables-restore < "${latest}"
  echo "  -> Restored from: ${latest}"
}

# ── Apply ───────────────────────────────────────────────
apply() {
  echo "  Applying firewall rules..."
  backup

  sudo iptables -F INPUT

  sudo iptables -A INPUT -i lo -j ACCEPT
  echo "  -> lo → ACCEPT"

  sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  echo "  -> RELATED,ESTABLISHED → ACCEPT"

  for port in "${ALLOW_TCP_PORTS[@]}"; do
    sudo iptables -A INPUT -p tcp --dport "${port}" -j ACCEPT
    echo "  -> tcp/${port} → ACCEPT"
  done

  sudo iptables -A INPUT -i "${KIND_BRIDGE}" -p udp --dport 5353 -j ACCEPT
  sudo iptables -A INPUT -i "${KIND_BRIDGE}" -p tcp --dport 8088 -j ACCEPT
  echo "  -> kind bridge (${KIND_BRIDGE}) internal rules → ACCEPT"

  sudo iptables -P INPUT DROP
  echo "  -> INPUT policy → DROP"

  if command -v netfilter-persistent &>/dev/null; then
    sudo netfilter-persistent save >/dev/null 2>&1
    echo "  -> Rules persisted via netfilter-persistent"
  else
    sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null
    echo "  -> Rules saved to /etc/iptables/rules.v4"
  fi

  echo ""
  echo "━━━ Result ──────────────────────────────"
  sudo iptables -L INPUT -n -v --line-numbers 2>/dev/null | grep -E '^[0-9]' | head -10
}

# ── Main ────────────────────────────────────────────────
case "${1:-}" in
  apply)   apply ;;
  backup)  backup ;;
  restore) restore ;;
  status|--status|-s) status ;;
  *)
    echo "Usage: $(basename "$0") {apply|backup|restore|status}"
    echo ""
    status
    ;;
esac
