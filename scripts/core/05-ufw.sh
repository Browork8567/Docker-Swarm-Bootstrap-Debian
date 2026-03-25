#!/bin/bash
set -e

echo "[INFO] Configuring UFW..."

apt-get install -y ufw

ufw default deny incoming
ufw default allow outgoing

# Always allow SSH first (safety)
ufw allow OpenSSH

ADMIN_IP=$(jq -r .admin_ip /etc/swarm-bootstrap/config.json)

if [[ "$ADMIN_IP" != "null" ]]; then
    ufw allow from "$ADMIN_IP" to any port 22
fi

# Allow ALL swarm-related traffic initially (broad)
ufw allow 2377/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp

# Allow internal subnet (optional but safer for bootstrap)
ufw allow from 10.0.0.0/8
ufw allow from 172.16.0.0/12
ufw allow from 192.168.0.0/16

ufw --force enable

echo "[INFO] UFW configured (initial permissive mode)."