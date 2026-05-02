#!/bin/bash
echo "[LOGGING] Configuration journald..."
systemctl stop rsyslog 2>/dev/null || true
systemctl disable rsyslog 2>/dev/null || true
mkdir -p /var/log/journal
cat > /etc/systemd/journald.conf << 'JOURNALD'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=10G
SystemMaxFileSize=100M
MaxRetentionSec=3month
ForwardToSyslog=no
JOURNALD
systemctl restart systemd-journald