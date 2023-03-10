#!/opt/homebrew/bin/python3.11
"""Print the 'name' metadata from a torrent file"""

# Needs to be brew python3.11 for libtorrent bindings

import pathlib
import sys
import warnings

import libtorrent

# libtorrent uses dunder methods for some things and we want clean output
warnings.filterwarnings("ignore", category=DeprecationWarning)

if len(sys.argv) != 2:
    print("Pass an argument.", file=sys.stderr)
    sys.exit(1)

torrent_file = pathlib.Path(sys.argv[1])
if not torrent_file.is_file():
    print(f"Cannot find file at: {torrent_file}", file=sys.stderr)
    sys.exit(1)

print(libtorrent.torrent_info(torrent_file.resolve().as_posix()).name())
