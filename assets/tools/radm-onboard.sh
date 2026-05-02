#!/bin/bash
ONBOARD_DONE="/etc/radm/onboarded"
[ -f "$ONBOARD_DONE" ] && { echo "Onboarding deja effectue"; exit 0; }

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RADM AI v3.0 - Configuration initiale                     ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"

read -p "Cle SSH publique (ou laisser vide) : " SSH_KEY
[ -n "$SSH_KEY" ] && { mkdir -p ~/.ssh; echo "$SSH_KEY" >> ~/.ssh/authorized_keys; echo "Cle SSH ajoutee"; }

read -p "Changer mot de passe radm ? (y/N) : " CHANGE_PASS
[ "$CHANGE_PASS" = "y" ] && passwd

read -p "IP fixe management (ex: 192.168.1.100/24) ou vide pour DHCP : " MGMT_IP
if [ -n "$MGMT_IP" ]; then
    cat > /etc/netplan/99-radm-mgmt.yaml << NETPLAN
network:
  version: 2
  renderer: networkd
  ethernets:
    $(ip route get 1 | awk '{print $5; exit}'):
      dhcp4: no
      addresses: [$MGMT_IP]
      gateway4: $(echo $MGMT_IP | cut -d. -f1-3).1
      nameservers: {addresses: [8.8.8.8, 1.1.1.1]}
NETPLAN
    netplan apply
fi

read -p "Serveur syslog externe (ex: 192.168.1.200:514) : " SYSLOG_SERVER
[ -n "$SYSLOG_SERVER" ] && /opt/radm/tools/radm-syslog-forward.sh "$SYSLOG_SERVER"

aideinit 2>/dev/null && mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null
rm -f /etc/ssh/ssh_host_* && dpkg-reconfigure openssh-server 2>/dev/null

touch "$ONBOARD_DONE"
echo "Onboarding termine"