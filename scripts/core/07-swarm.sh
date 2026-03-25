#!/bin/bash
set -e

echo "[INFO] Configuring Docker Swarm..."

# Wait for Docker
until docker info >/dev/null 2>&1; do
    echo "[INFO] Waiting for Docker..."
    sleep 2
done

ROLE=$(jq -r .role /etc/swarm-bootstrap/config.json)
NODE_IP=$(jq -r .node_ip /etc/swarm-bootstrap/config.json)
IS_PRIMARY=$(jq -r .is_primary_manager /etc/swarm-bootstrap/config.json)

# Load manager list safely
if [[ -f /etc/swarm-bootstrap/nodes.json ]]; then
    PRIMARY_MANAGER=$(jq -r '.managers[0]' /etc/swarm-bootstrap/nodes.json)
else
    PRIMARY_MANAGER="$NODE_IP"
fi

if [[ "$ROLE" == "manager" ]]; then

    if ! docker info | grep -q "Swarm: active"; then

        if [[ "$IS_PRIMARY" == "true" ]]; then
            echo "[INFO] Initializing swarm as PRIMARY manager..."

            docker swarm init --advertise-addr "$NODE_IP"

            mkdir -p /etc/swarm-bootstrap
            cat > /etc/swarm-bootstrap/nodes.json <<EOF
{
  "managers": ["$NODE_IP"],
  "workers": []
}
EOF

        else
            echo "[INFO] Joining existing swarm as manager..."

            for i in {1..5}; do
                TOKEN=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PRIMARY_MANAGER" \
                    "docker swarm join-token -q manager") && break
                sleep 3
            done

            docker swarm join --token "$TOKEN" "$PRIMARY_MANAGER:2377" || {
                echo "[ERROR] Manager failed to join swarm"
                exit 1
            }

            docker info | grep -q "Swarm: active" || {
                echo "[ERROR] Manager join validation failed"
                exit 1
            }
        fi
    fi

else
    echo "[INFO] Joining swarm as worker..."

    for i in {1..5}; do
        TOKEN=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PRIMARY_MANAGER" \
            "docker swarm join-token -q worker") && break
        sleep 3
    done

    docker swarm join --token "$TOKEN" "$PRIMARY_MANAGER:2377" || {
        echo "[ERROR] Worker failed to join swarm"
        exit 1
    }

    docker info | grep -q "Swarm: active" || {
        echo "[ERROR] Worker join validation failed"
        exit 1
    }
fi

echo "[INFO] Swarm configuration complete."