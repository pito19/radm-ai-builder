#!/bin/bash
set -euo pipefail

SNMP_USER="${1:-radm}"
AUTH_PASS="${2:-}"
PRIV_PASS="${3:-}"

if [ -z "$AUTH_PASS" ] || [ -z "$PRIV_PASS" ]; then
    echo "Usage: $0 <username> <auth_password> <priv_password>"
    echo ""
    echo "Exemple: radm-snmp-setup.sh radm MyAuthPass123 MyPrivPass456"
    echo ""
    echo "SNMPv2c est desactive - SNMPv3 avec authentification requis"
    exit 1
fi

echo "[SNMPv3] Configuration conforme ANSSI..."

if [ ${#AUTH_PASS} -lt 12 ] || [ ${#PRIV_PASS} -lt 12 ]; then
    echo "Les mots de passe doivent faire au moins 12 caracteres"
    exit 1
fi

apt install -y snmpd snmp
cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak

cat > /etc/snmp/snmpd.conf << EOF
agentAddress udp:161
disableV1V2c yes
createUser $SNMP_USER SHA "$AUTH_PASS" AES "$PRIV_PASS"
rouser $SNMP_USER authPriv
view systemview included .1.3.6.1.2.1.1
view systemview included .1.3.6.1.2.1.2
view systemview included .1.3.6.1.2.1.25
logOption f /var/log/snmpd.log
EOF

systemctl restart snmpd
systemctl enable snmpd

echo "SNMPv3 configure"
echo "   Utilisateur: $SNMP_USER"
echo "   Test: snmpget -v3 -l authPriv -u $SNMP_USER -a SHA -A $AUTH_PASS -x AES -X $PRIV_PASS localhost .1.3.6.1.2.1.1.1.0"