#!/bin/bash
echo "[AUDIT] Configuration auditd..."
cat > /etc/audit/rules.d/99-radm-security.rules << 'AUDIT'
-D
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k ssh
-w /etc/ssh/sshd_config.d/ -p wa -k ssh
-w /etc/apparmor/ -p wa -k apparmor
-w /etc/audit/ -p wa -k audit
-w /etc/audit/rules.d/ -p wa -k audit
-w /etc/cron.d/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /etc/hosts -p wa -k network
-w /etc/hosts.allow -p wa -k network
-w /etc/hosts.deny -p wa -k network
-w /etc/network/ -p wa -k network
-w /etc/security/ -p wa -k security
-w /etc/radm/ -p wa -k radm
-w /usr/bin/ -p x -k binaries
-w /usr/sbin/ -p x -k binaries
-w /bin/ -p x -k binaries
-w /sbin/ -p x -k binaries
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -S execve -C uid!=euid -F euid=0 -k priv_esc
-a always,exit -S execve -C gid!=egid -F egid=0 -k priv_esc
-a always,exit -F arch=b64 -S capset -k capabilities
-w /opt/radm/tools/radm-backup.sh -p x -k radm_tools
-w /opt/radm/tools/radm-restore.sh -p x -k radm_tools
-w /opt/radm/tools/radm-kpi-collect.sh -p x -k radm_tools
-w /opt/radm/tools/radm-nvme-check.sh -p x -k radm_tools
-w /opt/radm/tools/radm-snmp-setup.sh -p x -k radm_tools
-w /opt/radm/tools/radm-kexec-update.sh -p x -k radm_tools
-b 8192
-e 2
AUDIT
augenrules --load
systemctl enable --now auditd
if lsmod | grep -q nf_conntrack; then
    modprobe -r nf_conntrack 2>/dev/null || true
fi
echo "blacklist nf_conntrack" >> /etc/modprobe.d/blacklist-radm.conf
echo "[AUDIT] Auditd configure"