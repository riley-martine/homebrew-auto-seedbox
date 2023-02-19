#!/bin/bash

# Wait for a specified torrent to be downloaded to the seedbox,
# then download it to ~/Downloads with rclone
set -euo pipefail

# https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746
function retry {
    local retries=$1
    shift

    local count=0
    until "$@"; do
        exit=$?
        wait=$((2 ** count))
        wait=$((wait < 30 ? wait : 30))
        count=$((count + 1))
        if [ "$count" -lt "$retries" ]; then
            echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
            sleep $wait
        else
            echo "Retry $count/$retries exited $exit, no more retries left."
            return $exit
        fi
    done
    return 0
}

TORRENT_NAME="$(./torrent_name.py "$1").torrent"

function is_complete {
    rclone --config "$RCLONE_CONF" lsjson \
        seedbox:/home/"$SEEDBOX_USER"/completed_torrents |
        jq -e --arg FILENAME "$TORRENT_NAME" '.[]|select(.Name == $FILENAME)' > /dev/null
}

echo "Waiting for $TORRENT_NAME to finish downloading to seedbox..."
retry 240 is_complete "$TORRENT_NAME"
echo "$TORRENT_NAME has completed download to seedbox. Downloading new torrents to local..."

rclone --config "$RCLONE_CONF" --max-age 24h --no-traverse copy \
    seedbox:/home/"$SEEDBOX_USER"/twatch_out/ ~/Downloads
echo "Done downloading new torrents."

function send_epubs {
    set -x
    for epub in $(./get_torrent_epub_files.py "$1"); do
        ./copy_to_kindle.sh "$HOME/Downloads/$epub"
    done
    set +x
}

# Don't care that much if it fails
# Which it might, if kindle is offline, which it often is!
retry 20 send_epubs "$1" || echo "Failed to send epubs."
