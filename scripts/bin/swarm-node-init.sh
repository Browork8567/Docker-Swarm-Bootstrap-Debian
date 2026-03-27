#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Running controlled node initialization..."

SWARMD_HOME="/home/swarmd"
SSH_DIR="$SWARMD_HOME/.ssh"

# -------------------------------
# ENSURE SWARMD USER
# -------------------------------
if ! id -u swarmd >/dev/null 2>&1; then
    useradd -r -m -d "$SWARMD_HOME" -s /usr/sbin/nologin swarmd
    echo "[INFO] swarmd user created"
else
    echo "[INFO] swarmd already exists"
fi

# -------------------------------
# DOCKER GROUP
# -------------------------------
if getent group docker >/dev/null; then
    usermod -aG docker swarmd
fi

# -------------------------------
# SSH DIRECTORY
# -------------------------------
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown -R swarmd:swarmd "$SWARMD_HOME"

# -------------------------------
# AUTHORIZE KEY (PASSED IN)
# -------------------------------
PUB_KEY_FILE="/tmp/swarmd.pub"

if [[ -f "$PUB_KEY_FILE" ]]; then
    grep -qxF "$(cat $PUB_KEY_FILE)" "$SSH_DIR/authorized_keys" 2>/dev/null || \
        echo "no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty $(cat $PUB_KEY_FILE)" >> "$SSH_DIR/authorized_keys"
fi

chmod 600 "$SSH_DIR/authorized_keys"
chown swarmd:swarmd "$SSH_DIR/authorized_keys"

# -------------------------------
# CLEANUP BOOTSTRAP ACCESS
# -------------------------------
echo "[INFO] Removing bootstrap user..."

userdel -r bootstrap || true
rm -f /etc/sudoers.d/bootstrap || true

echo "[INFO] Node initialization complete"