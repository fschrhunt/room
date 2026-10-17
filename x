#!/bin/sh
# Repository checks shared by contributors and CI. `check` never writes sources.
set -eu
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
usage: ./x [command]
  check   shellcheck + shfmt (when installed) + tests   (default)
  test    run tests only
  help    show this help
EOF
}

check() {
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck bin/room install.sh tests/run x
  else
    echo "x: shellcheck not installed; skipping" >&2
  fi
  if command -v shfmt >/dev/null 2>&1; then
    shfmt -d bin/room install.sh tests/run x
  else
    echo "x: shfmt not installed; skipping" >&2
  fi
  tests/run
}

cmd=${1:-check}
if [ "$#" -gt 0 ]; then shift; fi
case $cmd in
check) check ;;
test) tests/run ;;
help | --help | -h) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
