#!/usr/bin/env bash
# ===================================================
# Bootstrap — Ubuntu server setup
# Covers system essentials, runtimes, shell, web
# server, and firewall in a single pass.
# K8s and advanced tools are manual.
# ===================================================
set -euo pipefail
#set -x  # uncomment for verbose debug

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✅${NC} $1"; }
fail() { echo -e "  ${RED}❌${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC} $1"; }
info() { echo -e "  ${CYAN}ℹ️${NC} $1"; }

echo "============================================"
echo "  Bootstrap"
echo "============================================"
echo "  Started: $(date)"
echo "  Log: $LOG_FILE"
echo ""

# --------------------------------------------------
# Detect hardware
# --------------------------------------------------
TOTAL_RAM_KB=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
TOTAL_RAM_GB=$(( TOTAL_RAM_KB / 1024 / 1024 ))
CPU_CORES=$(nproc 2>/dev/null || echo 1)
info "System: ${CPU_CORES}vCPU / ${TOTAL_RAM_GB}GB RAM"
echo ""

# ============================================================
# Stage 1: System essentials
# ============================================================
echo "============================================"
echo "  Stage 1/5 — System essentials"
echo "============================================"
echo ""

echo "[1.1] Setting APT mirror..."
bash "$SCRIPT_DIR/config/apt_mirror_config.sh" >> /dev/null 2>&1 && ok "APT mirror set (Kakao)" || warn "Mirror skipped"
echo ""

echo "[1.2] Upgrading packages..."
bash "$SCRIPT_DIR/config/package_upgrade_config.sh"
ok "Packages upgraded"
echo ""

echo "[1.3] Installing essential system packages..."
bash "$SCRIPT_DIR/config/essentials_config.sh"
ok "Essential packages installed"
echo ""

if [ "$TOTAL_RAM_GB" -le 2 ]; then
  echo "[1.4] Configuring swap..."
  bash "$SCRIPT_DIR/config/swap_config.sh"
  ok "Swap configured"
else
  info "Swap skipped (${TOTAL_RAM_GB}GB RAM)"
fi
echo ""

echo "[1.5] Tuning inotify limits..."
bash "$SCRIPT_DIR/config/inotify_config.sh"
ok "inotify limits tuned"
echo ""

echo "[1.6] Hardening SSH..."
bash "$SCRIPT_DIR/config/ssh_keyonly_config.sh"
ok "SSH hardened (key-only)"
echo ""

echo "[1.7] Enabling passwordless sudo..."
bash "$SCRIPT_DIR/config/sudo_nopass_config.sh"
ok "Passwordless sudo enabled"
echo ""

# ============================================================
# Stage 2: Runtimes
# ============================================================
echo "============================================"
echo "  Stage 2/5 — Runtimes"
echo "============================================"
echo ""

if command -v docker &>/dev/null; then
  info "Docker already installed ($(docker --version 2>&1 | head -1))"
else
  echo "[2.1] Installing Docker Engine..."
  bash "$SCRIPT_DIR/setup/docker_setup.sh"
  ok "Docker installed (incl. Buildx + Compose)"
fi

echo ""

if command -v node &>/dev/null; then
  info "Node.js already installed ($(node --version 2>&1))"
else
  echo "[2.2] Installing Node.js LTS..."
  bash "$SCRIPT_DIR/package/node_install.sh"
  ok "Node.js installed"
fi
echo ""

# ============================================================
# Stage 3: Shell environment
# ============================================================
echo "============================================"
echo "  Stage 3/5 — Shell environment"
echo "============================================"
echo ""

echo "[3.1] Installing zsh + oh-my-zsh + p10k..."
bash "$SCRIPT_DIR/setup/zsh_p10k_setup.sh"
ok "Zsh environment ready"
echo ""

echo "[3.2] Setting default shell..."
bash "$SCRIPT_DIR/config/default_shell_config.sh"
ok "Default shell set to zsh"
echo ""

# ============================================================
# Stage 4: Firewall
# ============================================================
echo "============================================"
echo "  Stage 4/5 — Firewall (22,80,443)"
echo "============================================"
echo ""

echo "[4.1] Configuring whitelist firewall..."
bash "$SCRIPT_DIR/config/firewall_config.sh"
ok "Firewall active (SSH/HTTP/HTTPS only)"
echo ""

# ============================================================
# Stage 5: Cleanup
# ============================================================
echo "============================================"
echo "  Stage 5/5 — Cleanup"
# shellcheck source=lib/apt_lib.sh
source "$SCRIPT_DIR/lib/apt_lib.sh"
echo "[5.1] Removing unused packages..."
apt_cleanup
ok "Unused packages removed"
echo ""

echo "============================================"
echo "  Bootstrap — Complete!"
echo "============================================"
echo ""
echo "  Runtimes:"
echo "    Docker   : $(docker --version 2>/dev/null || echo '-')"
echo "    Node.js  : $(node --version 2>/dev/null || echo '-')"
echo "    npm      : $(npm --version 2>/dev/null || echo '-')"
echo ""
echo "  Shell:"
echo "    Zsh      : $(zsh --version 2>/dev/null | head -1 || echo '-')"
echo "    Theme    : powerlevel10k"
echo ""
echo "  Web:"
echo "    Nginx    : $(nginx -v 2>&1 || echo '-')"
echo ""
echo "  Firewall : whitelist mode (SSH/HTTP/HTTPS)"
echo "  SSH      : key-only"
echo ""
echo "  Next steps:"
echo "    1. Log out and back in for zsh"
echo "    2. For K8s tools → package/kubectl_install.sh etc."
echo "    3. For domain/SSL → config/nginx_config.sh"
echo ""
echo "  Log: $LOG_FILE"
echo ""
