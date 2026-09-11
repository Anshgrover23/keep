import Foundation

/// Product weather state. HTTP strings stay on `WeatherFetching.lastError` for Lab.
enum WeatherStatus: String, Equatable, Sendable {
    case available
    case approximate
    case stale
    case unavailable

    /// Menu extra and Settings. Never HTTP status text.
    var extraLine: String? {
        switch self {
        case .available:
            return nil
        case .approximate:
            return "Weather is approximate"
        case .stale:
            return "Weather may be out of date"
        case .unavailable:
            return "Weather unavailable"
        }
    }

    /// Approximate is a time zone location, not an HTTP failure.
    static func resolve(
        lastUpdated: Date?,
        lastError: String?,
        fix: LocationFix
    ) -> WeatherStatus {
        if lastError != nil {
            return lastUpdated == nil ? .unavailable : .stale
        }
        if case .timeZone = fix {
            return .approximate
        }
        return lastUpdated == nil ? .unavailable : .available
    }
}

enum CalendarGlance: Equatable, Sendable {
    case upcoming(caption: String, title: String)
    case empty
    case notGranted
    case off

    static func resolve(
        wantsEvents: Bool,
        accessGranted: Bool,
        nextItem: MemoryItem?,
        now: Date
    ) -> CalendarGlance {
        guard wantsEvents else { return .off }
        if let nextItem {
            return .upcoming(caption: nextItem.caption(now: now), title: nextItem.title)
        }
        return accessGranted ? .empty : .notGranted
    }

    var emptyLine: String? {
        switch self {
        case .upcoming:
            return nil
        case .empty:
            return "Nothing upcoming. The day can stay quiet."
        case .notGranted, .off:
            return "Keep can show your next event from Calendar."
        }
    }
}
