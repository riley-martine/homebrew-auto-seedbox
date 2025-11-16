#!/usr/bin/env python3
"""Print the 'file' metadata from a torrent file, where files are PDF or EPUB"""

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

info = libtorrent.torrent_info(torrent_file.resolve().as_posix())
paths = [file.path for file in info.files()]

epubs = [p for p in paths if p.endswith(".epub")]
if epubs:
    print("\n".join(epubs))
    sys.exit(0)

pdfs = [p for p in paths if p.endswith(".pdf")]
if pdfs:
    print("\n".join(pdfs))
    sys.exit(0)

sys.exit(1)
