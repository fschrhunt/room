# Changelog

## Unreleased

- Initial release: `add`, `status`, `doctor`, `logs`, `mount`, `unmount`,
  `remove` and `uninstall`, managing one SMB share under the fixed `room`
  identity.
- launchd agent (label `room`) with host-reachability gating, stale-mountpoint
  cleanup and mount retries. The mount goes through Finder's `mount volume`, so
  the password stays in the login keychain.
- Homebrew formula `room.rb`; release archives carry checksums and build
  provenance.
