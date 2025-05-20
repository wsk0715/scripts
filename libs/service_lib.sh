#!/bin/bash

# ------------------------------------------------------------
# Linux 서비스 관리 모듈
# ------------------------------------------------------------

# 서비스 활성화 (enable)
# example: systemctl_service_enable <서비스명>
systemctl_service_enable() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        echo "❌ 서비스 이름을 지정해주세요"
        return 1
    fi
    
    echo "🔄 서비스 활성화 중: $service_name"
    sudo systemctl enable "$service_name"
    echo "✅ 서비스 활성화 완료: $service_name"
}

# 서비스 즉시 시작 (start)
# example: systemctl_service_start <서비스명>
systemctl_service_start() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        echo "❌ 서비스 이름을 지정해주세요"
        return 1
    fi
    
    echo "▶️ 서비스 시작 중: $service_name"
    sudo systemctl start "$service_name"
    echo "✅ 서비스 시작 완료: $service_name"
}

# 서비스 재시작 (restart)
# example: systemctl_service_restart <서비스명>
systemctl_service_restart() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        echo "❌ 서비스 이름을 지정해주세요"
        return 1
    fi
    
    echo "🔄 서비스 재시작 중: $service_name"
    sudo systemctl restart "$service_name"
    echo "✅ 서비스 재시작 완료: $service_name"
}

# 서비스 중지 (stop)
# example: systemctl_service_stop <서비스명>
systemctl_service_stop() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        echo "❌ 서비스 이름을 지정해주세요"
        return 1
    fi
    
    echo "⏹️ 서비스 중지 중: $service_name"
    sudo systemctl stop "$service_name"
    echo "✅ 서비스 중지 완료: $service_name"
}

# 서비스 상태 확인
# example: systemctl_service_status <서비스명>
systemctl_service_status() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        echo "❌ 서비스 이름을 지정해주세요"
        return 1
    fi
    
    echo "📊 서비스 상태 확인: $service_name"
    sudo systemctl status "$service_name" --no-pager
}

# 서비스 활성화 & 즉시 시작
# example: systemctl_service_enable_and_start <서비스명>
systemctl_service_enable_and_start() {
    local service_name="$1"

    if [ -z "$service_name" ]; then
        echo "❌ 서비스 이름을 지정해주세요"
        return 1
    fi
    
    systemctl_service_enable "$service_name"
    systemctl_service_start "$service_name"
}
