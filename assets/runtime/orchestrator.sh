#!/bin/bash
set -e
LOG_FILE="/var/log/radm-orchestrator.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "RADM AI v3.0 - Orchestrateur Runtime"
echo "Date: $(date)"
echo "=========================================="

CPU_CORES=$(nproc)
DEFAULT_NIC=$(ip route get 1 2>/dev/null | awk '{print $5; exit}')
CAPTURE_NIC=""

for nic in $(ls /sys/class/net/ | grep -v lo); do
    if [ "$nic" != "$DEFAULT_NIC" ] && ! ip addr show "$nic" | grep -q "inet "; then
        CAPTURE_NIC="$nic"
        break
    fi
done

[ -z "$CAPTURE_NIC" ] && { echo "ERREUR: Aucune NIC de capture"; exit 1; }
NIC_SPEED=$(ethtool "$CAPTURE_NIC" 2>/dev/null | grep "Speed" | awk '{print $2}' | cut -d'G' -f1)
[ -z "$NIC_SPEED" ] && NIC_SPEED=1

echo "NIC capture: $CAPTURE_NIC (${NIC_SPEED}Gbps)"
echo "$CAPTURE_NIC" > /opt/radm/configs/capture_iface.conf

MGMT_NIC="$DEFAULT_NIC"
MGMT_IP=$(ip addr show "$MGMT_NIC" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

echo "[1/5] Configuration firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

if [ -n "$MGMT_IP" ]; then
    MGMT_NET=$(echo "$MGMT_IP" | cut -d. -f1-2).0.0/16
    ufw allow from $MGMT_NET to any port 22 comment "SSH management"
    ufw allow from $MGMT_NET to any port 443 comment "HTTPS UI"
else
    ufw allow 22/tcp
    ufw allow 443/tcp
fi

ufw deny in on $CAPTURE_NIC
ufw --force enable

if [ -f "/opt/radm/configs/mode.conf" ]; then
    MODE=$(cat /opt/radm/configs/mode.conf | grep -v '^#' | head -1)
else
    if [ $CPU_CORES -lt 4 ] || [ $NIC_SPEED -lt 10 ]; then MODE="low"
    elif [ $CPU_CORES -ge 16 ] && [ $NIC_SPEED -ge 25 ]; then MODE="ultra"
    else MODE="prod"
    fi
fi

echo "Mode: $MODE"
echo "$MODE" > /opt/radm/configs/current-mode.conf

case $MODE in
    low)  RX=1024 TX=1024 COMB=4 ISOL=false ;;
    prod) RX=4096 TX=4096 COMB=8 ISOL=true ;;
    ultra) RX=8192 TX=8192 COMB=16 ISOL=true ;;
esac

ethtool -K "$CAPTURE_NIC" gro off lro off tso off gso off 2>/dev/null || true
ethtool -G "$CAPTURE_NIC" rx $RX tx $TX 2>/dev/null || true
ethtool -L "$CAPTURE_NIC" combined $COMB 2>/dev/null || true
ip link set "$CAPTURE_NIC" promisc on
ip addr flush dev "$CAPTURE_NIC" 2>/dev/null || true

if [ "$ISOL" = true ] && [ $CPU_CORES -ge 4 ]; then
    ISOL_CPUS="2-$(($CPU_CORES-1))"
    if ! grep -q "isolcpus" /proc/cmdline; then
        sed -i "s/GRUB_CMDLINE_LINUX=\"[^\"]*\"/GRUB_CMDLINE_LINUX=\"isolcpus=$ISOL_CPUS nohz_full=$ISOL_CPUS rcu_nocbs=$ISOL_CPUS\"/" /etc/default/grub
        update-grub
    fi
fi

if [ -f /opt/radm/configs/xdp-mode.conf ]; then
    XDP_MODE=$(cat /opt/radm/configs/xdp-mode.conf)
else
    XDP_MODE="unknown"
fi
echo "XDP mode: $XDP_MODE"

systemctl enable docker
systemctl start docker
usermod -aG docker radm

echo "=========================================="
echo "RADM AI v3.0 - Orchestrateur termine"
echo "=========================================="
systemctl disable radm-firstboot.service