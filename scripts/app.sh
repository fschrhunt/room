#!/bin/sh
# app: build Room.app. The room agent names it (AssociatedBundleIdentifiers), so
# System Settings lists the agent as Room with this icon. Opened at login, the app
# runs one `room agent` pass, then stays running with no timer and runs another
# each time the Mac wakes or a volume unmounts, so the share comes back on its own.
# It reads the same config, so set the share up with `room add` first. The icon is compiled from assets/room.icon with Xcode's actool, so this
# needs Xcode.
#
#   scripts/app.sh [DEST]   build to DEST (default ~/Applications/Room.app)
set -eu
cd "$(dirname "$0")/.."
dest=${1:-$HOME/Applications/Room.app}
command -v xcrun >/dev/null 2>&1 || {
  echo "app: needs Xcode (xcrun actool)" >&2
  exit 1
}
version=$(sed -n 's/^VERSION="\(.*\)"$/\1/p' bin/room)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
app="$work/Room.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

xcrun actool assets/room.icon --compile "$app/Contents/Resources" \
  --platform macosx --minimum-deployment-target 13.0 --app-icon room \
  --output-partial-info-plist "$work/icon.plist" >/dev/null

cat >"$app/Contents/MacOS/Room" <<'EOF'
#!/bin/sh
# Room.app's entry: start the watcher and stay its parent, so the process is named Room.
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH
/usr/bin/osascript -l JavaScript "$(dirname "$0")/../Resources/watch.js" &
trap 'kill $! 2>/dev/null' INT TERM
wait
EOF
chmod 755 "$app/Contents/MacOS/Room"

cat >"$app/Contents/Resources/watch.js" <<'EOF'
// Room.app's watcher: one `room agent` pass now, then one each time the Mac wakes or a
// volume unmounts. It waits in the run loop between events, so nothing runs on a timer;
// each pass runs in the background, and room's lock keeps overlapping events from stacking.
ObjC.import('Cocoa');
function pass() {
  $.NSTask.launchedTaskWithLaunchPathArguments('/bin/sh', $(['-c', 'exec room agent >/dev/null 2>&1']));
}
ObjC.registerSubclass({
  name: 'RoomWatcher',
  methods: { 'fire:': { types: ['void', ['id']], implementation: pass } },
});
const watcher = $.RoomWatcher.alloc.init;
const center = $.NSWorkspace.sharedWorkspace.notificationCenter;
[$.NSWorkspaceDidWakeNotification, $.NSWorkspaceDidUnmountNotification].forEach(function (name) {
  center.addObserverSelectorNameObject(watcher, 'fire:', name, $());
});
pass();
$.NSRunLoop.currentRunLoop.run;
EOF

cat >"$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Room</string>
  <key>CFBundleIdentifier</key><string>sh.room.app</string>
  <key>CFBundleName</key><string>Room</string>
  <key>CFBundleDisplayName</key><string>Room</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${version}</string>
  <key>CFBundleVersion</key><string>${version}</string>
  <key>CFBundleIconName</key><string>room</string>
  <key>CFBundleIconFile</key><string>room</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

codesign --force --sign - "$app" >/dev/null
rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
ditto "$app" "$dest"
echo "built $dest ($version)"
