# Changelog

## Unreleased

- The agent replaces a mount that stopped answering (after a server restart or a
  dropped connection) instead of treating any listed mount as healthy. The check
  is time-limited, so a dead mount no longer hangs it.
- room finds the share wherever Finder mounted it, such as `/Volumes/Share-1` when
  a leftover mount point holds the usual name, and repoints `~/room` there instead
  of failing every pass.
- The share is mounted soft, through a `[server:share]` section in
  `~/Library/Preferences/nsmb.conf`, so a dead server fails calls instead of
  hanging them; `room remove` drops it.
- A lock left by a killed agent pass now expires instead of stopping the agent.
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
