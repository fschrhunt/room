<p align="center">
  <picture>
    <source srcset="assets/white/lockup.svg" media="(prefers-color-scheme: dark)">
    <source srcset="assets/black/lockup.svg" media="(prefers-color-scheme: light)">
    <img src="assets/black/lockup.svg" alt="room" height="48">
  </picture>
</p>
<p align="center">Mount SMB shares at login, the native way.</p>
<p align="center"><a href="https://github.com/fschrhunt/room/actions/workflows/ci.yml"><img src="https://github.com/fschrhunt/room/actions/workflows/ci.yml/badge.svg" alt="CI"></a></p>

---

`room` keeps an SMB share mounted on macOS. It registers the share, writes a
launchd agent for it, and brings it back after a restart, a wake, or a dropped
connection — using only what macOS already ships.

No kernel extension, no FUSE, no Apple Developer account.

## Why

Mounting a network share on macOS usually means choosing between a Finder login
item that silently fails, a filesystem extension that needs signing and
notarization, or a third-party helper. `room` leans on the parts macOS already
trusts:

- **launchd** runs the agent at login and once a minute, scoped to the GUI session.
- **Finder's `mount volume`** mounts the share with the login keychain credential —
  the same code path as Finder, so nothing new is trusted and the volume behaves
  like any other.
- **`nc`** gates each attempt on the host answering SMB, so a VPN that comes up
  after login doesn't produce a burst of failed mounts.

## Install

With Homebrew (the repository is its own tap):

```sh
brew tap fschrhunt/room https://github.com/fschrhunt/room && brew install room
```

Or with the installer, which checks the latest release against its checksums:

```sh
curl -fsSL https://raw.githubusercontent.com/fschrhunt/room/main/install.sh | sh
```

Or drop `bin/room` anywhere on your `PATH`:

```sh
git clone https://github.com/fschrhunt/room.git
install -m 755 room/bin/room ~/.local/bin/room
```

Requires macOS and write access to `~/.local/bin`, `~/Library/LaunchAgents`, and
`~/Library/Logs`.

## Use

```sh
room add smb://user@server.local/Share
```

`room add` writes the config and the launchd agent, loads it, then mounts the
share once. That first mount runs in your session, so Finder can ask for the
password and remember it in the keychain. From then on the agent keeps it
mounted, including after a restart or a wake.

Run `room` with no arguments for status, or `room doctor` for a full check.
`room add` is safe to re-run.

```sh
room status            # mount and agent state
room doctor            # check config, agent, server and keychain
room logs              # the log
room mount             # mount now
room unmount           # unmount now
room remove            # unload the agent, unmount, forget the share
room uninstall         # remove room entirely
```

## How it works

For each share, `room` writes a small config and a per-share launchd agent, then
lets Finder do the mounting.

| What | Where |
| --- | --- |
| Config | `~/.config/room/config` |
| Agent | `~/Library/LaunchAgents/room.plist` (label `room`) |
| Log | `~/Library/Logs/room.log` |
| Path | `~/room`, a symlink to the mounted share |

The agent runs `room agent`, which waits for the host, clears a stale
mount point left by an unclean unmount, and retries the mount a few times. It is
safe to run every minute.

## Limitations

- macOS only. The mount itself is Finder's, by design.
- The first `room add` needs a logged-in session so Finder can prompt for the
  password. Adding a share over SSH? Connect once in Finder to seed the keychain.
- room manages one share.
- Each share appears under **Allow in the Background** in System Settings →
  General → Login Items & Extensions. Turning it off stops the mount.

## License

MIT
