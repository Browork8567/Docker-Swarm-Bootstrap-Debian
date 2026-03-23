#!/usr/bin/env bash
set -euo pipefail

apt install -y ufw

ufw --force reset

ufw default deny incoming
ufw default allow outgoing

ufw allow in on lo

# SSH restricted
ufw allow from $ADMIN_IP to any port 22 proto tcp
ufw limit 22/tcp

# Swarm ONLY internal
ufw allow from $LAN_SUBNET to any port 2377 proto tcp
ufw allow from $LAN_SUBNET to any port 7946 proto tcp
ufw allow from $LAN_SUBNET to any port 7946 proto udp
ufw allow from $LAN_SUBNET to any port 4789 proto udp

# VPN access only
ufw allow from $VPN_SUBNET

ufw --force enable