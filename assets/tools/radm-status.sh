#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RADM AI v3.0 - Etat Systeme                               ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

if [ -f /etc/radm/version ]; then
    echo "Version: $(head -1 /etc/radm/version | cut -d' ' -f5- | xargs)"
fi

if [ -f /opt/radm/configs/current-mode.conf ]; then
    echo "Mode: $(cat /opt/radm/configs/current-mode.conf)"
fi

if [ -f /opt/radm/configs/xdp-mode.conf ]; then
    XDP_MODE=$(cat /opt/radm/configs/xdp-mode.conf)
    case $XDP_MODE in
        native)  echo "XDP: natif (OK)" ;;
        generic) echo "XDP: generique (fallback)" ;;
        none)    echo "XDP: desactive" ;;
    esac
fi

if [ -f /opt/radm/configs/capture_iface.conf ]; then
    CAPTURE_NIC=$(cat /opt/radm/configs/capture_iface.conf)
    echo "NIC capture: $CAPTURE_NIC"
fi

echo -e "\nSECURITE:"
echo -n "   Firewall: "; ufw status | grep -q active && echo "actif" || echo "inactif"
echo -n "   Fail2ban: "; systemctl is-active --quiet fail2ban && echo "actif" || echo "inactif"
echo -n "   Auditd:   "; systemctl is-active --quiet auditd && echo "actif" || echo "inactif"
echo -n "   AppArmor: "; systemctl is-active --quiet apparmor && echo "actif" || echo "inactif"

echo -e "\nCONTENEURS:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "   Aucun"

if [ -f /opt/radm/configs/capture_iface.conf ]; then
    CAPTURE_NIC=$(cat /opt/radm/configs/capture_iface.conf)
    DROPS=$(ethtool -S $CAPTURE_NIC 2>/dev/null | grep -i drop | awk '{sum+=$2} END {print sum}')
    echo -e "\nPERFORMANCE:"
    echo "   Drops: ${DROPS:-0}"
fi