#!/bin/bash

# Watch downloads dir for torrents, then execute upload script.

set -euxo pipefail

trap '{ echo Exited daemon, code $?; exit $?; }' EXIT
echo "Started daemon."
date
ssh-add --apple-load-keychain

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"

CONFIG_DIR="$HOME/.config/auto-seedbox"
mkdir -p "$CONFIG_DIR"
CONFIG="$CONFIG_DIR/config.json"
if [ ! -f "$CONFIG" ]; then
    echo "No config file found at $CONFIG" >&2
    exit 1
fi
export CONFIG

SEEDBOX_USER="$(jq -r -e '.seedbox_user' "$CONFIG")"
SEEDBOX_HOST="$(jq -r -e '.seedbox_host' "$CONFIG")"
SEEDBOX_PORT="$(jq -r -e '.seedbox_port' "$CONFIG")"
SEEDBOX_KEY="$(jq -r -e '.seedbox_key' "$CONFIG")"
export SEEDBOX_USER

SSH_CONF="$CONFIG_DIR"/sshconfig
echo "Host seedbox
    HostName $SEEDBOX_HOST
    User $SEEDBOX_USER
    Port $SEEDBOX_PORT
    IdentityFile $SEEDBOX_KEY" > "$SSH_CONF"
export SSH_CONF

RCLONE_CONF="$CONFIG_DIR"/rclone.conf
echo "[seedbox]
type = sftp
host = $SEEDBOX_HOST
user = $SEEDBOX_USER
port = $SEEDBOX_PORT
shell_type = unix
md5sum_command = none
sha1sum_command = none" > "$RCLONE_CONF"
export RCLONE_CONF

function do_send_to_kindle {
    jq -r -e '.send_to_kindle' "$CONFIG"
}
export -f do_send_to_kindle

# shellcheck disable=SC2016
fswatch -0 -E -e '.*' -i '.+\.torrent$' --event Created ~/Downloads/ |
    xargs -0 -n 1 -P 4 bash -exo pipefail -c 'for arg do [ -f "$arg" ] \
        && [[ $arg == *.torrent ]] \
        && echo "Copying $arg" \
        && scp -F "$SSH_CONF" -B "$arg" seedbox:/home/"$SEEDBOX_USER"/twatch/ \
        && echo "Done copying. Starting download wait..." \
        && ./wait_and_download.sh "$arg" \
        && rm "$arg" \
        && echo "Done downloading. Removed $arg."; done' _
