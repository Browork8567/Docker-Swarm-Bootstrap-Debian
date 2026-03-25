#!/bin/bash
set -e

CONFIG_DIR="/etc/swarm-bootstrap"
SECURE_DIR="$HOME/.swarm-bootstrap"
CONFIG_FILE="$CONFIG_DIR/config.json"
SECURE_FILE="$SECURE_DIR/secure.env.gpg"

mkdir -p "$CONFIG_DIR"
mkdir -p "$SECURE_DIR"

echo "==== Docker Swarm Bootstrap ===="

### 🔹 USER INPUT

read -p "Node role (manager/worker): " NODE_ROLE
read -p "Hostname: " HOSTNAME
read -p "Primary IP: " NODE_IP
read -p "Manager IP (for SSH): " MANAGER_IP

read -p "Use NAS? (y/n): " USE_NAS

if [[ "$USE_NAS" == "y" ]]; then
    read -p "NAS IP: " NAS_IP
    read -p "NAS Share: " NAS_SHARE
    read -p "NAS Username: " NAS_USER
    read -s -p "NAS Password: " NAS_PASS
    echo
fi

### 🔹 SAVE CONFIG (non-sensitive)
cat > "$CONFIG_FILE" <<EOF
{
  "role": "$NODE_ROLE",
  "hostname": "$HOSTNAME",
  "ip": "$NODE_IP",
  "manager_ip": "$MANAGER_IP",
  "use_nas": "$USE_NAS"
}
EOF

### 🔐 SAVE NAS SECURELY
if [[ "$USE_NAS" == "y" ]]; then
    echo "NAS_USER=$NAS_USER
NAS_PASS=$NAS_PASS
NAS_IP=$NAS_IP
NAS_SHARE=$NAS_SHARE" | gpg --symmetric --cipher-algo AES256 -o "$SECURE_FILE"
fi

### 🔹 APPLY HOSTNAME
hostnamectl set-hostname "$HOSTNAME"

### 🔹 RUN MODULES

echo "[1/9] Base setup..."
bash scripts/01-base.sh

echo "[2/9] Installing Docker..."
bash scripts/02-docker.sh

echo "[3/9] Setting up SSH trust..."
bash scripts/03-ssh.sh "$MANAGER_IP"

echo "[4/9] Configuring firewall..."
bash scripts/04-ufw.sh

if [[ "$USE_NAS" == "y" ]]; then
    echo "[5/9] Setting up NAS..."
    bash scripts/05-nas.sh "$SECURE_FILE"
fi

echo "[6/9] Swarm setup..."
bash scripts/07-swarm.sh "$NODE_ROLE" "$MANAGER_IP"

echo "[7/9] Hardening..."
bash scripts/08-hardening.sh

echo "[8/9] Installing recovery services..."
bash systemd/install-services.sh

echo "[INFO] Installing runtime scripts..."
bash scripts/09-install-runtime.sh

echo "==== COMPLETE ===="