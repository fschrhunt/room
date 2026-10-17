# room development context

- Product: mount SMB shares at login on macOS without a kernel extension, FUSE,
  or Apple Developer account. launchd runs the agent; Finder's `mount volume`
  mounts the share using the login keychain. Keep the surface small and the
  implementation in POSIX `sh` — this is glue over macOS, not an app.
- Single binary: `bin/room` is both the CLI and the launchd entry point
  (`room agent <name>`). Config is `~/.config/room/shares/<name>`, agents are
  `~/Library/LaunchAgents/room.<name>.plist`, logs are
  `~/Library/Logs/room.<name>.log`.
- Onboarding is part of the product: `room add` must write config, install and
  load the agent, then mount once interactively so the keychain gets seeded.
  Never make a background agent responsible for first-time authentication.
- Do not claim more than is verified. The mount path is Finder's; test the agent
  logic with stubbed binaries (`tests/run`), not by asserting macOS behavior.
- Secrets stay in the login keychain. Never accept a password in a URL or write
  one to config or logs.
- Verify with `./x check` (shellcheck, shfmt, tests). Keep changes small, follow
  the existing 2-space shell style, and update every comment/doc a change touches.
