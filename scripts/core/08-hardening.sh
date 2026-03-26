#!/usr/bin/env bash
set -euo pipefail

echo "[08] Applying system hardening..."

# -------------------------------
# Install fail2ban if missing
# -------------------------------
if ! command -v fail2ban-client >/dev/null 2>&1; then
    echo "[INFO] Installing fail2ban..."
    apt-get update
    apt-get install -y fail2ban
else
    echo "[INFO] fail2ban already installed"
fi

# -------------------------------
# Ensure config directory exists
# -------------------------------
mkdir -p /etc/fail2ban

# -------------------------------
# Configure jail.local
# -------------------------------
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 5m
findtime = 1m
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = systemd
EOF

# -------------------------------
# Enable + start service
# -------------------------------
systemctl enable fail2ban
systemctl restart fail2ban

echo "[INFO] fail2ban configured and running"

# -------------------------------
# Basic sysctl hardening (optional but good)
# -------------------------------
SYSCTL_FILE="/etc/sysctl.d/99-swarm-hardening.conf"

cat > "$SYSCTL_FILE" <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
EOF

sysctl --system

echo "[08] Hardening complete."