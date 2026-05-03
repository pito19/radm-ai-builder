#!/bin/bash
# =============================================================================
# RADM XDP Secure Loader - Avec verification d'integrite
# =============================================================================

set -euo pipefail

XDP_PROG="/opt/radm/xdp/radm_xdp.o"
XDP_HASH="/opt/radm/xdp/radm_xdp.sha256"
XDP_IFACE=$(cat /opt/radm/configs/capture_iface.conf 2>/dev/null || echo "")

if [ -z "$XDP_IFACE" ]; then
    echo "[XDP] ERROR: No capture interface found"
    exit 1
fi

echo "[XDP] Verification d'integrite du programme BPF"

if [ ! -f "$XDP_HASH" ]; then
    echo "[XDP] ERROR: Hash file not found"
    exit 1
fi

EXPECTED_HASH=$(cat "$XDP_HASH" | awk '{print $1}')
ACTUAL_HASH=$(sha256sum "$XDP_PROG" | awk '{print $1}')

if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then
    echo "[XDP] ERREUR: Integrity check failed"
    echo "   Expected: $EXPECTED_HASH"
    echo "   Actual:   $ACTUAL_HASH"
    exit 1
fi

echo "[XDP] Integrity check passed"

# Verification que l'interface supporte XDP
if ! ip link show "$XDP_IFACE" 2>/dev/null | grep -q "xdp"; then
    echo "[XDP] Loading program on $XDP_IFACE"
    
    if bpftool prog load "$XDP_PROG" /sys/fs/bpf/radm_xdp 2>/dev/null; then
        PROG_ID=$(bpftool prog show | grep radm_xdp | awk '{print $1}')
        bpftool net attach xdp id "$PROG_ID" dev "$XDP_IFACE"
        echo "[XDP] Successfully loaded"
    else
        echo "[XDP] ERROR: Failed to load XDP program"
        exit 1
    fi
else
    echo "[XDP] Already loaded on $XDP_IFACE"
fi