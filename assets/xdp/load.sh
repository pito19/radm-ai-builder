#!/bin/bash
NIC=$(cat /opt/radm/configs/capture_iface.conf 2>/dev/null || ip route get 1 | awk '{print $5; exit}')
if [ -z "$NIC" ]; then echo "XDP: No capture NIC found"; exit 1; fi
clang -O2 -g -target bpf -c /opt/radm/xdp/radm_xdp.c -o /opt/radm/xdp/radm_xdp.o 2>/dev/null
if ip link set dev $NIC xdp obj /opt/radm/xdp/radm_xdp.o 2>/dev/null; then
    echo "native" > /opt/radm/configs/xdp-mode.conf
    echo "XDP: native loaded on $NIC"
elif ip link set dev $NIC xdpgeneric obj /opt/radm/xdp/radm_xdp.o 2>/dev/null; then
    echo "generic" > /opt/radm/configs/xdp-mode.conf
    echo "XDP: generic loaded on $NIC"
else
    echo "none" > /opt/radm/configs/xdp-mode.conf
    echo "XDP: not available"
fi