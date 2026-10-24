#!/bin/sh
# guard: the rules AGENTS.md states, checked on every change. Each check pins one
# invariant; a change that moves a rule must move this script in the same diff.
set -eu
cd "$(dirname "$0")/.."
fail=0

bad() {
  printf 'guard: FAIL: %s\n' "$1" >&2
  fail=1
}

# 1. room is the product: no per-share names or naming flags anywhere in the CLI.
if grep -nE -- '--name|name_for|shares/|room\.\$' bin/room | grep .; then
  bad "per-share naming in bin/room"
fi

# 2. No personal identifiers in tracked example text.
if git grep -nE 'fschr@|100\.65\.' -- . ':(exclude)LICENSE' ':(exclude)scripts/guard.sh' | grep .; then
  bad "personal identifier in tracked files"
fi

# 3. bin/room only mounts: the sidebar row is Room.app's job, and neither touches the volume icon.
if grep -nE 'SidebarFavorites|Sidebar\.svg|VolumeIcon' bin/room | grep .; then
  bad "room must not touch sidebar favorites or the volume icon"
fi
if grep -rn 'VolumeIcon' app | grep .; then
  bad "Room.app must not touch the volume icon"
fi

# 4. Executables are exactly the scripts.
unexpected=$(git ls-files -s | awk '$1=="100755"{print $4}' | grep -vE '^(bin/room|install\.sh|tests/run|x|scripts/.*\.sh)$' || true)
[ -z "$unexpected" ] || bad "unexpected executable: $unexpected"
not_exec=$(git ls-files -s bin/room install.sh tests/run x | awk '$1!="100755"{print $4}')
[ -z "$not_exec" ] || bad "script not executable: $not_exec"

exit "$fail"
