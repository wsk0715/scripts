#!/bin/bash

# ------------------------------------------------------------
# 네트워크 관리 모듈
# ------------------------------------------------------------

# TCP 포트 허용
# example: network_iptables_allow_tcp <포트1> <포트2> ...
network_iptables_allow_tcp() {
    local ports=("$@")

    if [ -z "$ports" ]; then
        echo "❌ 허용할 포트를 지정해주세요"
        return 1
    fi

    local IFS=", "
    echo "🔓 TCP 포트 $ports 허용 중..."
    for port in "${ports[@]}"; do
        sudo iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT
    done
    echo "✅ TCP 포트 허용 완료"
}

# iptables 규칙 저장(영구 적용)
# example: network_iptables_save_rules
network_iptables_save_rules() {
    echo "💾 iptables 규칙 저장 중..."
    sudo netfilter-persistent save
    sudo netfilter-persistent reload
    echo "✅ iptables 규칙 저장 완료"
}
