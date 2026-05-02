#!/bin/bash
set -euo pipefail
ALERT=false
[ "${1:-}" = "--alert" ] && ALERT=true

check_nvme() {
    local device="$1"
    if [ ! -e "$device" ]; then return 1; fi
    if ! command -v nvme >/dev/null 2>&1; then return 1; fi
    
    SMART=$(nvme smart-log "$device" 2>/dev/null)
    [ -z "$SMART" ] && return 1
    
    TEMP=$(echo "$SMART" | grep temperature | awk '{print $3}')
    CRIT_WARN=$(echo "$SMART" | grep critical_warning | awk '{print $3}')
    PERCENT_USED=$(echo "$SMART" | grep percentage_used | awk '{print $3}')
    MEDIA_ERRORS=$(echo "$SMART" | grep media_errors | awk '{print $3}')
    
    STATUS="OK"
    ISSUES=""
    
    if [ "${CRIT_WARN:-0}" -ne 0 ]; then
        STATUS="CRITICAL"
        ISSUES="$ISSUES critical_warning=$CRIT_WARN"
        [ "$ALERT" = true ] && logger -t radm-nvme "CRITICAL: $device - critical_warning=$CRIT_WARN"
    elif [ "${TEMP:-0}" -gt 70 ]; then
        STATUS="HIGH TEMP"
        ISSUES="$ISSUES temperature=${TEMP}C"
        [ "$ALERT" = true ] && logger -t radm-nvme "WARNING: $device - temperature=${TEMP}C"
    elif [ "${PERCENT_USED%\%}" -gt 90 ] 2>/dev/null; then
        STATUS="WEAR"
        ISSUES="$ISSUES wear=${PERCENT_USED}"
        [ "$ALERT" = true ] && logger -t radm-nvme "WARNING: $device - wear=${PERCENT_USED}"
    fi
    
    if [ "${MEDIA_ERRORS:-0}" -gt 0 ]; then
        ISSUES="$ISSUES media_errors=$MEDIA_ERRORS"
        [ "$ALERT" = true ] && logger -t radm-nvme "ERROR: $device - media_errors=$MEDIA_ERRORS"
    fi
    
    echo "$device: $STATUS | Temp: ${TEMP:-N/A}C | Wear: ${PERCENT_USED:-N/A} | Errors: ${MEDIA_ERRORS:-0}"
    [ -n "$ISSUES" ] && echo "   WARNING $ISSUES"
    return 0
}

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RADM AI v3.0 - NVMe Health Check                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

if ! command -v nvme >/dev/null 2>&1; then
    echo "nvme-cli not installed. Run: apt install -y nvme-cli"
    exit 1
fi

FOUND=false
for dev in /dev/nvme[0-9]*; do
    if [ -e "$dev" ]; then
        check_nvme "$dev"
        FOUND=true
    fi
done

if [ "$FOUND" = false ]; then
    echo "Aucun peripherique NVMe trouve"
fi
echo ""