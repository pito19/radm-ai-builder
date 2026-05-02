#!/bin/bash
WATCHDOG_DEV="/dev/watchdog"
HEALTH_CHECK_INTERVAL=30
MAX_FAILURES=3
fail_count=0

while true; do
    [ -e "$WATCHDOG_DEV" ] && echo "1" > "$WATCHDOG_DEV" 2>/dev/null
    
    if command -v radm-health.sh >/dev/null 2>&1; then
        health=$(radm-health.sh --check 2>/dev/null | jq -r '.status' 2>/dev/null || echo "2")
        
        if [ "$health" -eq 0 ]; then
            fail_count=0
        elif [ "$health" -eq 1 ]; then
            fail_count=$((fail_count + 1))
        else
            fail_count=$((fail_count + 2))
        fi
        
        if [ $fail_count -ge $MAX_FAILURES ]; then
            logger -t radm-watchdog "Redemarrage systeme"
            echo "V" > "$WATCHDOG_DEV" 2>/dev/null
            reboot
        fi
    fi
    sleep $HEALTH_CHECK_INTERVAL
done