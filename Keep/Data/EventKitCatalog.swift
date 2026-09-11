@preconcurrency import EventKit
import Foundation
import os

/// EventKit lives here only. One `EKEventStore` per catalog / app session.
/// `@preconcurrency` is required for Swift 6 on Xcode 16.4: access APIs are nonisolated.
@MainActor
protocol CalendarCataloging: AnyObject {
    func currentAccess() -> (events: CalendarAccess, reminders: CalendarAccess)
    func requestAccess() async -> (events: CalendarAccess, reminders: CalendarAccess, error: String?)
    func loadSnapshot(at now: Date) async -> CalendarSnapshot
    func startObservingChanges(_ handler: @escaping @MainActor () async -> Void)
}

@MainActor
final class EventKitCatalog: CalendarCataloging {
    static let reminderFetchTimeout: TimeInterval = 2

    private let store: EKEventStore
    private let reminderTimeout: TimeInterval
    private var observer: NSObjectProtocol?

    init(store: EKEventStore = EKEventStore(), reminderTimeout: TimeInterval = reminderFetchTimeout) {
        self.store = store
        self.reminderTimeout = reminderTimeout
    }

    func currentAccess() -> (events: CalendarAccess, reminders: CalendarAccess) {
        (
            events: Self.map(EKEventStore.authorizationStatus(for: .event)),
            reminders: Self.map(EKEventStore.authorizationStatus(for: .reminder))
        )
    }

    func requestAccess() async -> (events: CalendarAccess, reminders: CalendarAccess, error: String?) {
        var errorText: String?
        do {
            _ = try await store.requestFullAccessToEvents()
        } catch {
            errorText = error.localizedDescription
            KeepLog.calendar.error("Event access failed: \(error.localizedDescription, privacy: .public)")
        }
        do {
            _ = try await store.requestFullAccessToReminders()
        } catch {
            errorText = error.localizedDescription
            KeepLog.calendar.error("Reminders access failed: \(error.localizedDescription, privacy: .public)")
        }
        let access = currentAccess()
        return (access.events, access.reminders, errorText)
    }

    func loadSnapshot(at now: Date) async -> CalendarSnapshot {
        let access = currentAccess()
        var events: [CalendarOccurrence] = []
        var reminders: [ReminderOccurrence] = []
        if access.events.canRead {
            events = loadOccurrences(at: now)
        }
        var remindersTimedOut = false
        if access.reminders.canRead {
            switch await loadReminders(at: now) {
            case .drafts(let drafts):
                reminders = drafts.compactMap { draft in
                    guard let due = draft.due else { return nil }
                    return ReminderOccurrence(title: draft.title, due: due)
                }
            case .timedOut:
                remindersTimedOut = true
                KeepLog.calendar.error("Reminder fetch timed out")
            }
        }
        return CalendarSnapshot(
            eventsAccess: access.events,
            remindersAccess: access.reminders,
            events: events,
            reminders: reminders,
            remindersTimedOut: remindersTimedOut
        )
    }

    func startObservingChanges(_ handler: @escaping @MainActor () async -> Void) {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { _ in
            Task { @MainActor in await handler() }
        }
    }

    private func loadOccurrences(at now: Date) -> [CalendarOccurrence] {
        let start = now.addingTimeInterval(-NextMemoryPolicy.inProgressLookback)
        let end = now.addingTimeInterval(NextMemoryPolicy.lookahead)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map(Self.occurrence(from:))
    }

    private func loadReminders(at now: Date) async -> ReminderLoad {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: now.addingTimeInterval(-NextMemoryPolicy.incompleteReminderLookback),
            ending: now.addingTimeInterval(NextMemoryPolicy.incompleteReminderLookahead),
            calendars: nil
        )
        return await fetchReminderDrafts(matching: predicate)
    }

    /// Copies EventKit values on the fetch callback queue into Sendable drafts. Never sends `EKReminder`.
    private func fetchReminderDrafts(matching predicate: NSPredicate) async -> ReminderLoad {
        await withCheckedContinuation { continuation in
            let gate = ReminderFetchGate()
            let timeout = DispatchWorkItem {
                gate.complete(.timedOut, continuation)
            }
            store.fetchReminders(matching: predicate) { items in
                timeout.cancel()
                let mapped = (items ?? []).map { reminder in
                    ReminderDraft(title: reminder.title ?? "", due: reminder.dueDateComponents?.date)
                }
                gate.complete(.drafts(mapped), continuation)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + reminderTimeout, execute: timeout)
        }
    }

    static func occurrence(from event: EKEvent) -> CalendarOccurrence {
        let declined = event.attendees?.contains(where: {
            $0.isCurrentUser && $0.participantStatus == .declined
        }) ?? false
        return CalendarOccurrence(
            title: event.title ?? "",
            start: event.startDate,
            end: event.endDate,
            isAllDay: event.isAllDay,
            isCancelled: event.status == .canceled,
            currentUserDeclined: declined
        )
    }

    static func map(_ status: EKAuthorizationStatus) -> CalendarAccess {
        switch status {
        case .fullAccess, .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .writeOnly:
            return .writeOnly
        @unknown default:
            return .denied
        }
    }
}

