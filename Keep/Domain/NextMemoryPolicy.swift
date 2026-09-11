import Foundation

enum CalendarAccess: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
    case restricted
    case writeOnly

    var canRead: Bool { self == .granted }

    /// `requestFullAccess` can return false while `authorizationStatus` still says granted.
    static func afterPrompt(success: Bool, status: CalendarAccess) -> CalendarAccess {
        if success {
            return status.canRead ? status : .granted
        }
        if status == .restricted { return .restricted }
        if status == .writeOnly { return .writeOnly }
        return .denied
    }

    /// Prefer a fresh live deny. Keep a probed deny when the process status is still stale granted.
    static func combining(live: CalendarAccess, probed: CalendarAccess?) -> CalendarAccess {
        guard let probed else { return live }
        if !live.canRead { return live }
        if !probed.canRead { return probed }
        return live
    }
}

/// EventKit free snapshot of one calendar event. Only fields Keep displays or filters on.
struct CalendarOccurrence: Equatable, Sendable {
    var title: String
    var start: Date
    var end: Date
    var isAllDay: Bool
    var isCancelled: Bool
    var currentUserDeclined: Bool

    var isReadable: Bool { !isCancelled && !currentUserDeclined }
}

struct ReminderOccurrence: Equatable, Sendable {
    var title: String
    var due: Date
}

struct CalendarSnapshot: Equatable, Sendable {
    var eventsAccess: CalendarAccess
    var remindersAccess: CalendarAccess
    var events: [CalendarOccurrence]
    var reminders: [ReminderOccurrence]
    /// Distinct from an empty reminder list. EventKit did not finish in time.
    var remindersTimedOut: Bool = false

    static func empty(eventsAccess: CalendarAccess, remindersAccess: CalendarAccess) -> CalendarSnapshot {
        CalendarSnapshot(
            eventsAccess: eventsAccess,
            remindersAccess: remindersAccess,
            events: [],
            reminders: []
        )
    }
}

/// Keep product policy for “next memory.” Not an EventKit or Apple rule.
/// Reference time is always the `now` argument, never a hidden wall clock.
enum NextMemoryPolicy {
    /// Keep policy: how long an in progress timed event stays eligible.
    static let inProgressLookback: TimeInterval = .hours(12)
    /// Keep policy: timed events starting after this are ignored.
    static let lookahead: TimeInterval = .hours(36)
    /// Keep policy: incomplete reminders due in the last seven days stay in the fetch window.
    static let incompleteReminderLookback: TimeInterval = .days(7)
    /// Keep policy: incomplete reminders due in the next day stay in the fetch window.
    static let incompleteReminderLookahead: TimeInterval = .days(1)
    /// Fallback length of one calendar day when Calendar cannot add a day.
    static let calendarDay: TimeInterval = .days(1)
    /// Keep policy: timed events starting within this window beat overdue reminders.
    static let imminentHorizon: TimeInterval = .minutes(30)
    /// Keep policy: timed events that started this recently still count as imminent.
    static let imminentLookback: TimeInterval = .minutes(5)

    static func select(_ snapshot: CalendarSnapshot, at now: Date, calendar: Calendar = .current) -> MemoryItem? {
        let event = snapshot.eventsAccess.canRead ? nextEvent(in: snapshot.events, at: now, calendar: calendar) : nil
        let reminder = snapshot.remindersAccess.canRead ? nextReminder(in: snapshot.reminders, at: now) : nil

        if let event, isImminentTimed(event, at: now) {
            return event
        }
        if let reminder, reminder.date <= now {
            return reminder
        }
        return event ?? reminder
    }

    private static func nextEvent(in events: [CalendarOccurrence], at now: Date, calendar: Calendar) -> MemoryItem? {
        let timed = events
            .filter { $0.isReadable && !$0.isAllDay }
            .filter { $0.end > now }
            .filter { $0.start >= now.addingTimeInterval(-inProgressLookback) }
            .filter { $0.start <= now.addingTimeInterval(lookahead) }
            .sorted { $0.start < $1.start }

        if let first = timed.first {
            return MemoryItem(
                kind: .event,
                title: displayTitle(first.title, fallback: "Event"),
                date: first.start,
                isAllDay: false
            )
        }

        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now.addingTimeInterval(calendarDay)
        let allDay = events
            .filter { $0.isReadable && $0.isAllDay }
            .filter { $0.start < dayEnd && $0.end > dayStart }
            .sorted { $0.start < $1.start }

        if let first = allDay.first {
            return MemoryItem(
                kind: .event,
                title: displayTitle(first.title, fallback: "Today"),
                date: first.start,
                isAllDay: true
            )
        }
        return nil
    }

    private static func nextReminder(in reminders: [ReminderOccurrence], at now: Date) -> MemoryItem? {
        reminders
            .sorted { $0.due < $1.due }
            .first
            .map {
                MemoryItem(
                    kind: .reminder,
                    title: displayTitle($0.title, fallback: "Reminder"),
                    date: $0.due
                )
            }
    }

    private static func isImminentTimed(_ item: MemoryItem, at now: Date) -> Bool {
        guard item.kind == .event, !item.isAllDay else { return false }
        return item.isImminent(at: now)
    }

    private static func displayTitle(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
