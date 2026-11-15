#!/usr/bin/env bash
# ===================================================
# GitHub Actions runner: 전용 계정 + rootless docker
#
# 전용 계정(ci)을 만들고 그 계정의 rootless docker로
# 러너를 옮기기 위한 설정 스크립트다.
#
# 사용법:
#   ./runner-setup.sh --check       필요 패키지·계정·설정 점검 (읽기 전용)
#   sudo ./runner-setup.sh --apply  빠진 패키지와 계정·rootless docker 설정 (root)
#   sudo ./runner-setup.sh --verify 설정 결과 확인 (읽기 전용, root 필요)
#
# 인자 없이 실행하면 이 사용법만 출력하고 종료 코드 2로 끝난다.
# 러너 등록과 토큰 입력은 하지 않는다. --apply 끝에 등록 명령만 출력한다.
# 기존 러너, ubuntu 계정, sudoers, k3s, iptables는 건드리지 않는다.
# ===================================================
set -euo pipefail

RUNNER_USER="ci"
RUNNER_HOME="/home/ci"
REQUIRED_PACKAGES=(uidmap slirp4netns fuse-overlayfs)
CHECK_PACKAGES=(slirp4netns fuse-overlayfs)
MISSING_FOUND=0

# ------------------------------------------------------------
# 출력
# ------------------------------------------------------------
report_ok() {
    printf '%-8s %s\n' "ok" "$1"
}

report_missing() {
    printf '%-8s %s\n' "missing" "$1"
    MISSING_FOUND=1
}

usage() {
    cat <<'EOF'
사용법: runner-setup.sh [--check|--apply|--verify]

  --check   필요 패키지, 계정, rootless docker 전제 조건을 읽기 전용으로 점검한다.
  --apply   root로 실행한다. 빠진 패키지와 ci 계정, rootless docker를 멱등하게 설정한다.
  --verify  root로 실행한다. 설정 결과와 러너 유닛을 읽기 전용으로 확인한다.

인자 없이 실행하면 이 사용법을 출력하고 종료 코드 2로 끝난다.
EOF
}

# ------------------------------------------------------------
# 점검용 판정 함수 (아무것도 바꾸지 않는다)
# ------------------------------------------------------------
user_exists() {
    id -u "$RUNNER_USER" >/dev/null 2>&1
}

user_in_group() {
    local group="$1"
    id -Gn "$RUNNER_USER" 2>/dev/null | tr ' ' '\n' | grep -qx "$group"
}

package_installed() {
    local package="$1"
    command -v dpkg-query >/dev/null 2>&1 || return 1
    [ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" = "install ok installed" ]
}

subid_has_user() {
    local file="$1"
    [ -r "$file" ] || return 1
    awk -F: -v u="$RUNNER_USER" '$1 == u { found = 1 } END { exit(found ? 0 : 1) }' "$file"
}

linger_enabled() {
    user_exists || return 1
    loginctl show-user "$RUNNER_USER" -p Linger 2>/dev/null | grep -qx 'Linger=yes'
}

cgroup_v2() {
    [ -d /sys/fs/cgroup ] || return 1
    [ "$(stat -fc %T /sys/fs/cgroup 2>/dev/null || true)" = "cgroup2fs" ]
}

# ci 사용자의 systemd 사용자 인스턴스에 접근할 수 있는지 확인한다.
# --verify는 root로만 실행하므로 root 여부는 여기서 다시 보지 않는다.
user_session_reachable() {
    user_exists || return 1
    [ -S "/run/user/$(id -u "$RUNNER_USER")/bus" ] || return 1
}

user_systemctl() {
    runuser -u "$RUNNER_USER" -- env \
        XDG_RUNTIME_DIR="/run/user/$(id -u "$RUNNER_USER")" \
        HOME="$RUNNER_HOME" \
        systemctl --user "$@"
}

# 계약: ci는 존재하고, sudo·docker 그룹에 속하지 않아야 한다.
# --check와 --verify가 같은 사실을 반대로 판정하지 않도록 한 곳에 모은다.
report_account_groups() {
    local group
    if ! user_exists; then
        report_missing "계정 $RUNNER_USER 없음"
        report_missing "$RUNNER_USER sudo 그룹 소속 없음 (계정 없음)"
        report_missing "$RUNNER_USER docker 그룹 소속 없음 (계정 없음)"
        return 0
    fi
    report_ok "계정 $RUNNER_USER"
    for group in sudo docker; do
        if user_in_group "$group"; then
            report_missing "$RUNNER_USER $group 그룹 소속 없음"
        else
            report_ok "$RUNNER_USER $group 그룹 소속 없음"
        fi
    done
}

# ------------------------------------------------------------
# --check
# ------------------------------------------------------------
run_check() {
    if cgroup_v2; then
        report_ok "cgroup v2 (/sys/fs/cgroup)"
    else
        report_missing "cgroup v2 (/sys/fs/cgroup)"
    fi

    if command -v dockerd-rootless-setuptool.sh >/dev/null 2>&1; then
        report_ok "dockerd-rootless-setuptool.sh"
    else
        report_missing "dockerd-rootless-setuptool.sh"
    fi

    if command -v newuidmap >/dev/null 2>&1 && command -v newgidmap >/dev/null 2>&1; then
        report_ok "newuidmap, newgidmap (uidmap)"
    else
        report_missing "newuidmap, newgidmap (uidmap)"
    fi

    local package
    for package in "${CHECK_PACKAGES[@]}"; do
        if package_installed "$package"; then
            report_ok "패키지 $package"
        else
            report_missing "패키지 $package"
        fi
    done

    report_account_groups

    if subid_has_user /etc/subuid; then
        report_ok "/etc/subuid $RUNNER_USER 항목"
    else
        report_missing "/etc/subuid $RUNNER_USER 항목"
    fi

    if subid_has_user /etc/subgid; then
        report_ok "/etc/subgid $RUNNER_USER 항목"
    else
        report_missing "/etc/subgid $RUNNER_USER 항목"
    fi

    if linger_enabled; then
        report_ok "linger $RUNNER_USER"
    else
        report_missing "linger $RUNNER_USER"
    fi

    if [ "$MISSING_FOUND" -ne 0 ]; then
        return 3
    fi
    return 0
}

# ------------------------------------------------------------
# --apply
# ------------------------------------------------------------
# root가 필요한 서브커맨드는 실행 전에 확인하고, 아니면 안내 후 1로 멈춘다.
require_root() {
    local command="$1"
    local reason="$2"
    if [ "$(id -u)" -ne 0 ]; then
        echo "$reason" >&2
        echo "sudo ./runner-setup.sh $command 로 다시 실행하세요." >&2
        exit 1
    fi
}

# --apply 단계를 실행하고, 실패하면 무엇이 실패했는지와 다음에 할 일을 알린 뒤 멈춘다.
apply_step() {
    local label="$1"
    local next_action="$2"
    shift 2
    if "$@"; then
        return 0
    fi
    echo "" >&2
    echo "[실패] $label 단계가 실패해 설정을 멈췄습니다." >&2
    echo "다음에 할 일: $next_action" >&2
    exit 1
}

apply_packages() {
    local package
    local needed=0
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! package_installed "$package"; then
            needed=1
        fi
    done

    if [ "$needed" -eq 0 ]; then
        echo "  -> 설치된 패키지: ${REQUIRED_PACKAGES[*]} (변경 없음)"
        return 0
    fi

    echo "  -> 빠진 패키지 설치: ${REQUIRED_PACKAGES[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${REQUIRED_PACKAGES[@]}" || return 1
    echo "  -> 패키지 설치 완료"
}

apply_user() {
    if user_exists; then
        echo "  -> 계정 $RUNNER_USER 이미 존재 (변경 없음)"
    else
        useradd --create-home --shell /bin/bash "$RUNNER_USER" || return 1
        echo "  -> 계정 $RUNNER_USER 생성"
    fi
}

apply_subids() {
    if subid_has_user /etc/subuid; then
        echo "  -> /etc/subuid $RUNNER_USER 항목 있음 (변경 없음)"
    else
        usermod --add-subuids 100000-165535 "$RUNNER_USER" || return 1
        echo "  -> /etc/subuid $RUNNER_USER 항목 추가"
    fi

    if subid_has_user /etc/subgid; then
        echo "  -> /etc/subgid $RUNNER_USER 항목 있음 (변경 없음)"
    else
        usermod --add-subgids 100000-165535 "$RUNNER_USER" || return 1
        echo "  -> /etc/subgid $RUNNER_USER 항목 추가"
    fi
}

apply_linger() {
    if linger_enabled; then
        echo "  -> linger $RUNNER_USER 이미 켜짐 (변경 없음)"
        return 0
    fi
    loginctl enable-linger "$RUNNER_USER" || return 1
    echo "  -> linger $RUNNER_USER 켜짐"
}

user_instance_active() {
    systemctl is-active --quiet "user@$(id -u "$RUNNER_USER").service"
}

runtime_dir_ready() {
    [ -d "/run/user/$(id -u "$RUNNER_USER")" ]
}

# linger를 켠 직후에는 ci의 systemd 사용자 인스턴스가 아직 뜨지 않았을 수 있다.
# 인스턴스가 없으면 setuptool이 유닛을 설치하지 않고 끝나므로 먼저 보장한다.
ensure_user_systemd_instance() {
    local uid instance waited=0
    uid=$(id -u "$RUNNER_USER")
    instance="user@$uid.service"

    if user_instance_active; then
        echo "  -> $instance 이미 active (변경 없음)"
    else
        echo "  -> $instance 시작"
        if ! systemctl start "$instance"; then
            echo "[실패] $instance 를 시작하지 못했습니다." >&2
            return 1
        fi
        echo "  -> $instance 시작됨"
    fi

    while ! runtime_dir_ready && [ "$waited" -lt 20 ]; do
        sleep 0.5
        waited=$((waited + 1))
    done

    if ! runtime_dir_ready; then
        echo "[실패] $instance 는 active지만 /run/user/$uid 디렉터리가 10초 안에 생기지 않았습니다." >&2
        return 1
    fi
    echo "  -> /run/user/$uid 준비됨"
}

rootless_docker_active() {
    user_systemctl is-active --quiet docker.service
}

apply_rootless_docker() {
    runuser -u "$RUNNER_USER" -- env \
        XDG_RUNTIME_DIR="/run/user/$(id -u "$RUNNER_USER")" \
        HOME="$RUNNER_HOME" \
        PATH=/usr/bin:/bin:/usr/sbin:/sbin \
        dockerd-rootless-setuptool.sh install || return 1

    if ! rootless_docker_active; then
        echo "  -> rootless docker 데몬이 inactive, docker.service 시작 시도"
        user_systemctl start docker.service || true
    fi

    if ! rootless_docker_active; then
        echo "[실패] rootless docker 데몬(docker.service)이 active가 아닙니다." >&2
        echo "       setuptool이 유닛을 설치하지 못했을 수 있습니다." >&2
        return 1
    fi
    echo "  -> rootless docker 설치 완료 (docker.service active)"
}

print_runner_registration() {
    cat <<EOF

============================================
  러너 등록은 자동으로 하지 않습니다.
  $RUNNER_USER 사용자로 다음 명령을 실행하고 토큰은 직접 넣으세요.

  sudo -u $RUNNER_USER -H bash -lc 'mkdir -p ~/actions-runner && cd ~/actions-runner && curl -fsSL -o actions-runner.tar.gz <runner tarball 주소> && tar xzf actions-runner.tar.gz && ./config.sh --url <조직 URL> --token <토큰>'
============================================
EOF
}

run_apply() {
    require_root --apply "root 권한이 필요합니다."

    echo "============================================"
    echo "  GitHub Actions runner: apply"
    echo "============================================"
    echo ""
    echo "  실행할 작업:"
    echo "    1. 빠진 패키지 설치: ${REQUIRED_PACKAGES[*]}"
    echo "    2. 계정 $RUNNER_USER 생성 (없을 때만)"
    echo "    3. /etc/subuid, /etc/subgid 의 $RUNNER_USER 범위 추가 (없을 때만)"
    echo "    4. linger $RUNNER_USER 켜기"
    echo "    5. $RUNNER_USER 의 systemd 사용자 인스턴스 기동 확인"
    echo "    6. $RUNNER_USER 사용자의 rootless docker 설치 및 데몬 기동 확인"
    echo "    7. 러너 등록 명령 출력 (등록은 하지 않음)"
    echo ""

    echo "[1/7] 패키지 설치..."
    apply_step "패키지 설치" \
        "apt-get install -y --no-install-recommends ${REQUIRED_PACKAGES[*]} 를 직접 실행해 원인을 확인한 뒤 다시 실행하세요." \
        apply_packages
    echo ""

    echo "[2/6] 계정 준비..."
    apply_step "계정 생성" \
        "useradd --create-home --shell /bin/bash $RUNNER_USER 를 직접 실행해 원인을 확인한 뒤 다시 실행하세요." \
        apply_user
    echo ""

    echo "[3/6] subuid/subgid 설정..."
    apply_step "subuid/subgid 설정" \
        "usermod --add-subuids 100000-165535 $RUNNER_USER 와 usermod --add-subgids 100000-165535 $RUNNER_USER 를 직접 실행해 원인을 확인한 뒤 다시 실행하세요." \
        apply_subids
    echo ""

    echo "[4/6] linger 설정..."
    apply_step "linger 설정" \
        "loginctl enable-linger $RUNNER_USER 를 직접 실행해 원인을 확인한 뒤 다시 실행하세요." \
        apply_linger
    echo ""

    echo "[5/7] 사용자 systemd 인스턴스 확인..."
    apply_step "사용자 systemd 인스턴스 기동" \
        "systemctl status user@$(id -u "$RUNNER_USER").service 와 journalctl -u user@$(id -u "$RUNNER_USER").service 로 원인을 확인하고, /run/user/$(id -u "$RUNNER_USER") 가 생기는지 확인한 뒤 다시 실행하세요." \
        ensure_user_systemd_instance
    echo ""

    echo "[6/7] rootless docker 설치..."
    apply_step "rootless docker 설치" \
        "$RUNNER_USER 사용자로 로그인해 systemctl --user status docker.service 와 journalctl --user -u docker.service 로 원인을 확인하고, XDG_RUNTIME_DIR=/run/user/$(id -u "$RUNNER_USER") dockerd-rootless-setuptool.sh install 을 직접 실행한 뒤 다시 실행하세요." \
        apply_rootless_docker
    echo ""

    echo "[7/7] 러너 등록 안내..."
    print_runner_registration
}

# ------------------------------------------------------------
# --verify
# ------------------------------------------------------------
verify_linger() {
    if linger_enabled; then
        report_ok "linger $RUNNER_USER"
    else
        report_missing "linger $RUNNER_USER"
    fi
}

verify_rootless_docker() {
    if ! user_session_reachable; then
        report_missing "rootless docker 유닛 active (사용자 세션에 접근할 수 없음)"
        return 0
    fi

    local output
    if output=$(user_systemctl is-active docker 2>&1); then
        report_ok "rootless docker 유닛 active"
        return 0
    fi

    report_missing "rootless docker 유닛 active ($output)"
}

verify_runner_service() {
    if ! user_session_reachable; then
        report_missing "러너 서비스 active (사용자 세션에 접근할 수 없음)"
        return 0
    fi

    local output
    if output=$(user_systemctl list-units --type=service --state=active --no-legend 'actions.runner.*' 2>&1) && [ -n "$output" ]; then
        report_ok "러너 서비스 active"
        return 0
    fi

    report_missing "러너 서비스 active"
}

run_verify() {
    require_root --verify "root로 실행해야 유닛을 확인할 수 있습니다."

    echo "============================================"
    echo "  GitHub Actions runner: verify"
    echo "============================================"
    echo ""

    report_account_groups
    verify_linger
    verify_rootless_docker
    verify_runner_service

    if [ "$MISSING_FOUND" -ne 0 ]; then
        return 3
    fi
    return 0
}

# ------------------------------------------------------------
# 진입점
# ------------------------------------------------------------
if [ "$#" -eq 0 ]; then
    usage >&2
    exit 2
fi

COMMAND="$1"

case "$COMMAND" in
    --check)
        run_check || exit $?
        ;;
    --apply)
        run_apply
        ;;
    --verify)
        run_verify || exit $?
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
