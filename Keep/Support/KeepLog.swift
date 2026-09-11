import Foundation
import os

enum KeepLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app.keep.desktop"

    static let wallpaper = Logger(subsystem: subsystem, category: "wallpaper")
    static let calendar = Logger(subsystem: subsystem, category: "calendar")
    static let weather = Logger(subsystem: subsystem, category: "weather")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let session = Logger(subsystem: subsystem, category: "session")
    static let power = Logger(subsystem: subsystem, category: "power")

    /// Wallpaper display link transitions. Never emit from `FrameClock.step`.
    static let wallpaperSignpost = OSSignposter(subsystem: subsystem, category: "wallpaper")
    /// One interval per weather HTTP attempt. No coordinates.
    static let weatherSignpost = OSSignposter(subsystem: subsystem, category: "weather")
}
