# Changelog

## 0.1.0

- Initial release: `add`, `status`, `logs`, `mount`, `unmount`, `remove` and
  `uninstall`, managing one share under the fixed `room` agent label.
- launchd agent per share with host reachability gating, stale-mountpoint
  cleanup and mount retries.
- Keychain-native mounting through Finder's `mount volume`; no signing,
  notarization, kernel extension or FUSE.
