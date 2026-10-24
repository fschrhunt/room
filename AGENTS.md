# room development context

- Product: mount SMB shares at login on macOS without a kernel extension, FUSE,
  or Apple Developer account. launchd runs the agent; Finder's `mount volume`
  mounts the share using the login keychain. Keep the surface small and the
  implementation in POSIX `sh` — this is glue over macOS, not an app.
- Single binary: `bin/room` is both the CLI and the launchd entry point
  (`room agent`). room manages one share under the fixed `room` identity: config
  `~/.config/room/config`, agent `~/Library/LaunchAgents/room.plist` (label
  `room`), log `~/Library/Logs/room.log`. Never introduce per-share names.
- `scripts/app.sh` builds the optional `Room.app` from `assets/room.icon`. The
  agent plist names it (`AssociatedBundleIdentifiers`) so System Settings shows
  the agent as Room. It stays a shell bundle whose only job is one `room agent`
  pass; never move mount logic into it.
- A mount counts only if it answers. Never touch the mount without a time limit
  (`within`, `responsive`): a dead SMB mount hangs any call into it. Find the
  share with `share_mountpoint`, never by assuming `/Volumes/<share>`.
- Onboarding is part of the product: `room add` must write config, install and
  load the agent, then mount once interactively so the keychain gets seeded.
  Never make a background agent responsible for first-time authentication.
- Do not claim more than is verified. The mount path is Finder's; test the agent
  logic with stubbed binaries (`tests/run`), not by asserting macOS behavior.
- Secrets stay in the login keychain. Never accept a password in a URL or write
  one to config or logs.
- Verify with `./x check` (pinned shellcheck, actionlint, shfmt, tests and
  `scripts/guard.sh`). Keep changes small, follow the existing 2-space shell
  style, add user-visible changes to CHANGELOG.md under `## Unreleased`, and
  update every comment/doc a change touches.
- Dependencies: Dependabot updates GitHub Actions and any future lockfile
  ecosystem added to `.github/dependabot.yml`; add a `deps.yml` only for bespoke
  lockfile updates. Lint tool versions and hashes live in
  `.github/infra-tools.json` and are installed by `scripts/tools.py`; bump both
  together.
