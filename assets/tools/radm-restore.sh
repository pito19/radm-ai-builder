#!/bin/bash
set -euo pipefail
BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup.tar.gz>"
    exit 1
fi

echo "=== RADM AI v3.0 - Restore ==="
BACKUP_DIR="/tmp/radm_restore_$$"
mkdir -p "$BACKUP_DIR"

tar -xzf "$BACKUP_FILE" -C "$BACKUP_DIR" 2>/dev/null
RESTORE_DIR=$(find "$BACKUP_DIR" -name "radm_*" -type d | head -1)

if [ -d "$RESTORE_DIR/etc/radm" ]; then
    cp -a "$RESTORE_DIR/etc/radm"/* /etc/radm/ 2>/dev/null || true
fi
if [ -d "$RESTORE_DIR/opt/radm/runtime" ]; then
    cp -a "$RESTORE_DIR/opt/radm/runtime"/* /opt/radm/runtime/ 2>/dev/null || true
fi
if [ -d "$RESTORE_DIR/opt/radm/configs" ]; then
    cp -a "$RESTORE_DIR/opt/radm/configs"/* /opt/radm/configs/ 2>/dev/null || true
fi
if [ -f "$RESTORE_DIR/data.tar.gz" ]; then
    tar -xzf "$RESTORE_DIR/data.tar.gz" -C / 2>/dev/null || true
fi

rm -rf "$BACKUP_DIR"
systemctl restart docker radm-runtime 2>/dev/null || true

echo "Restauration terminee"