#!/bin/bash
MODE="${1:-text}"

if [ "$MODE" = "--watch" ]; then
    while true; do clear; /opt/radm/tools/radm-kpi-collect.sh --once; sleep 5; done
elif [ "$MODE" = "--json" ]; then
    VERSION=$(cat /etc/radm/version 2>/dev/null | head -1 | cut -d' ' -f5- | xargs || echo "N/A")
    MODE_PERF=$(cat /opt/radm/configs/current-mode.conf 2>/dev/null || echo "N/A")
    XDP_MODE=$(cat /opt/radm/configs/xdp-mode.conf 2>/dev/null || echo "unknown")
    CAPTURE_IF=$(cat /opt/radm/configs/capture_iface.conf 2>/dev/null || echo "")
    if [ -n "$CAPTURE_IF" ]; then
        SPEED=$(ethtool "$CAPTURE_IF" 2>/dev/null | grep Speed | awk '{print $2}' || echo "?")
        DROPS=$(ethtool -S "$CAPTURE_IF" 2/dev/null | grep -i drop | awk '{sum+=$2} END {print sum}' || echo "0")
    else
        SPEED="?"; DROPS="0"
    fi
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' 2>/dev/null || echo "0")
    MEM_PERCENT=$(free | awk '/^Mem:/{printf "%.0f", $3/$2 * 100}' 2>/dev/null || echo "0")
    CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l || echo "0")
    HEALTH=$(/opt/radm/tools/radm-health.sh --check 2>/dev/null | jq -r '.status' 2>/dev/null || echo "2")
    echo "{\"timestamp\":$(date +%s),\"version\":\"$VERSION\",\"mode\":\"$MODE_PERF\",\"xdp_mode\":\"$XDP_MODE\",\"nic_capture\":\"$CAPTURE_IF\",\"nic_speed\":\"$SPEED\",\"drops\":$DROPS,\"cpu_usage\":$CPU_USAGE,\"mem_used_percent\":$MEM_PERCENT,\"containers\":$CONTAINERS,\"health_status\":$HEALTH}"
else
    VERSION=$(cat /etc/radm/version 2>/dev/null | head -1 | cut -d' ' -f5- | xargs || echo "N/A")
    MODE_PERF=$(cat /opt/radm/configs/current-mode.conf 2>/dev/null || echo "N/A")
    XDP_MODE=$(cat /opt/radm/configs/xdp-mode.conf 2>/dev/null || echo "unknown")
    CAPTURE_IF=$(cat /opt/radm/configs/capture_iface.conf 2>/dev/null || echo "")
    if [ -n "$CAPTURE_IF" ]; then
        SPEED=$(ethtool "$CAPTURE_IF" 2>/dev/null | grep Speed | awk '{print $2}' || echo "?")
        DROPS=$(ethtool -S "$CAPTURE_IF" 2>/dev/null | grep -i drop | awk '{sum+=$2} END {print sum}' || echo "0")
    else
        SPEED="?"; DROPS="0"
    fi
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' 2>/dev/null || echo "0")
    MEM_USED=$(free -h | awk '/^Mem:/{print $3}' 2>/dev/null || echo "0")
    MEM_TOTAL=$(free -h | awk '/^Mem:/{print $2}' 2>/dev/null || echo "0")
    CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l || echo "0")
    HEALTH=$(/opt/radm/tools/radm-health.sh --check 2>/dev/null | jq -r '.status' 2>/dev/null || echo "2")
    HEALTH_STR=$([ "$HEALTH" = "0" ] && echo "OK" || ([ "$HEALTH" = "1" ] && echo "WARN" || echo "CRIT"))
    
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    RADM AI v3.0 - KPI Collection                             ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "VERSION: $VERSION"
    echo "MODE: $MODE_PERF"
    echo "XDP: $XDP_MODE"
    echo "NIC: $CAPTURE_IF ($SPEED)"
    echo "DROPS: ${DROPS:-0}"
    echo "CPU: ${CPU_USAGE}%"
    echo "RAM: $MEM_USED / $MEM_TOTAL"
    echo "CONTENEURS: $CONTAINERS"
    echo "HEALTH: $HEALTH_STR"
    echo ""
fi