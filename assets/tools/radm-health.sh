#!/bin/bash
MODE="${1:-check}" PORT="${2:-9100}"

check_health() {
    local status=0 message=""
    if [ -f /opt/radm/configs/xdp-mode.conf ]; then
        XDP_MODE=$(cat /opt/radm/configs/xdp-mode.conf)
        [ "$XDP_MODE" = "none" ] && status=2 message="$message XDP down"
    fi
    NIC=$(cat /opt/radm/configs/capture_iface.conf 2>/dev/null)
    if [ -n "$NIC" ]; then
        DROPS=$(ethtool -S "$NIC" 2>/dev/null | grep -i drop | awk '{sum+=$2} END {print sum}')
        [ "${DROPS:-0}" -gt 1000 ] && [ $status -lt 1 ] && status=1 message="$message drops=$DROPS"
    fi
    echo "{\"status\": $status, \"message\": \"$message\", \"timestamp\": $(date +%s)}"
    return $status
}

if [ "$MODE" = "exporter" ]; then
    while true; do
        METRICS="# HELP radm_health_status Health status (0=OK,1=WARN,2=CRIT)\n# TYPE radm_health_status gauge\nradm_health_status $(check_health | jq -r '.status' 2>/dev/null || echo 2)"
        echo -e "HTTP/1.1 200 OK\n\n$METRICS" | nc -l -p $PORT -q 1
    done
else
    check_health
fi