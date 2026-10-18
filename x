#!/bin/sh
# One repository entry point. Local checks and CI run the same commands, so no
# environment has a private definition of "green". Lint tools are checksum-pinned
# in .github/infra-tools.json; on a host with no pin (an Intel Mac) it falls back
# to a PATH install.
set -eu
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
usage: ./x [command] [args...]
  check              Default; shellcheck, actionlint, shfmt, tests and the guards
  fmt [--check]      Format shell sources, or check without writing
  test               Run the tests only
  guard              Product and hygiene guards
  release-check TAG  Check a release tag against CHANGELOG.md
  help | --help | -h Show this help
EOF
}

# Resolve a checksum-pinned tool; fall back to PATH only when the host is unpinned.
tool() {
  if ! command -v python3 >/dev/null 2>&1; then
    command -v "$1" 2>/dev/null || true
    return 0
  fi
  _rc=0
  _pinned=$(python3 scripts/tools.py ensure "$1") || _rc=$?
  if [ "$_rc" -ne 0 ]; then
    echo "x: could not install pinned $1" >&2
    return 1
  fi
  if [ -n "$_pinned" ]; then
    printf '%s' "$_pinned"
  else
    command -v "$1" 2>/dev/null || true
  fi
}

fmt() {
  _shfmt=$(tool shfmt)
  if [ -z "$_shfmt" ]; then
    if [ "${1:-}" = "--check" ]; then
      echo "x: shfmt unavailable; skipping" >&2
      return 0
    fi
    echo "x: shfmt unavailable" >&2
    exit 1
  fi
  if [ "${1:-}" = "--check" ]; then
    "$_shfmt" -d bin/room install.sh tests/run x scripts/*.sh
  else
    "$_shfmt" -w bin/room install.sh tests/run x scripts/*.sh
  fi
}

check() {
  _shellcheck=$(tool shellcheck)
  if [ -n "$_shellcheck" ]; then
    "$_shellcheck" bin/room install.sh tests/run x scripts/*.sh
  else
    echo "x: shellcheck unavailable; skipping" >&2
  fi
  _actionlint=$(tool actionlint)
  if [ -n "$_actionlint" ]; then
    "$_actionlint" .github/workflows/*.yml
  else
    echo "x: actionlint unavailable; skipping" >&2
  fi
  fmt --check
  tests/run
  scripts/guard.sh
}

release_check() {
  tag=${1:-}
  [ -n "$tag" ] || {
    usage >&2
    exit 2
  }
  printf '%s\n' "$tag" | grep -Eq '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || {
    echo "x: bad release tag: $tag" >&2
    exit 1
  }
  scripts/release-notes.sh "$tag" <CHANGELOG.md >/dev/null || {
    echo "x: CHANGELOG.md has no usable $tag section" >&2
    exit 1
  }
}

cmd=${1:-check}
if [ "$#" -gt 0 ]; then shift; fi
case $cmd in
check) check ;;
fmt) fmt "$@" ;;
test) tests/run ;;
guard) scripts/guard.sh ;;
release-check) release_check "$@" ;;
help | --help | -h) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
