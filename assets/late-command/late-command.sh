#!/bin/bash
set -e

# Création arborescence
mkdir -p /target/opt/radm/{hardening,performance,xdp,runtime,tools,configs,services}
mkdir -p /target/usr/local/bin /target/etc/radm /target/etc/docker /target/etc/systemd/system
mkdir -p /target/backup

# ============================================================================
# Configuration APT pour offline (air-gap)
# ============================================================================

echo "[OFFLINE] Configuration du repo APT local..."

# Copier le repo depuis l'ISO
mkdir -p /target/opt/radm/repo
cp -a /cdrom/radm-repo/* /target/opt/radm/repo/ 2>/dev/null || true

# Configuration sources.list
cp /target/etc/apt/sources.list /target/etc/apt/sources.list.original 2>/dev/null || true

cat > /target/etc/apt/sources.list << 'APT_OFFLINE'
deb file:/opt/radm/repo stable main
APT_OFFLINE

rm -f /target/etc/apt/sources.list.d/*.list 2>/dev/null || true

chroot /target apt-get update

# Installation des paquets
chroot /target apt-get install -y --no-install-recommends \
    docker.io docker-compose auditd clang llvm libbpf-dev jq \
    kexec-tools snmpd nvme-cli fail2ban ufw aide apparmor \
    ethtool tcpdump htop vim curl git 2>/dev/null || true

# ============================================================================
# Versioning et fingerprint
# ============================================================================
cat > /target/etc/radm/version << VERSION
RADM AI - Network Detection & Response
Version: 3.0.0
Build Date: \$(date +%Y-%m-%d)
Architecture: amd64
Mode: AIR-GAP OFFLINE
VERSION

chroot /target dmidecode -s system-uuid > /target/etc/radm/fingerprint 2>/dev/null || echo "unknown" > /target/etc/radm/fingerprint
chroot /target dmidecode -s system-serial-number >> /target/etc/radm/fingerprint 2>/dev/null || echo "unknown" >> /target/etc/radm/fingerprint

# Copie des scripts
cp /cdrom/iso/hardening/* /target/opt/radm/hardening/ 2>/dev/null || true
cp /cdrom/iso/performance/* /target/opt/radm/performance/ 2>/dev/null || true
cp /cdrom/iso/xdp/* /target/opt/radm/xdp/ 2>/dev/null || true
cp /cdrom/iso/runtime/* /target/opt/radm/runtime/ 2>/dev/null || true
cp /cdrom/iso/tools/* /target/opt/radm/tools/ 2>/dev/null || true
cp /cdrom/iso/configs/* /target/opt/radm/configs/ 2>/dev/null || true
cp /cdrom/iso/services/* /target/etc/systemd/system/ 2>/dev/null || true

find /target/opt/radm -name "*.sh" -exec chmod +x {} \;

# Copier configurations système
cp /cdrom/iso/configs/99-radm-perf.conf /target/etc/sysctl.d/
cp /cdrom/iso/configs/99-radm-security.conf /target/etc/sysctl.d/
cp /cdrom/iso/configs/limits.conf /target/etc/security/limits.d/99-radm.conf
cp /cdrom/iso/configs/blacklist-modules.conf /target/etc/modprobe.d/blacklist-radm.conf
cp /cdrom/iso/configs/logrotate-radm.conf /target/etc/logrotate.d/radm
cp /cdrom/iso/configs/aide.conf /target/etc/aide/aide.conf
cp /cdrom/iso/configs/snmpd.conf /target/etc/snmp/snmpd.conf

# ============================================================================
# Docker sécurisé + userns-remap
# ============================================================================
mkdir -p /target/etc/docker
cat > /target/etc/docker/daemon.json << 'DOCKERJSON'
{
  "log-driver": "journald",
  "log-opts": {"tag": "{{.Name}}", "max-size": "100m", "max-file": "3"},
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "ip-forward": false,
  "iptables": true,
  "live-restore": true,
  "log-level": "warn",
  "userns-remap": "radm",
  "seccomp-profile": "/etc/docker/seccomp-radm.json",
  "registry-mirrors": [],
  "insecure-registries": []
}
DOCKERJSON

echo "radm:100000:65536" >> /target/etc/subuid
echo "radm:100000:65536" >> /target/etc/subgid
chroot /target chown root:root /etc/subuid /etc/subgid
chroot /target chmod 644 /etc/subuid /etc/subgid

cat > /target/etc/docker/seccomp-radm.json << 'SECCOMP'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [{"names": ["accept","accept4","access","arch_prctl","bind","brk","capget","capset","chdir","clone","close","connect","dup","dup2","epoll_create","epoll_create1","epoll_ctl","epoll_wait","eventfd2","execve","exit","exit_group","fadvise64","fchown","fcntl","fstat","fstatfs","ftruncate","futex","getcwd","getdents","getegid","geteuid","getgid","getpeername","getpid","getppid","getsockname","getsockopt","gettid","getuid","inotify_init1","ioctl","listen","llseek","lseek","madvise","mincore","mkdir","mmap","mprotect","munmap","nanosleep","open","openat","pipe","pipe2","poll","ppoll","prctl","read","readlink","recvfrom","recvmsg","rename","rt_sigaction","rt_sigprocmask","rt_sigreturn","sendmsg","sendto","set_robust_list","set_tid_address","setgid","setgroups","setsid","setsockopt","setuid","shutdown","sigaltstack","socket","socketcall","socketpair","stat","statfs","sysinfo","tgkill","time","tkill","uname","wait4","write"], "action": "SCMP_ACT_ALLOW"}]
}
SECCOMP

# ============================================================================
# SSH durci
# ============================================================================
chroot /target sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
chroot /target sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
chroot /target systemctl enable ssh

# ============================================================================
# Services systemd
# ============================================================================
cat > /target/etc/systemd/system/radm-firstboot.service << 'SERVICE'
[Unit]
Description=RADM AI First Boot v3.0
After=network.target multi-user.target docker.service
Wants=network.target docker.service
[Service]
Type=oneshot
ExecStart=/opt/radm/runtime/orchestrator.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SERVICE

cat > /target/etc/systemd/system/radm-ringbuf.service << 'RINGBUF'
[Unit]
Description=RADM XDP Ring Buffer Reader
After=radm-xdp.service
Requires=radm-xdp.service
[Service]
Type=simple
ExecStart=/opt/radm/xdp/ringbuf-reader.sh
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
RINGBUF

cat > /target/etc/systemd/system/radm-watchdog.service << 'WATCHDOG'
[Unit]
Description=RADM Watchdog v3.0
After=multi-user.target
[Service]
Type=simple
ExecStart=/opt/radm/tools/radm-watchdog.sh
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
WATCHDOG

chroot /target systemctl enable radm-firstboot.service
chroot /target systemctl enable radm-ringbuf.service 2>/dev/null || true
chroot /target systemctl enable radm-watchdog.service 2>/dev/null || true
chroot /target systemctl enable radm-health.timer 2>/dev/null || true
chroot /target systemctl enable docker

# ============================================================================
# MOTD
# ============================================================================
cat > /target/etc/motd << 'MOTD'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ██████╗  █████╗ ██████╗ ███╗   ███╗                                       ║
║    ██╔══██╗██╔══██╗██╔══██╗████╗ ████║                                       ║
║    ██████╔╝███████║██║  ██║██╔████╔██║                                       ║
║    ██╔══██╗██╔══██║██║  ██║██║╚██╔╝██║                                       ║
║    ██║  ██║██║  ██║██████╔╝██║ ╚═╝ ██║                                       ║
║    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝                                       ║
║                                                                              ║
║    RADM AI v3.0 - Network Detection & Response - AIR-GAP OFFLINE EDITION     ║
║                                                                              ║
║    📊 COMMANDES: radm-status, radm-debug, radm-audit, radm-health,           ║
║                 radm-onboard, radm-backup, radm-restore, radm-kpi-collect    ║
║                                                                              ║
║    📅 Version 3.0.0 | \$(date +%Y-%m-%d)                                     ║
║    📦 Mode: OFFLINE (air-gap) - Aucun appel réseau                           ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
MOTD

# Métadonnées ISO
cat > /target/.disk/info << 'DISKINFO'
RADM AI - Network Detection & Response
Version: 3.0.0
Architecture: amd64
Type: Industrial Offline Ready NDR - AIR-GAP
Security: ANSSI BP-028 compliant, OIVI ready
Installation: 100% offline - no network required
DISKINFO
EOF