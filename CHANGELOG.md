# Changelog

## 0.1.0

- Initial release: `add`, `list`, `status`, `logs`, `mount`, `unmount`, `remove`
  and `uninstall`.
- launchd agent per share with host reachability gating, stale-mountpoint
  cleanup and mount retries.
- Keychain-native mounting through Finder's `mount volume`; no signing,
  notarization, kernel extension or FUSE.
