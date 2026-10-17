# room

Mount SMB shares at login on macOS, the native way.

`room` registers a share, writes a launchd agent for it, and keeps it mounted:
the agent waits for the host to answer, then asks Finder (`mount volume`) to mount
the share, so the password comes from the login keychain and the volume behaves
like any other. No kernel extension, no FUSE, no Apple Developer account.

## Why

Mounting a network share on macOS "natively" normally means choosing between a
Finder login item that silently fails, a kernel/filesystem extension that needs
signing and notarization, or a third-party helper. `room` uses the pieces macOS
already ships and already trusts:

- **launchd** runs the agent at login and every minute, scoped to the GUI session.
- **Finder's `mount volume`** mounts the share using the login keychain, the same
  code path as Finder itself, so there is nothing new to trust.
- **`nc`** gates each attempt on the host answering SMB, so a VPN that comes up
  after login does not produce a burst of failed mounts.

## Requirements

- macOS.
- An SMB server reachable from this Mac (LAN, VPN or Tailscale).
- Write access to `~/.local/bin`, `~/Library/LaunchAgents` and `~/Library/Logs`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/fschrhunt/room/main/install.sh | sh
```

Or copy `bin/room` anywhere on your `PATH`:

```sh
git clone https://github.com/fschrhunt/room.git
install -m 755 room/bin/room ~/.local/bin/room
```

## Use

```sh
room add smb://user@server.local/Share
room list
room status share
room logs share
```

`room add` writes the config and launchd agent, loads it, then mounts the share
once. That first mount runs in your session, so Finder can ask for the password
and remember it in the keychain. After that the agent keeps it mounted, including
after a restart or wake.

```sh
room remove share     # unload the agent, unmount, forget the share
room uninstall        # remove every share and agent
```

## How it works

- Config: `~/.config/room/shares/<name>`
- Agent: `~/Library/LaunchAgents/room.<name>.plist` (label `room.<name>`)
- Log: `~/Library/Logs/room.<name>.log`

The agent calls `room agent <name>`, which waits for the host, clears a stale
mount point left by an unclean unmount, and retries the mount a few times. It is
safe to run every minute.

## Limitations

- macOS only. The mount itself is Finder's, by design.
- The first `room add` needs a logged-in session so Finder can prompt for the
  password. If you add a share over SSH, connect once in Finder to seed the
  keychain.
- `room` mounts one share per agent; add several shares to get several agents.
- Adding a share records it under Allow in the Background in System Settings →
  General → Login Items & Extensions. Turning it off stops the mount.

## License

MIT
