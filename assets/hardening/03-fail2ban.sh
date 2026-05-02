#!/bin/bash
echo "[FAIL2BAN] Configuration..."
cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
banaction = ufw

[sshd]
enabled = true
maxretry = 3
bantime = 3600

[recidive]
enabled = true
maxretry = 5
bantime = 86400
FAIL2BAN
systemctl enable --now fail2ban