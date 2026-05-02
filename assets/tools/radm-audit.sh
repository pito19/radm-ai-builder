#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RADM AI v3.0 - Audit Securite                             ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "SERVICES RESEAU EXPOSES:"
ss -tln | grep -E "0.0.0.0|:::" | awk '{print "   " $4}' | sort -u

echo -e "\nUTILISATEURS SUDO:"
grep -v "^#" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -v "Default" | grep "ALL=" | cut -d: -f2 | sed 's/^/   /'

echo -e "\nAPPARMOR:"
aa-status | grep "profiles are in enforce mode" | sed 's/^/   /'

echo -e "\nAUDITD:"
systemctl is-active --quiet auditd && echo "   Auditd actif" || echo "   Auditd inactif"

echo -e "\nCONTENEURS ROOT:"
docker ps --format "{{.Names}}" 2>/dev/null | while read name; do
    if docker inspect $name 2>/dev/null | grep -q '"User": ""'; then
        echo "   WARNING $name (root)"
    fi
done

echo -e "\nAudit termine"