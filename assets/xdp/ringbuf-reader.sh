#!/bin/bash
while true; do
    bpftool map event pipe name events 2>/dev/null | while read event; do
        logger -t radm-xdp "DROP event: $event"
    done
    sleep 1
done