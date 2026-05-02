#!/bin/bash
if [ -f /opt/radm/configs/capture_iface.conf ]; then
    CAPTURE_NIC=$(cat /opt/radm/configs/capture_iface.conf)
else
    CAPTURE_NIC=$(ip route get 1 2>/dev/null | awk '{print $5; exit}')
    for nic in $(ls /sys/class/net/ | grep -v lo); do
        if [ "$nic" != "$CAPTURE_NIC" ] && ! ip addr show "$nic" | grep -q "inet "; then
            CAPTURE_NIC="$nic"
            break
        fi
    done
fi

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    RADM AI v3.0 - Changement mode XDP                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "   NIC: $CAPTURE_NIC"
echo ""
echo "Choisir le mode XDP:"
echo "   1) XDP natif (driver) - meilleure performance"
echo "   2) XDP generique (fallback) - compatibilite"
echo "   3) Desactiver XDP (AF_PACKET) - mode standard"
read -p "Choix [1-3]: " choice

case $choice in
    1)
        ip link set dev $CAPTURE_NIC xdp off 2>/dev/null
        if ip link set dev $CAPTURE_NIC xdp obj /opt/radm/xdp/radm_xdp.o 2>/dev/null; then
            echo "native" > /opt/radm/configs/xdp-mode.conf
            echo "XDP natif active"
        else
            echo "Echec XDP natif"
        fi
        ;;
    2)
        ip link set dev $CAPTURE_NIC xdp off 2>/dev/null
        if ip link set dev $CAPTURE_NIC xdpgeneric obj /opt/radm/xdp/radm_xdp.o 2>/dev/null; then
            echo "generic" > /opt/radm/configs/xdp-mode.conf
            echo "XDP generique active"
        else
            echo "Echec XDP generique"
        fi
        ;;
    3)
        ip link set dev $CAPTURE_NIC xdp off 2>/dev/null
        echo "none" > /opt/radm/configs/xdp-mode.conf
        echo "XDP desactive"
        ;;
    *) echo "Choix invalide"; exit 1 ;;
esac