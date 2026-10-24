// Room.app: keeps room's share mounted and in Finder's sidebar, with no window, menu or Dock icon.
//
// At launch it runs one `room agent` pass and turns on the bundled Finder Sync extension, which
// gives the share's sidebar row Room's symbol. After each pass that leaves the share mounted, it
// makes sure the share is in Finder's Favorites. It then waits, with no timer, and runs another
// pass each time the Mac wakes or a volume unmounts; `room agent` holds its own lock, so
// overlapping events never stack passes. Mount logic stays in `room`; this app only triggers it.
import AppKit

/// The share's mount point, from room's config, so the app follows whatever `room add` set up.
let volume: String? = {
    let config = (NSHomeDirectory() as NSString).appendingPathComponent(".config/room/config")
    let text = (try? String(contentsOfFile: config, encoding: .utf8)) ?? ""
    return text.split(separator: "\n").first { $0.hasPrefix("volume=") }.map { String($0.dropFirst(7)) }
}()

/// True when `path` is itself a mount point. statfs never reads the share's contents, so it needs
/// no Network Volumes permission and never prompts.
func isMountPoint(_ path: String) -> Bool {
    var fs = statfs()
    guard statfs(path, &fs) == 0 else { return false }
    let mountedOn = withUnsafeBytes(of: fs.f_mntonname) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    return mountedOn == path
}

/// Runs one `room agent` pass in the background, then keeps the share in Finder's Favorites.
func runPass() {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", "exec room agent >/dev/null 2>&1"]
    var env = ProcessInfo.processInfo.environment
    env["PATH"] = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin")
    task.environment = env
    task.terminationHandler = { _ in DispatchQueue.main.async(execute: keepFavorite) }
    try? task.run()
}

/// Adds the share to the end of Finder's Favorites when it is mounted and missing. Only an existing
/// mount is added, so the row never points at a missing volume. LSSharedFileList is deprecated but
/// is still the only interface to the sidebar's Favorites. The row goes after the current last
/// item: the kLSSharedFileListItemLast marker is not a real object, and Swift crashes retaining it.
func keepFavorite() {
    guard let volume, isMountPoint(volume),
          let list = LSSharedFileListCreate(nil, kLSSharedFileListFavoriteItems.takeUnretainedValue(), nil)?
              .takeRetainedValue() else { return }
    var seed: UInt32 = 0
    let items = LSSharedFileListCopySnapshot(list, &seed)?.takeRetainedValue() as? [LSSharedFileListItem] ?? []
    let flags = UInt32(kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes)
    let present = items.contains { item in
        let url = LSSharedFileListItemCopyResolvedURL(item, flags, nil)?.takeRetainedValue() as URL?
        return url?.path == volume
    }
    if !present, let last = items.last {
        LSSharedFileListInsertItemURL(list, last, nil, nil, URL(fileURLWithPath: volume) as CFURL, nil, nil)
    }
}

/// Registers and enables the bundled Finder Sync extension; both steps are idempotent.
func enableSidebar() {
    guard let plugins = Bundle.main.builtInPlugInsURL else { return }
    let appex = plugins.appendingPathComponent("RoomSidebar.appex").path
    for args in [["-a", appex], ["-e", "use", "-i", "sh.room.app.sidebar"]] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = args
        try? task.run()
        task.waitUntilExit()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let center = NSWorkspace.shared.notificationCenter
for name in [NSWorkspace.didWakeNotification, NSWorkspace.didUnmountNotification] {
    center.addObserver(forName: name, object: nil, queue: .main) { _ in runPass() }
}
enableSidebar()
runPass()
app.run()
