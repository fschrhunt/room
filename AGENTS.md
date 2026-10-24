# room development context

- Product: mount SMB shares at login on macOS without a kernel extension, FUSE,
  or Apple Developer account. launchd runs the agent; it mounts through NetFS
  (Finder's framework, from `osascript -l JavaScript`) with no UI, using the login
  keychain. `room add` mounts once through Finder's `mount volume` so it can prompt. Keep the surface small and the
  implementation in POSIX `sh` — this is glue over macOS. The one exception is
  the small Swift `Room.app` in `app/`.
- Single binary: `bin/room` is both the CLI and the launchd entry point
  (`room agent`). room manages one share under the fixed `room` identity: config
  `~/.config/room/config`, agent `~/Library/LaunchAgents/room.plist` (label
  `room`), log `~/Library/Logs/room.log`. Never introduce per-share names.
- `scripts/app.sh` builds the optional `Room.app` from `app/` with `swiftc` and
  `actool`, signed ad hoc. The agent plist names it (`AssociatedBundleIdentifiers`)
  so System Settings shows the agent as Room. `app/Room/main.swift` runs a
  `room agent` pass at start and on each wake or unmount event, never on a timer,
  and keeps the mounted share in Finder's Favorites. `app/Sidebar` is a Finder
  Sync extension that only watches the mount point; that is what makes Finder show
  the `room.sidebar` symbol on the row. Never move mount logic into the app, and
  never touch the volume icon. `scripts/symbol.py` generates the symbol from
  `assets/sidebar.svg` at the native `folder` symbol's exact size; edit the SVG,
  not the generated template.
- A mount counts only if it answers. Never touch the mount without a time limit
  (`within`, `responsive`): a dead SMB mount hangs any call into it. Find the
  share with `share_mountpoint`, never by assuming `/Volumes/<share>`.
- Onboarding is part of the product: `room add` must write config, install and
  load the agent, then mount once interactively so the keychain gets seeded.
  Never make a background agent responsible for first-time authentication.
- Do not claim more than is verified. The mount path is macOS's (NetFS and Finder); test the agent
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
