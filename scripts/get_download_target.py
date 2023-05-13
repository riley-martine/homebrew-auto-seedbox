#!/opt/homebrew/bin/python3.11
"""Get the top-level directory or file inside the torrent to look for to download."""

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

info = libtorrent.torrent_info(torrent_file.resolve().as_posix())
paths = [file.path for file in info.files()]

# Assume everything either has one dir containing everything,
# or one file w/o a dir

chunked_paths = [pathlib.Path(p).parts for p in paths]
if len(["x" for parts in chunked_paths if not len(parts) > 1]) > 1:
    print(chunked_paths, file=sys.stderr)
    raise NotImplementedError("Expected at most one top level file.")

if len({len(parts) > 1 for parts in chunked_paths}) != 1:
    print(chunked_paths, file=sys.stderr)
    raise NotImplementedError("Both a top-level directory and file exist.")

print(chunked_paths[0][0])
