#!/bin/bash
set -euo pipefail
BACKUP_DIR="/backup/radm_$(date +%Y%m%d_%H%M%S)"
INCLUDE_DATA=false
[ "${1:-}" = "--include-data" ] && INCLUDE_DATA=true

echo "=== RADM AI v3.0 - Backup ==="
mkdir -p "$BACKUP_DIR"

cp -a /etc/radm "$BACKUP_DIR/" 2>/dev/null || true
cp -a /opt/radm/runtime "$BACKUP_DIR/" 2>/dev/null || true
cp -a /opt/radm/configs "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/ssh/ssh_host_* "$BACKUP_DIR/" 2>/dev/null || true

if [ "$INCLUDE_DATA" = true ]; then
    tar -czf "$BACKUP_DIR/data.tar.gz" /data/ 2>/dev/null || true
fi

tar -czf "$BACKUP_DIR.tar.gz" -C /backup "$(basename "$BACKUP_DIR")" 2>/dev/null
rm -rf "$BACKUP_DIR"

echo "Backup cree : $BACKUP_DIR.tar.gz"