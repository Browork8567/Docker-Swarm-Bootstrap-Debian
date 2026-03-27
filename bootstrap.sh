#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Starting Swarm Bootstrap..."

USER_CONFIG="$HOME/.swarm-bootstrap/config.json"
SYSTEM_CONFIG="/etc/swarm-bootstrap/config.json"

# -------------------------------
# CHECK REQUIRED TOOLS
# -------------------------------
check_install() {
    local pkg="$1"

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "[INFO] $pkg already installed"
    else
        echo "[WARN] $pkg is required but not installed"
        read -rp "Install $pkg now? (y/n): " INSTALL

        if [[ "$INSTALL" =~ ^[Yy]$ ]]; then
            apt-get update -y
            apt-get install -y "$pkg"
        else
            echo "[ERROR] Cannot continue without $pkg"
            exit 1
        fi
    fi
}

check_install jq
check_install openssl

# -------------------------------
# IMPORT USER CONFIG IF EXISTS
# -------------------------------
if [[ -f "$USER_CONFIG" && ! -f "$SYSTEM_CONFIG" ]]; then
    echo "[INFO] Importing existing user config..."

    mkdir -p /etc/swarm-bootstrap

    jq 'del(.bootstrap_password)' "$USER_CONFIG" > "$SYSTEM_CONFIG"

    echo "[INFO] Config imported to system location"
fi

# -------------------------------
# RUN CORE SCRIPTS
# -------------------------------
# -------------------------------
# CORE SCRIPT EXECUTION (ORDERED)
# -------------------------------
echo "[INFO] Running core bootstrap scripts..."

# Define execution order explicitly
CORE_SCRIPTS=(
    "scripts/core/01-config.sh"
    "scripts/core/02-dependencies.sh"
    "scripts/core/03-swarm-user.sh"
    "scripts/core/04-ssh.sh"
    "scripts/core/05-ufw.sh"
    "scripts/core/06-nas.sh"
    "scripts/core/07-swarm.sh"
    "scripts/core/08-hardening.sh"
    "scripts/core/09-install-runtime.sh"
)

for script in "${CORE_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo "[INFO] Running $script"
        bash "$script"
    else
        echo "[WARN] Missing $script, skipping"
    fi
done

echo "[INFO] Core bootstrap complete"