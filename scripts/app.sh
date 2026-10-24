#!/bin/sh
# app: build Room.app. The room agent names it (AssociatedBundleIdentifiers), so
# System Settings lists the agent as Room with this icon; opening the app runs one
# `room agent` pass. It reads the same config, so set the share up with `room add`
# first. The icon is compiled from assets/room.icon with Xcode's actool, so this
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
# Room.app's entry: one `room agent` pass, so the share mounts at login without polling.
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
exec room agent
EOF
chmod 755 "$app/Contents/MacOS/Room"

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
