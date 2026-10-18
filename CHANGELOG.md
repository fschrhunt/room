# Changelog

## Unreleased

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
