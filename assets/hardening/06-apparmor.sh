#!/bin/bash
echo "[APPARMOR] Configuration..."
systemctl enable --now apparmor
aa-status | head -3