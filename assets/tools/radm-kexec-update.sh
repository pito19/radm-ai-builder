#!/bin/bash
set -euo pipefail

KERNEL_IMAGE="${1:-}"
INITRD="${2:-}"

if [ -z "$KERNEL_IMAGE" ] || [ -z "$INITRD" ]; then
    echo "Usage: $0 <vmlinuz> <initrd.img>"
    exit 1
fi

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "Kernel non trouve: $KERNEL_IMAGE"
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "Initrd non trouve: $INITRD"
    exit 1
fi

echo "=== RADM AI v3.0 - Kernel Update (kexec) ==="
echo ""
echo "Kernel actuel: $(uname -r)"
echo "Nouveau kernel: $(basename "$KERNEL_IMAGE")"

if ! command -v kexec >/dev/null 2>&1; then
    apt install -y kexec-tools
fi

echo -n "Chargement du nouveau kernel... "
kexec -l "$KERNEL_IMAGE" --initrd="$INITRD" --reuse-cmdline
echo "OK"

echo ""
read -p "Redemarrer sur le nouveau kernel ? (o/N) : " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    systemctl kexec
fi