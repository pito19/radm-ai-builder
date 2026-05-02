#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RADM AI v3.0 - Diagnostic                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "MATERIEL:"
echo "   CPU: $(nproc) cores ($(lscpu | grep 'Model name' | cut -d: -f2 | xargs))"
echo "   RAM: $(free -h | awk '/^Mem:/{print $2}')"
echo "   Kernel: $(uname -r)"
if [ -f /etc/radm/fingerprint ]; then
    echo "   Fingerprint: $(head -1 /etc/radm/fingerprint | cut -c1-16)..."
fi

if [ -f /opt/radm/configs/capture_iface.conf ]; then
    CAPTURE_NIC=$(cat /opt/radm/configs/capture_iface.conf)
    echo -e "\nINTERFACES RESEAU:"
    echo "   NIC capture: $CAPTURE_NIC"
    echo "   Speed: $(ethtool $CAPTURE_NIC 2>/dev/null | grep Speed | awk '{print $2}')"
    echo "   Promiscuous: $(ip link show $CAPTURE_NIC | grep -q PROMISC && echo "oui" || echo "non")"
fi

echo -e "\nXDP:"
if [ -f /opt/radm/configs/xdp-mode.conf ]; then
    echo "   Mode: $(cat /opt/radm/configs/xdp-mode.conf)"
fi
if [ -f /opt/radm/configs/capture_iface.conf ]; then
    CAPTURE_NIC=$(cat /opt/radm/configs/capture_iface.conf)
    if ip link show $CAPTURE_NIC 2>/dev/null | grep -q "xdp"; then
        echo "   XDP actif sur $CAPTURE_NIC"
    else
        echo "   XDP inactif"
    fi
fi

echo -e "\nSERVICES:"
for svc in docker ssh ufw fail2ban auditd apparmor radm-xdp radm-ringbuf radm-watchdog; do
    if systemctl is-active --quiet $svc 2>/dev/null; then
        echo "   OK $svc"
    else
        echo "   FAIL $svc"
    fi
done

echo -e "\nDiagnostic termine"