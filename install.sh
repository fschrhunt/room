#!/bin/sh
# Installs room from its GitHub release: the source archive for this version,
# checked against the release's checksums, into ~/.local/bin (or $ROOM_INSTALL_DIR).
# Run it again to update.
#
#   curl -fsSL https://raw.githubusercontent.com/fschrhunt/room/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/fschrhunt/room/main/install.sh | sh -s -- --version v0.1.0
#
# $ROOM_RELEASES replaces https://github.com/fschrhunt/room/releases, for testing.
set -eu

releases=${ROOM_RELEASES:-https://github.com/fschrhunt/room/releases}
dir=${ROOM_INSTALL_DIR:-$HOME/.local/bin}
version=${ROOM_VERSION:-}

fail() {
  echo "room install: $*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case $1 in
  --version)
    [ $# -ge 2 ] || fail "--version needs a version, like v0.1.0"
    version=$2
    shift 2
    ;;
  --version=*)
    version=${1#--version=}
    shift
    ;;
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
    # Printed here, not read from $0: under curl | sh, $0 is not this file.
    cat <<'EOF'
usage: install.sh [--version vX.Y.Z] [--dir DIR]
Installs room from its GitHub release into ~/.local/bin, or DIR, or $ROOM_INSTALL_DIR.
Run it again to update. $ROOM_RELEASES replaces the release host, for testing.
EOF
    exit 0
    ;;
  *) fail "unknown option $1; options: --version vX.Y.Z, --dir DIR" ;;
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

# Resolve the latest tag from where releases/latest redirects.
if [ -z "$version" ]; then
  if command -v curl >/dev/null 2>&1; then
    landing=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$releases/latest") || fail "could not reach $releases"
  else
    landing=$(wget -q --max-redirect=5 --server-response --spider "$releases/latest" 2>&1 | sed -n 's/^ *[Ll]ocation: *//p' | tail -1 | tr -d '\r')
  fi
  version=${landing##*/}
fi
case $version in
v[0-9]*.[0-9]*.[0-9]*) ;;
[0-9]*.[0-9]*.[0-9]*) version=v$version ;;
*) fail "could not tell the latest version from $releases (got \"$version\")" ;;
esac
plain=${version#v}

tmp=$(mktemp -d "${TMPDIR:-/tmp}/room-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
fetch "$releases/download/$version/room-$plain.tar.gz" "$tmp/room.tar.gz"
fetch "$releases/download/$version/checksums.txt" "$tmp/checksums.txt"

expected=$(sed -n "s/^\([0-9a-f]\{64\}\)  *room-$plain\.tar\.gz\$/\1/p" "$tmp/checksums.txt")
[ -n "$expected" ] || fail "checksums.txt has no entry for room-$plain.tar.gz"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmp/room.tar.gz" | cut -d' ' -f1)
else
  actual=$(shasum -a 256 "$tmp/room.tar.gz" | cut -d' ' -f1)
fi
[ "$actual" = "$expected" ] || fail "checksum mismatch for room-$plain.tar.gz"

mkdir -p "$tmp/extract" "$dir"
tar -xzf "$tmp/room.tar.gz" -C "$tmp/extract"
src="$tmp/extract/room-$plain/room"
[ -f "$src" ] || fail "archive does not contain room-$plain/room"
cp "$src" "$dir/room"
chmod 755 "$dir/room"

echo "room installed: $dir/room"
case :$PATH: in
*:"$dir":*) ;;
*) echo "add $dir to PATH to run 'room'" ;;
esac
