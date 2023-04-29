#!/bin/bash

# Requirements:
# Kindle must be running an SSH server on port 2323
# I used koreader for this.

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ]; then
    echo "Call me with an arg" >&2
    exit 1
fi
if [ ! -f "$FILE" ]; then
    echo "Error: $FILE is not a file that exists" >&2
    exit 1
fi
echo "Registered desire to copy $FILE to kindle..."

IP_FILE="$(brew --prefix)/var/cache/.prev_kindle_ip"
export IP_FILE

echo "Locating kindle..."
IP=''
if [ -f "$IP_FILE" ]; then
    IP="$(cat "$IP_FILE")"
fi

if [ -z "$IP" ] || ! nc -zv -G 2 "$IP" 2323 2> /dev/null; then
    echo "Cached IP does not exist or is not online, scanning network..."
    IP="$(nmap -p2323 -Pn -R --open -oG /dev/stdout 192.168.1.0/24 |
        rg --only-matching "Host: (192.168.1.\d+)" -r '$1' |
        head -n1)"
    echo "$IP" > "$IP_FILE"
fi
echo "Kindle found: $IP"

echo "Copying $FILE..."
# No password
SSH_ASKPASS_REQUIRE=force SSH_ASKPASS="echo" scp -o "StrictHostKeyChecking no" \
    "$1" "scp://root@${IP}:2323/../../../mnt/us/documents/"
echo "Done, file sent to kindle."
