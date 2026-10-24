// Room's Finder Sync extension. Watching the share's mount point is all Finder needs to show Room's
// symbol (CFBundleSymbolName in Room.app's Info.plist) on that folder's sidebar row; the extension
// adds no badges, menus or toolbar items. The path is RoomVolume in this extension's Info.plist,
// written when the app is built, because the sandbox keeps it from reading room's config.
import FinderSync

final class Sidebar: FIFinderSync {
    override init() {
        super.init()
        if let path = Bundle.main.object(forInfoDictionaryKey: "RoomVolume") as? String {
            FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: path)]
        }
    }
}
