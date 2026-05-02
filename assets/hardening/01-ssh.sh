#!/bin/bash
echo "[SSH] Configuration..."
mkdir -p /etc/ssh/sshd_config.d/
cat > /etc/ssh/sshd_config.d/99-radm.conf << 'SSH'
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 0
LoginGraceTime 30
Protocol 2
X11Forwarding no
DebianBanner no
SSH
systemctl restart sshd