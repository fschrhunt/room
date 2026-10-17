#!/bin/sh
# Installs room from GitHub into ~/.local/bin (or $ROOM_INSTALL_DIR).
#
#   curl -fsSL https://raw.githubusercontent.com/fschrhunt/room/main/install.sh | sh
#
# Environment: ROOM_REPO (owner/name), ROOM_REF (branch/tag), ROOM_INSTALL_DIR.
set -eu

repo=${ROOM_REPO:-fschrhunt/room}
ref=${ROOM_REF:-main}
dir=${ROOM_INSTALL_DIR:-$HOME/.local/bin}
raw="https://raw.githubusercontent.com/$repo/$ref"

fail() {
  echo "room install: $*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case $1 in
  --dir)
    [ $# -ge 2 ] || fail "--dir needs a folder"
    dir=$2
    shift 2
    ;;
  --dir=*)
    dir=${1#--dir=}
    shift
    ;;
  -h | --help)
    sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *) fail "unknown option: $1" ;;
  esac
done

fetch() { # fetch URL FILE
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  else
    fail "needs curl or wget"
  fi
}

mkdir -p "$dir"
tmp="$dir/.room.$$"
fetch "$raw/bin/room" "$tmp" || fail "could not download $raw/bin/room"
chmod 755 "$tmp"
mv "$tmp" "$dir/room"

echo "room installed: $dir/room"
case :$PATH: in
*:"$dir":*) ;;
*) echo "add $dir to PATH to run 'room'" ;;
esac
