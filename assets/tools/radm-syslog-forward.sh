#!/bin/bash
set -euo pipefail
SYSLOG_SERVER="${1:-}"
SYSLOG_PORT="${2:-514}"
SYSLOG_PROTO="${3:-tcp}"

if [ -z "$SYSLOG_SERVER" ]; then
    echo "Usage: $0 <server> [port] [tcp|udp]"
    exit 1
fi

configure_rsyslog_forward() {
    local config_file="/etc/rsyslog.d/99-radm-forward.conf"
    if [ "$SYSLOG_PROTO" = "tcp" ]; then
        echo "*.* @@${SYSLOG_SERVER}:${SYSLOG_PORT}" > "$config_file"
    else
        echo "*.* @${SYSLOG_SERVER}:${SYSLOG_PORT}" > "$config_file"
    fi
    systemctl restart rsyslog
}

configure_journald_forward() {
    sed -i 's/^#ForwardToSyslog=.*/ForwardToSyslog=yes/' /etc/systemd/journald.conf
    systemctl restart systemd-journald
}

configure_rsyslog_forward
configure_journald_forward

mkdir -p /etc/radm
cat > /etc/radm/syslog-forward.conf << EOF
SYSLOG_SERVER=$SYSLOG_SERVER
SYSLOG_PORT=$SYSLOG_PORT
SYSLOG_PROTO=$SYSLOG_PROTO
EOF

echo "Syslog forward vers $SYSLOG_SERVER:$SYSLOG_PORT ($SYSLOG_PROTO)"