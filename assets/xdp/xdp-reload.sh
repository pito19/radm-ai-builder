#!/bin/bash
NIC="${1:-eth1}" MODE="${2:-native}"
if [ "$MODE" = "native" ]; then
    ip link set dev $NIC xdp obj /opt/radm/xdp/radm_xdp.o 2>/dev/null
elif [ "$MODE" = "generic" ]; then
    ip link set dev $NIC xdpgeneric obj /opt/radm/xdp/radm_xdp.o 2>/dev/null
fi