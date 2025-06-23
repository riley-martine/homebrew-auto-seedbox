#!/bin/bash

# Sets and exports config variables. Useful for debugging -- source this and run whatever other scripts.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"

CONFIG_DIR="$HOME/.config/auto-seedbox"
mkdir -p "$CONFIG_DIR"
CONFIG="$CONFIG_DIR/config.json"
if [ ! -f "$CONFIG" ]; then
    echo "No config file found at $CONFIG" >&2
    exit 1
fi
export CONFIG

SSH_USER="$(jq -r -e '.ssh_user' "$CONFIG")"
SSH_HOST="$(jq -r -e '.ssh_host' "$CONFIG")"
SSH_PORT="$(jq -r -e '.ssh_port' "$CONFIG")"
SSH_KEY="$(jq -r -e '.ssh_key' "$CONFIG")"
export SSH_USER

SSH_CONF="$CONFIG_DIR"/sshconfig
echo "Host seedbox
    HostName $SSH_HOST
    User $SSH_USER
    Port $SSH_PORT
    IdentityFile $SSH_KEY" > "$SSH_CONF"
export SSH_CONF

RCLONE_CONF="$CONFIG_DIR"/rclone.conf
echo "[seedbox]
type = sftp
host = $SSH_HOST
user = $SSH_USER
port = $SSH_PORT
shell_type = unix
md5sum_command = none
sha1sum_command = none" > "$RCLONE_CONF"
export RCLONE_CONF

function do_send_to_kindle {
    jq -r -e '.send_to_kindle' "$CONFIG"
}
export -f do_send_to_kindle
