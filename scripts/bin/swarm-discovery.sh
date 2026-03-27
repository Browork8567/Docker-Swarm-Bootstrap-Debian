#!/bin/bash
set -euo pipefail

CONFIG="/etc/swarm-bootstrap/config.json"
NODES="/etc/swarm-bootstrap/nodes.json"

PRIMARY=$(jq -r .primary_manager_ip "$CONFIG")
SELF=$(jq -r .node_ip "$CONFIG")

# Only leader runs
if [[ "$SELF" != "$PRIMARY" ]]; then
    exit 0
fi

BOOT_USER=$(jq -r .bootstrap_user "$CONFIG")
BOOT_PASS=$(jq -r .bootstrap_password "$CONFIG")

expand_range() {
    START=$(echo $1 | cut -d'-' -f1 | awk -F. '{print $4}')
    END=$(echo $1 | cut -d'-' -f2 | awk -F. '{print $4}')
    BASE=$(echo $1 | cut -d'-' -f1 | awk -F. '{print $1"."$2"."$3}')
    for i in $(seq $START $END); do
        echo "$BASE.$i"
    done
}

ALL_IPS=$(expand_range "$(jq -r .manager_range "$CONFIG")")
ALL_IPS+=" $(expand_range "$(jq -r .worker_range "$CONFIG") )"

for IP in $ALL_IPS; do
    [[ "$IP" == "$SELF" ]] && continue

    ping -c1 -W1 "$IP" >/dev/null 2>&1 || continue

    if grep -q "$IP" "$NODES" 2>/dev/null; then
        continue
    fi

    echo "[INFO] Found new node: $IP"

    sshpass -p "$BOOT_PASS" ssh -o StrictHostKeyChecking=no "$BOOT_USER@$IP" "
        useradd -m -s /bin/bash swarmd || true
        mkdir -p /home/swarmd/.ssh
        echo '$(cat /home/swarmd/.ssh/id_rsa.pub)' >> /home/swarmd/.ssh/authorized_keys
        chown -R swarmd:swarmd /home/swarmd/.ssh
        chmod 700 /home/swarmd/.ssh
        chmod 600 /home/swarmd/.ssh/authorized_keys
    "

    TOKEN=$(docker swarm join-token -q worker)

    ssh -i /home/swarmd/.ssh/id_rsa -o StrictHostKeyChecking=no swarmd@$IP \
        "docker swarm join --token $TOKEN $PRIMARY:2377"

    jq --arg ip "$IP" '.workers += [$ip]' "$NODES" > tmp && mv tmp "$NODES"

done