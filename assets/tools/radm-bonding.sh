#!/bin/bash
set -euo pipefail
MODE="${1:-auto}"
BOND_NAME="${BOND_NAME:-bond0}"

MGMT_NIC=$(ip route get 1 2>/dev/null | awk '{print $5; exit}')
CAPTURE_NICS=()

for nic in $(ls /sys/class/net/ | grep -v lo); do
    if [ "$nic" != "$MGMT_NIC" ] && ! ip addr show "$nic" 2>/dev/null | grep -q "inet "; then
        CAPTURE_NICS+=("$nic")
    fi
done

if [ ${#CAPTURE_NICS[@]} -lt 2 ] && [ "$MODE" != "auto" ]; then
    echo "Moins de 2 NICs disponibles pour bonding"
    exit 0
fi

configure_bonding() {
    command -v ifenslave >/dev/null 2>&1 || apt install -y ifenslave
    modprobe bonding mode=4 miimon=100
    
    cat > /etc/netplan/99-radm-bonding.yaml << NETPLAN
network:
  version: 2
  renderer: networkd
  bonds:
    $BOND_NAME:
      interfaces: [$(IFS=,; echo "${CAPTURE_NICS[*]}")]
      parameters:
        mode: 802.3ad
        mii-monitor-interval: 100
        lacp-rate: fast
      dhcp4: no
NETPLAN
    netplan apply
    echo "$BOND_NAME" > /opt/radm/configs/capture_iface.conf
    echo "Bonding configure: ${CAPTURE_NICS[*]} -> $BOND_NAME"
}

case $MODE in
    auto)
        if [ ${#CAPTURE_NICS[@]} -ge 2 ]; then
            configure_bonding
        else
            echo "${CAPTURE_NICS[0]:-}" > /opt/radm/configs/capture_iface.conf
        fi
        ;;
    lacp) configure_bonding ;;
    *) echo "Usage: $0 [auto|lacp]"; exit 1 ;;
esac