# Changelog

## Unreleased

- Room.app keeps the share in Finder's sidebar under Favorites with Room's symbol,
  replacing SidebarFavorites: a Finder Sync extension inside the app supplies the
  symbol (Apple's folder with the Room mark, at the native folder icon's size),
  with no window and no second login item. Room.app is now a small Swift app built by `scripts/app.sh`.
- Room.app stays running after login and runs a pass each time the Mac wakes or a
  volume unmounts, so the share reconnects on its own after sleep, with no timer and
  no second login item. Ejecting the share brings it back; quit Room.app to keep it
  off.
- The mount check asks the server for the volume size instead of listing it. macOS
  blocks a background agent from listing a network volume, so every pass took a
  healthy share for dead and remounted it, breaking open files.
- The agent replaces a mount that stopped answering (after a server restart or a
  dropped connection) instead of treating any listed mount as healthy. The check
  is time-limited, so a dead mount no longer hangs it.
- The agent keeps the share at `/Volumes/Share`: it mounts onto a leftover mount
  point instead of letting Finder pick `/Volumes/Share-1`, and moves a share already
  at `-1` back when nothing has it open (following it while something does).
- Agent mounts go through NetFS with no UI, so a background pass can never raise a
  dialog; `room add` still mounts through Finder so it can ask for the password.
- The share is mounted soft, through a `[server:share]` section in
  `~/Library/Preferences/nsmb.conf`, so a dead server fails calls instead of
  hanging them; `room remove` drops it.
- A lock left by a killed agent pass now expires instead of stopping the agent.
- A pass that receives SIGTERM or SIGINT now exits and releases its lock, instead of
  carrying on without it.
- `room doctor` reports the soft mount only when the share's section sets `soft=yes`.
- `room remove` and `room uninstall` delete the `~/room` link room made, so none is
  left pointing at an unmounted share.
- Share names with spaces or other URL-unsafe characters are encoded in the mount URL,
  and `%XX` escapes in a URL are decoded, so `Public%20Files` and `Public Files` both
  mount at `/Volumes/Public Files`.
- `room add` refuses a second share, or a port in the URL, with a message, instead of
  adding a half-working setup.
- A probe that hangs on a dead mount no longer leaves its child process running.
- `install.sh --help` works under `curl | sh`.
- `Room.app` builds with share names containing `&`, `<`, `>` or `|`.
- The release checks accept a changelog heading without a date, as `release-notes.sh` does.
- `scripts/app.sh` builds `Room.app` from the Room icon; the agent names it, so
  System Settings lists the agent as Room.
- Checksum-pin shellcheck, shfmt and actionlint in `.github/infra-tools.json`
  instead of installing the latest of each with `brew`.

## v0.1.1 · 2026-10-17

- Homebrew: install the release archive correctly, and document the explicit
  tap URL the repository needs.

## v0.1.0 · 2026-10-17

- Initial release: `add`, `status`, `doctor`, `logs`, `mount`, `unmount`,
  `remove` and `uninstall`, managing one SMB share under the fixed `room`
  identity.
- launchd agent (label `room`) with host-reachability gating, stale-mountpoint
  cleanup and mount retries. The mount goes through Finder's `mount volume`, so
  the password stays in the login keychain.
- Homebrew formula `room.rb`; release archives carry checksums and build
  provenance.
