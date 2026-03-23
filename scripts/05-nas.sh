#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] NAS setup (secure input)..."

read -rp "NAS username: " NAS_USER
read -rsp "NAS password: " NAS_PASS
echo

cat <<EOF >/etc/.smbcredentials
username=$NAS_USER
password=$NAS_PASS
EOF

chmod 600 /etc/.smbcredentials

mkdir -p /data

cat <<EOF >>/etc/fstab
//${NAS_IP}/data /data cifs credentials=/etc/.smbcredentials,vers=3.0,_netdev,nofail 0 0
EOF

mount -a
