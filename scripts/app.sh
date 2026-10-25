#!/bin/sh
# app: build Room.app from app/ (needs Xcode, for swiftc and actool). Room.app keeps the share
# mounted and in Finder's sidebar with Room's symbol, and reconnects after sleep or a drop; see
# app/Room/main.swift. It reads room's config, so set the share up with `room add` first.
#
#   scripts/app.sh [DEST]   build to DEST (default ~/Applications/Room.app)
set -eu
cd "$(dirname "$0")/.."
dest=${1:-$HOME/Applications/Room.app}
command -v xcrun >/dev/null 2>&1 || {
  echo "app: needs Xcode (swiftc and actool)" >&2
  exit 1
}
config=${XDG_CONFIG_HOME:-$HOME/.config}/room/config
volume=$(sed -n 's/^volume=//p' "$config" 2>/dev/null)
[ -n "$volume" ] || {
  echo "app: room is not set up; run: room add <smb://user@host/share>" >&2
  exit 1
}
version=$(sed -n 's/^VERSION="\(.*\)"$/\1/p' bin/room)
target=$(uname -m)-apple-macos13.0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
app=$work/Room.app
appex=$app/Contents/PlugIns/RoomSidebar.appex
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$appex/Contents/MacOS"

# Escape a value as XML text and as a sed replacement with | as the delimiter, so a share name
# holding &, <, > or | fills the templates intact.
xml_sed() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/[\\|]/\\&/g' -e 's/&/\\&/g'
}

# Fill a template's build-time values: the version and the share's mount point.
fill() { sed -e "s|__VERSION__|$version|g" -e "s|__VOLUME__|$(xml_sed "$volume")|g" "$1" >"$2"; }

# Compile one Swift target, showing swiftc's output only on failure: the app's deprecated
# LSSharedFileList calls are intentional, so their warnings are not news.
compile() {
  xcrun swiftc -O -target "$target" "$@" 2>"$work/swiftc.log" || {
    cat "$work/swiftc.log" >&2
    exit 1
  }
}
compile -module-name Room app/Room/main.swift -o "$app/Contents/MacOS/Room"
compile -module-name RoomSidebar -parse-as-library -application-extension \
  -Xlinker -e -Xlinker _NSExtensionMain app/Sidebar/Sidebar.swift -o "$appex/Contents/MacOS/RoomSidebar"

xcrun actool assets/room.icon app/Assets.xcassets --compile "$app/Contents/Resources" \
  --platform macosx --minimum-deployment-target 13.0 --app-icon room \
  --output-partial-info-plist "$work/assets.plist" >/dev/null

fill app/Room/Info.plist "$app/Contents/Info.plist"
fill app/Sidebar/Info.plist "$appex/Contents/Info.plist"
fill app/Sidebar/Sidebar.entitlements "$work/sidebar.entitlements"

# Sign ad hoc (no developer account needed): the sandboxed extension first, then the app around
# it. codesign always notes that it replaced the linker's signature, so its output shows only on failure.
sign() {
  codesign --force --sign - "$@" >"$work/codesign.log" 2>&1 || {
    cat "$work/codesign.log" >&2
    exit 1
  }
}
sign --entitlements "$work/sidebar.entitlements" "$appex"
sign "$app"
rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
ditto "$app" "$dest"
echo "built $dest ($version)"
