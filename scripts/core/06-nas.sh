#!/usr/bin/env bash
set -euo pipefail

CONFIG="/etc/swarm-bootstrap/config.json"
CRED_FILE="/root/.nas-cred"

if [[ ! -f "$CONFIG" ]]; then
    echo "[WARN] Config file not found, skipping NAS setup"
    exit 0
fi

echo "[07] Mounting NAS (optional)..."

# Load config
NAS_IP=$(jq -r .nas_ip "$CONFIG")
NAS_SHARE_NAME=$(jq -r .nas_share "$CONFIG")
NAS_PATH=$(jq -r .nas_path "$CONFIG")

# Skip if not configured
if [[ "$NAS_IP" == "null" || -z "$NAS_IP" ]]; then
    echo "[INFO] NAS not configured, skipping..."
    exit 0
fi

# Validate credentials file
if [[ ! -f "$CRED_FILE" ]]; then
    echo "[WARN] Credentials file not found, skipping mount"
    exit 0
fi

# Build share path (IP-based, no DNS)
NAS_SHARE="//${NAS_IP}/${NAS_SHARE_NAME}"

# Create mount point
mkdir -p "$NAS_PATH"

# fstab entry
FSTAB_ENTRY="${NAS_SHARE} ${NAS_PATH} cifs credentials=${CRED_FILE},_netdev,iocharset=utf8 0 0"

# Add to fstab if not already present
if ! grep -q "$NAS_SHARE" /etc/fstab; then
    echo "[INFO] Adding NAS mount to /etc/fstab"
    echo "$FSTAB_ENTRY" >> /etc/fstab
else
    echo "[INFO] NAS already present in /etc/fstab"
fi

# Attempt mount (non-blocking)
if mount -a; then
    echo "[INFO] NAS mounted successfully"
else
    echo "[WARN] NAS mount failed (continuing)"
fi

echo "[07] NAS step complete (non-blocking)."