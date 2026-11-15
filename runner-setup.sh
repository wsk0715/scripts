#!/usr/bin/env bash
# ===================================================
# GitHub Actions runner: 전용 계정 + rootless docker
#
# 전용 계정(ci)을 만들고 그 계정의 rootless docker로
# 러너를 옮기기 위한 설정 스크립트다.
#
# 사용법:
#   ./runner-setup.sh --check     필요 패키지·계정·설정 점검 (읽기 전용, 기본 동작)
#   sudo ./runner-setup.sh --apply  빠진 패키지와 계정·rootless docker 설정 (root)
#   ./runner-setup.sh --verify    설정 결과 확인 (읽기 전용)
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

report_unknown() {
    printf '%-8s %s\n' "unknown" "$1"
}

usage() {
    cat <<'EOF'
사용법: runner-setup.sh [--check|--apply|--verify]

  --check   필요 패키지, 계정, rootless docker 전제 조건을 읽기 전용으로 점검한다. (기본 동작)
  --apply   root로 실행한다. 빠진 패키지와 ci 계정, rootless docker를 멱등하게 설정한다.
  --verify  설정 결과를 읽기 전용으로 확인한다.

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
user_session_reachable() {
    [ "$(id -u)" -eq 0 ] || return 1
    user_exists || return 1
    [ -S "/run/user/$(id -u "$RUNNER_USER")/bus" ] || return 1
}

user_systemctl() {
    runuser -u "$RUNNER_USER" -- env \
        XDG_RUNTIME_DIR="/run/user/$(id -u "$RUNNER_USER")" \
        HOME="$RUNNER_HOME" \
        systemctl --user "$@"
}

is_bus_error() {
    case "$1" in
        *"Failed to connect to bus"*|*"No such file or directory"*|*"Connection refused"*) return 0 ;;
        *) return 1 ;;
    esac
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

    local package group
    for package in "${CHECK_PACKAGES[@]}"; do
        if package_installed "$package"; then
            report_ok "패키지 $package"
        else
            report_missing "패키지 $package"
        fi
    done

    if user_exists; then
        report_ok "계정 $RUNNER_USER"
        for group in sudo docker; do
            if user_in_group "$group"; then
                report_ok "$RUNNER_USER $group 그룹"
            else
                report_missing "$RUNNER_USER $group 그룹"
            fi
        done
    else
        report_missing "계정 $RUNNER_USER"
        report_missing "$RUNNER_USER sudo 그룹"
        report_missing "$RUNNER_USER docker 그룹"
    fi

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
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "root 권한이 필요합니다. sudo ./runner-setup.sh --apply 로 다시 실행하세요." >&2
        exit 1
    fi
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
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${REQUIRED_PACKAGES[@]}"
    echo "  -> 패키지 설치 완료"
}

apply_user() {
    if user_exists; then
        echo "  -> 계정 $RUNNER_USER 이미 존재 (변경 없음)"
    else
        useradd --create-home --shell /bin/bash "$RUNNER_USER"
        echo "  -> 계정 $RUNNER_USER 생성"
    fi
}

apply_subids() {
    if subid_has_user /etc/subuid; then
        echo "  -> /etc/subuid $RUNNER_USER 항목 있음 (변경 없음)"
    else
        usermod --add-subuids 100000-165535 "$RUNNER_USER"
        echo "  -> /etc/subuid $RUNNER_USER 항목 추가"
    fi

    if subid_has_user /etc/subgid; then
        echo "  -> /etc/subgid $RUNNER_USER 항목 있음 (변경 없음)"
    else
        usermod --add-subgids 100000-165535 "$RUNNER_USER"
        echo "  -> /etc/subgid $RUNNER_USER 항목 추가"
    fi
}

apply_linger() {
    if linger_enabled; then
        echo "  -> linger $RUNNER_USER 이미 켜짐 (변경 없음)"
        return 0
    fi
    loginctl enable-linger "$RUNNER_USER"
    echo "  -> linger $RUNNER_USER 켜짐"
}

apply_rootless_docker() {
    if ! runuser -u "$RUNNER_USER" -- env \
        XDG_RUNTIME_DIR="/run/user/$(id -u "$RUNNER_USER")" \
        HOME="$RUNNER_HOME" \
        PATH=/usr/bin:/bin:/usr/sbin:/sbin \
        dockerd-rootless-setuptool.sh install; then
        echo "" >&2
        echo "rootless docker 설치에 실패했습니다." >&2
        echo "$RUNNER_USER 사용자로 로그인해 다음 명령을 직접 실행하세요." >&2
        echo "  XDG_RUNTIME_DIR=/run/user/$(id -u "$RUNNER_USER") dockerd-rootless-setuptool.sh install" >&2
        exit 1
    fi
    echo "  -> rootless docker 설치 완료"
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
    require_root

    echo "============================================"
    echo "  GitHub Actions runner: apply"
    echo "============================================"
    echo ""
    echo "  실행할 작업:"
    echo "    1. 빠진 패키지 설치: ${REQUIRED_PACKAGES[*]}"
    echo "    2. 계정 $RUNNER_USER 생성 (없을 때만)"
    echo "    3. /etc/subuid, /etc/subgid 의 $RUNNER_USER 범위 추가 (없을 때만)"
    echo "    4. linger $RUNNER_USER 켜기"
    echo "    5. $RUNNER_USER 사용자의 rootless docker 설치"
    echo "    6. 러너 등록 명령 출력 (등록은 하지 않음)"
    echo ""

    echo "[1/6] 패키지 설치..."
    apply_packages
    echo ""

    echo "[2/6] 계정 준비..."
    apply_user
    echo ""

    echo "[3/6] subuid/subgid 설정..."
    apply_subids
    echo ""

    echo "[4/6] linger 설정..."
    apply_linger
    echo ""

    echo "[5/6] rootless docker 설치..."
    apply_rootless_docker
    echo ""

    echo "[6/6] 러너 등록 안내..."
    print_runner_registration
}

# ------------------------------------------------------------
# --verify
# ------------------------------------------------------------
verify_groups_removed() {
    if ! user_exists; then
        report_missing "계정 $RUNNER_USER 없음"
        return 0
    fi
    if user_in_group sudo || user_in_group docker; then
        report_missing "$RUNNER_USER 의 sudo·docker 그룹 소속 없음"
    else
        report_ok "$RUNNER_USER 의 sudo·docker 그룹 소속 없음"
    fi
}

verify_linger() {
    if linger_enabled; then
        report_ok "linger $RUNNER_USER"
    else
        report_missing "linger $RUNNER_USER"
    fi
}

verify_rootless_docker() {
    if ! user_session_reachable; then
        report_unknown "rootless docker 유닛 active (사용자 세션에 접근할 수 없음)"
        return 0
    fi

    local output
    if output=$(user_systemctl is-active docker 2>&1); then
        report_ok "rootless docker 유닛 active"
        return 0
    fi

    if is_bus_error "$output"; then
        report_unknown "rootless docker 유닛 active (사용자 세션에 접근할 수 없음)"
    else
        report_missing "rootless docker 유닛 active ($output)"
    fi
}

verify_runner_service() {
    if ! user_session_reachable; then
        report_unknown "러너 서비스 active (사용자 세션에 접근할 수 없음)"
        return 0
    fi

    local output
    if output=$(user_systemctl list-units --type=service --state=active --no-legend 'actions.runner.*' 2>&1) && [ -n "$output" ]; then
        report_ok "러너 서비스 active"
        return 0
    fi

    if is_bus_error "$output"; then
        report_unknown "러너 서비스 active (사용자 세션에 접근할 수 없음)"
    else
        report_missing "러너 서비스 active"
    fi
}

run_verify() {
    echo "============================================"
    echo "  GitHub Actions runner: verify"
    echo "============================================"
    echo ""

    verify_groups_removed
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

COMMAND="${1:---check}"

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
