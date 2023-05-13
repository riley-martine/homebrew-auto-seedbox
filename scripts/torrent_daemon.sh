#!/bin/bash

# Watch downloads dir for torrents, then execute upload script.

set -euxo pipefail

trap '{ echo Exited daemon, code $?; exit $?; }' EXIT
echo "Started daemon."
date
ssh-add --apple-load-keychain

source ./set_vars.sh

# TODO add temporary disable
# TODO figure out why fswatch sometimes seems to fire two events
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
