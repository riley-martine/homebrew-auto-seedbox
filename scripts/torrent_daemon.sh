#!/bin/bash

# Watch downloads dir for torrents, then execute upload script.

set -euxo pipefail

trap '{ echo Exited daemon, code $?; exit $?; }' EXIT
echo "Started daemon."
date
ssh-add --apple-load-keychain

PATH="$(dirname "$0"):$PATH"
export PATH
source "$(dirname "$0")/set_vars.sh"

auto-seedbox
