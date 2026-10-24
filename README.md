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
lets macOS's own mount path, NetFS (what Finder uses), do the mounting.

| What | Where |
| --- | --- |
| Config | `~/.config/room/config` |
| Agent | `~/Library/LaunchAgents/room.plist` (label `room`) |
| Log | `~/Library/Logs/room.log` |
| Path | `~/room`, a symlink to the mounted share |
| Soft mount | a `[server:share]` section in `~/Library/Preferences/nsmb.conf` |

The agent runs `room agent` at login and every minute. Each pass:

- **Checks that the mount still answers**, not just that it is listed. A mount
  whose server restarted or dropped the connection is unmounted and mounted again,
  but only while the server is reachable and a second, longer probe also fails, so
  a slow answer never costs you open files. Every probe is time-limited, so a dead
  mount never hangs the agent.
- **Keeps the share at `/Volumes/Share`.** A leftover mount point at that name is
  mounted onto directly, so the share never lands at `/Volumes/Share-1`. A share
  already at `-1` moves back when nothing has it open, and is followed, with
  `~/room` repointed, while something does.
- **Waits for the host**, then mounts with no UI and retries a few times, so a
  background pass never raises a dialog.

The share is mounted **soft**: when the server goes away, file calls fail after
about a minute instead of hanging for up to ten, so a dead mount can always be
replaced. `room remove` drops the section again.

## Room.app (optional)

`scripts/app.sh` builds `Room.app` from `assets/room.icon` (it needs Xcode for
`actool`) into `~/Applications`. The agent names it as its app, so System Settings
lists the agent as **Room** with its icon instead of a bare script. Opening the
app runs one `room agent` pass. It does not replace the agent: only the agent
notices a dropped connection and mounts the share again.

## Limitations

- macOS only. The mount uses NetFS, Finder's own framework, by design.
- The first `room add` needs a logged-in session so Finder can prompt for the
  password. Adding a share over SSH? Connect once in Finder to seed the keychain.
- room manages one share.
- Each share appears under **Allow in the Background** in System Settings →
  General → Login Items & Extensions. Turning it off stops the mount.
- A leftover mount point you own (the usual case) is reused. One that belongs to
  root cannot be; room then follows the share to `/Volumes/Share-1` until a restart
  clears the leftover.

## License

MIT
