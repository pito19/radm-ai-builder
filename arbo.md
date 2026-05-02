radm-iso-builder/
├── build.sh
├── assets/
│   ├── preseed/
│   │   └── radm-preseed.cfg
│   ├── late-command/
│   │   └── late-command.sh
│   ├── hardening/
│   │   ├── 01-ssh.sh
│   │   ├── 03-fail2ban.sh
│   │   ├── 04-journald.sh
│   │   ├── 05-audit.sh
│   │   ├── 06-apparmor.sh
│   │   └── apply.sh
│   ├── xdp/
│   │   ├── radm_xdp.c
│   │   ├── load.sh
│   │   ├── ringbuf-reader.sh
│   │   └── xdp-reload.sh
│   ├── services/
│   │   ├── radm-hardening.service
│   │   ├── radm-xdp.service
│   │   ├── radm-runtime.service
│   │   ├── radm-health.service
│   │   └── radm-health.timer
│   ├── configs/
│   │   ├── 99-radm-perf.conf
│   │   ├── 99-radm-security.conf
│   │   ├── limits.conf
│   │   ├── blacklist-modules.conf
│   │   ├── logrotate-radm.conf
│   │   ├── mode.conf
│   │   ├── aide.conf
│   │   └── snmpd.conf
│   ├── tools/
│   │   ├── radm-status.sh
│   │   ├── radm-debug.sh
│   │   ├── radm-audit.sh
│   │   ├── radm-fallback.sh
│   │   ├── radm-health.sh
│   │   ├── radm-backup.sh
│   │   ├── radm-restore.sh
│   │   ├── radm-kpi-collect.sh
│   │   ├── radm-nvme-check.sh
│   │   ├── radm-snmp-setup.sh
│   │   ├── radm-kexec-update.sh
│   │   ├── radm-onboard.sh
│   │   ├── radm-bonding.sh
│   │   ├── radm-watchdog.sh
│   │   └── radm-syslog-forward.sh
│   └── runtime/
│       ├── orchestrator.sh
│       └── deploy.sh
└── .github/workflows/build-iso.yml