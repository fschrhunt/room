#!/bin/sh
# One repository entry point. Local checks and CI run the same commands, so no
# environment has a private definition of "green".
set -eu
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
usage: ./x [command] [args...]
  check              Default; shellcheck, shfmt, tests and the guards
  fmt [--check]      Format shell sources, or check without writing
  test               Run the tests only
  guard              Product and hygiene guards
  release-check TAG  Check a release tag against CHANGELOG.md
  help | --help | -h Show this help
EOF
}

fmt() {
  if [ "${1:-}" = "--check" ]; then
    if command -v shfmt >/dev/null 2>&1; then
      shfmt -d bin/room install.sh tests/run x scripts/*.sh
    else
      echo "x: shfmt not installed; skipping" >&2
    fi
  else
    command -v shfmt >/dev/null 2>&1 || {
      echo "x: shfmt not installed" >&2
      exit 1
    }
    shfmt -w bin/room install.sh tests/run x scripts/*.sh
  fi
}

check() {
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck bin/room install.sh tests/run x scripts/*.sh
  else
    echo "x: shellcheck not installed; skipping" >&2
  fi
  if command -v actionlint >/dev/null 2>&1; then
    actionlint .github/workflows/*.yml
  else
    echo "x: actionlint not installed; skipping" >&2
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
