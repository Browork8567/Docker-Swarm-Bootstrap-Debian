#!/bin/bash
set -euo pipefail

echo "[INFO] Setting up SSH for swarmd..."

# -------------------------------
# VARIABLES
# -------------------------------
CONFIG_FILE="/etc/swarm-bootstrap/nodes.json"
HOME_DIR="/home/swarmd"
SSH_DIR="$HOME_DIR/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"

# -------------------------------
# CHECK CONFIG
# -------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[WARN] nodes.json not found, skipping SSH sync"
    exit 0
fi

# -------------------------------
# ENSURE SSH DIRECTORY
# -------------------------------
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown swarmd:swarmd "$SSH_DIR"

# -------------------------------
# SSH KEY GENERATION (idempotent)
# -------------------------------
if [[ ! -f "$KEY_FILE" ]]; then
    echo "[INFO] Generating SSH key for swarmd..."
    sudo -u swarmd ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N ""
else
    echo "[INFO] SSH key already exists"
fi

chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE.pub"
chown swarmd:swarmd "$KEY_FILE" "$KEY_FILE.pub"

# -------------------------------
# AUTHORIZED KEYS FILE
# -------------------------------
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
touch "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"
chown swarmd:swarmd "$AUTHORIZED_KEYS"

# -------------------------------
# LOAD MANAGER LIST
# -------------------------------
MANAGERS=$(jq -r '.managers[]?' "$CONFIG_FILE" || true)

if [[ -z "$MANAGERS" ]]; then
    echo "[WARN] No managers listed in nodes.json, skipping SSH sync"
    exit 0
fi

# -------------------------------
# SYNC SSH KEY TO MANAGERS
# -------------------------------
for NODE in $MANAGERS; do
    echo "[INFO] Syncing SSH key to $NODE"

    # Retry loop for SSH mkdir
    for i in {1..3}; do
        if sudo -u swarmd ssh -i "$KEY_FILE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$NODE" \
            "mkdir -p ~/.ssh && chmod 700 ~/.ssh"; then
            break
        else
            echo "[WARN] Attempt $i failed, retrying in 2s..."
            sleep 2
        fi
    done

    # Push public key (idempotent) as swarmd
    PUB_KEY=$(cat "$KEY_FILE.pub")
    sudo -u swarmd ssh -i "$KEY_FILE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$NODE" \
        "grep -qxF '$PUB_KEY' ~/.ssh/authorized_keys || \
         echo 'no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty $PUB_KEY' >> ~/.ssh/authorized_keys"

done

# -------------------------------
# FINAL PERMISSIONS CHECK
# -------------------------------
chmod 600 "$AUTHORIZED_KEYS"
chown swarmd:swarmd "$AUTHORIZED_KEYS"

echo "[INFO] SSH setup complete."