#!/bin/bash

NODES="/etc/swarm-bootstrap/nodes.json"

[[ ! -f "$NODES" ]] && exit 0

ADMIN_IP=$(jq -r .admin_ip /etc/swarm-bootstrap/config.json)

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

ufw allow from "$ADMIN_IP" to any port 22

for IP in $(jq -r '.managers[]' "$NODES"); do
    ufw allow from "$IP" to any port 22
done

ufw allow 2377/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp

ufw --force enable