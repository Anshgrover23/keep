import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Renders the production wallpaper view at pinned civil times. Used by tests and launch export. Not a product surface.
enum DayFilm {
    static let checkSize = CGSize(width: 640, height: 360)
    static let launchSize = CGSize(width: 1920, height: 1080)
    static let defaultStrideMinutes = 10
    static func weather(at date: Date, timeZone: TimeZone) -> WeatherKind {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 0..<4: return .clear
        case 4..<7: return .fog
        case 7..<11: return .cloudy
        case 11..<14: return .clear
        case 14..<17: return .rain
        case 17..<20: return .storm
        default: return .snow
        }
    }

    /// One launch still per weather kind at a time of day that reads well.
    static let heroHours: [(hour: Int, weather: WeatherKind)] = [
        (5, .fog),
        (8, .cloudy),
        (12, .clear),
        (15, .rain),
        (18, .storm),
        (22, .snow),
    ]

    static func civilDates(
        year: Int,
        month: Int,
        day: Int,
        strideMinutes: Int,
        timeZone: TimeZone
    ) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var cursor = DateComponents()
        cursor.year = year
        cursor.month = month
        cursor.day = day
        cursor.hour = 0
        cursor.minute = 0
        cursor.second = 0
        guard let start = calendar.date(from: cursor) else { return [] }
        let step = max(1, strideMinutes)
        let count = (24 * 60) / step
        return (0..<count).compactMap { calendar.date(byAdding: .minute, value: $0 * step, to: start) }
    }

    @MainActor
    static func render(session: AppSession, at date: Date, size: CGSize) -> CGImage? {
        session.clockAnchor = date
        session.clockPinnedAt = Date()
        session.refreshSolar(at: Date())
        let clock = FrameClock()
        let view = WallpaperRootView(
            session: session,
            clock: clock,
            sceneReadability: .socialPreview,
            showsMemoryOverlay: false
        )
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.scale = 1
        return renderer.cgImage
    }

    static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
}
