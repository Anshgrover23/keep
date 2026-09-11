import Foundation

struct MemoryItem: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case event
        case reminder
    }

    var kind: Kind
    var title: String
    var date: Date
    var isAllDay: Bool = false

    func caption(now: Date) -> String {
        if isAllDay {
            return "today"
        }
        let remaining = date.timeIntervalSince(now)
        if kind == .reminder && remaining <= 0 {
            return "due now"
        }
        if remaining <= 0 {
            return "now"
        }
        let minutes = Int(remaining / KeepTime.secondsPerMinute)
        if minutes < 1 {
            return "in a moment"
        }
        if minutes < KeepTime.minutesPerHour {
            return "in \(minutes) min"
        }
        let hours = minutes / KeepTime.minutesPerHour
        if hours < KeepTime.hoursPerDay {
            let mins = minutes % KeepTime.minutesPerHour
            if mins == 0 { return "in \(hours)h" }
            return "in \(hours)h \(mins)m"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return formatter.string(from: date)
    }

    func isImminent(at now: Date) -> Bool {
        if isAllDay { return false }
        let remaining = date.timeIntervalSince(now)
        return remaining <= NextMemoryPolicy.imminentHorizon
            && remaining > -NextMemoryPolicy.imminentLookback
    }
}

enum KeepTime {
    static let secondsPerMinute: TimeInterval = 60
    static let minutesPerHour = 60
    static let hoursPerDay = 24
    static let secondsPerHour: TimeInterval = secondsPerMinute * TimeInterval(minutesPerHour)
    static let secondsPerDay: TimeInterval = secondsPerHour * TimeInterval(hoursPerDay)
    static let minutesPerCivilDay = hoursPerDay * minutesPerHour
}

extension TimeInterval {
    static func minutes(_ count: Int) -> TimeInterval {
        TimeInterval(count) * KeepTime.secondsPerMinute
    }

    static func hours(_ count: Int) -> TimeInterval {
        TimeInterval(count) * KeepTime.secondsPerHour
    }

    static func days(_ count: Int) -> TimeInterval {
        TimeInterval(count) * KeepTime.secondsPerDay
    }
}
