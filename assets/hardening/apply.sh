#!/bin/bash
set -e
echo "[HARDENING] Application des configurations..."
sysctl -p /etc/sysctl.d/99-radm-perf.conf 2>/dev/null || true
sysctl -p /etc/sysctl.d/99-radm-security.conf 2>/dev/null || true
echo "radm soft nofile 1048576" >> /etc/security/limits.conf
echo "radm hard nofile 1048576" >> /etc/security/limits.conf
depmod -a
update-initramfs -u
systemctl restart systemd-journald
systemctl enable --now auditd
systemctl enable --now apparmor
systemctl enable --now fail2ban
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "[HARDENING] Termine"