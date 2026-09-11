import EventKit
import Foundation
import Testing
@testable import Keep

struct NextMemoryPolicyTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test func deniedAccessYieldsNoItemWithoutFabricatingEvents() {
        let event = occurrence(title: "Secret", start: 60, end: 120)
        let snapshot = CalendarSnapshot(
            eventsAccess: .denied,
            remindersAccess: .denied,
            events: [event],
            reminders: []
        )
        #expect(NextMemoryPolicy.select(snapshot, at: Date(timeIntervalSince1970: 0), calendar: calendar) == nil)
    }

    @Test func restrictedAndWriteOnlyCannotRead() {
        #expect(CalendarAccess.restricted.canRead == false)
        #expect(CalendarAccess.writeOnly.canRead == false)
        #expect(CalendarAccess.notDetermined.canRead == false)
        #expect(CalendarAccess.granted.canRead)
    }

    @Test func afterPromptTrustsFalseEvenWhenStatusStillSaysGranted() {
        #expect(CalendarAccess.afterPrompt(success: false, status: .granted) == .denied)
        #expect(CalendarAccess.afterPrompt(success: true, status: .granted) == .granted)
        #expect(CalendarAccess.combining(live: .granted, probed: .denied) == .denied)
        #expect(CalendarAccess.combining(live: .denied, probed: .denied) == .denied)
        #expect(CalendarAccess.combining(live: .granted, probed: .granted) == .granted)
    }

    @Test func emptyCalendarYieldsNoItem() {
        let snapshot = CalendarSnapshot.empty(eventsAccess: .granted, remindersAccess: .granted)
        #expect(NextMemoryPolicy.select(snapshot, at: Date(timeIntervalSince1970: 0), calendar: calendar) == nil)
    }

    @Test func oneUpcomingEventIsSelected() {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = granted(events: [
            occurrence(title: "Review", startOffset: .minutes(8), endOffset: .minutes(68), now: now)
        ])
        let item = NextMemoryPolicy.select(snapshot, at: now, calendar: calendar)
        #expect(item?.title == "Review")
        #expect(item?.kind == .event)
        #expect(item?.isAllDay == false)
    }

    @Test func earliestStartWinsAmongMultipleTimedEvents() {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = granted(events: [
            occurrence(title: "Later", startOffset: 3_600, endOffset: 7_200, now: now),
            occurrence(title: "Sooner", startOffset: 120, endOffset: 600, now: now)
        ])
        #expect(NextMemoryPolicy.select(snapshot, at: now, calendar: calendar)?.title == "Sooner")
    }

    @Test func eventsOutsideLookaheadAreIgnored() {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = granted(events: [
            occurrence(
                title: "Far",
                startOffset: NextMemoryPolicy.lookahead + 3_600,
                endOffset: NextMemoryPolicy.lookahead + 7_200,
                now: now
            )
        ])
        #expect(NextMemoryPolicy.select(snapshot, at: now, calendar: calendar) == nil)
    }

    @Test func inProgressEventStillQualifiesAfterTheOldFifteenMinuteLookback() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = granted(events: [
            occurrence(title: "Standup", startOffset: -.minutes(30), endOffset: .minutes(30), now: now)
        ])
        let item = NextMemoryPolicy.select(snapshot, at: now, calendar: calendar)
        #expect(item?.title == "Standup")
        #expect(item?.caption(now: now) == "now")
    }

    @Test func eventCrossingMidnightStaysCurrentAfterMidnight() {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 11
        parts.hour = 0
        parts.minute = 30
        let now = calendar.date(from: parts)!
        let start = now.addingTimeInterval(-.minutes(90))
        let end = now.addingTimeInterval(.minutes(90))
        let snapshot = granted(events: [
            CalendarOccurrence(
                title: "Launch",
                start: start,
                end: end,
                isAllDay: false,
                isCancelled: false,
                currentUserDeclined: false
            )
        ])
        let item = NextMemoryPolicy.select(snapshot, at: now, calendar: calendar)
        #expect(item?.title == "Launch")
        #expect(item?.date == start)
        #expect(item?.caption(now: now) == "now")
    }

    @Test func allDayEventUsedOnlyWhenNoTimedCandidate() {
        let now = Date(timeIntervalSince1970: 1_000)
        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let allDay = CalendarOccurrence(
            title: "Offsite",
            start: dayStart,
            end: dayEnd,
            isAllDay: true,
            isCancelled: false,
            currentUserDeclined: false
        )
        let timed = occurrence(title: "Call", startOffset: 600, endOffset: 1_200, now: now)
        #expect(NextMemoryPolicy.select(granted(events: [allDay, timed]), at: now, calendar: calendar)?.title == "Call")
        #expect(NextMemoryPolicy.select(granted(events: [allDay]), at: now, calendar: calendar)?.isAllDay == true)
    }

    @Test func cancelledAndDeclinedEventsAreExcluded() {
        let now = Date(timeIntervalSince1970: 1_000)
        let cancelled = occurrence(title: "X", startOffset: 60, endOffset: 120, now: now, cancelled: true)
        let declined = occurrence(title: "Y", startOffset: 60, endOffset: 120, now: now, declined: true)
        #expect(NextMemoryPolicy.select(granted(events: [cancelled, declined]), at: now, calendar: calendar) == nil)
    }

    @Test func blankTitleFallsBack() {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = granted(events: [
            occurrence(title: "   ", startOffset: 60, endOffset: 120, now: now)
        ])
        #expect(NextMemoryPolicy.select(snapshot, at: now, calendar: calendar)?.title == "Event")
    }

    @Test func overdueReminderBeatsNonImminentEvent() {
        let now = Date(timeIntervalSince1970: 1_000)
        let later = occurrence(title: "Tomorrow", startOffset: .hours(4), endOffset: .hours(5), now: now)
        let reminder = ReminderOccurrence(title: "Call Dad", due: now.addingTimeInterval(-.minutes(1)))
        let snapshot = CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .granted,
            events: [later],
            reminders: [reminder]
        )
        #expect(NextMemoryPolicy.select(snapshot, at: now, calendar: calendar)?.title == "Call Dad")
    }

    private func granted(events: [CalendarOccurrence], reminders: [ReminderOccurrence] = []) -> CalendarSnapshot {
        CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .granted,
            events: events,
            reminders: reminders
        )
    }

    private func occurrence(
        title: String,
        startOffset: TimeInterval,
        endOffset: TimeInterval,
        now: Date,
        cancelled: Bool = false,
        declined: Bool = false
    ) -> CalendarOccurrence {
        CalendarOccurrence(
            title: title,
            start: now.addingTimeInterval(startOffset),
            end: now.addingTimeInterval(endOffset),
            isAllDay: false,
            isCancelled: cancelled,
            currentUserDeclined: declined
        )
    }

    private func occurrence(title: String, start: TimeInterval, end: TimeInterval) -> CalendarOccurrence {
        occurrence(
            title: title,
            startOffset: start,
            endOffset: end,
            now: Date(timeIntervalSince1970: 0)
        )
    }
}

@MainActor
struct EventKitAuthorizationMappingTests {
    @Test func adapterMapsEventKitStatusesWithoutTreatingWriteOnlyAsRead() {
        #expect(EventKitCatalog.map(.fullAccess) == .granted)
        #expect(EventKitCatalog.map(.denied) == .denied)
        #expect(EventKitCatalog.map(.notDetermined) == .notDetermined)
        #expect(EventKitCatalog.map(.restricted) == .restricted)
        #expect(EventKitCatalog.map(.writeOnly) == .writeOnly)
        #expect(EventKitCatalog.map(.writeOnly).canRead == false)
    }
}

@MainActor
struct CalendarServiceBoundaryTests {
    @Test func deniedRefreshReturnsEmptyDomainResult() async {
        let catalog = FakeCatalog(
            eventsAccess: .denied,
            remindersAccess: .denied,
            snapshot: .empty(eventsAccess: .denied, remindersAccess: .denied)
        )
        catalog.snapshot.events = [
            CalendarOccurrence(
                title: "Should not leak",
                start: Date(),
                end: Date().addingTimeInterval(60),
                isAllDay: false,
                isCancelled: false,
                currentUserDeclined: false
            )
        ]
        let service = CalendarService(catalog: catalog, now: { Date(timeIntervalSince1970: 0) })
        await service.refresh()
        #expect(service.nextItem == nil)
        #expect(service.eventsGranted == false)
        #expect(service.accessGranted == false)
    }

    @Test func grantedEmptyCalendarIsEmptyNotAnError() async {
        let catalog = FakeCatalog(
            eventsAccess: .granted,
            remindersAccess: .granted,
            snapshot: .empty(eventsAccess: .granted, remindersAccess: .granted)
        )
        let service = CalendarService(catalog: catalog)
        await service.refresh()
        #expect(service.nextItem == nil)
        #expect(service.lastError == nil)
        #expect(service.eventsGranted)
    }

    @Test func grantedUpcomingEventBecomesMemoryItem() async {
        let now = Date(timeIntervalSince1970: 5_000)
        let start = now.addingTimeInterval(600)
        let catalog = FakeCatalog(
            eventsAccess: .granted,
            remindersAccess: .denied,
            snapshot: CalendarSnapshot(
                eventsAccess: .granted,
                remindersAccess: .denied,
                events: [
                    CalendarOccurrence(
                        title: "Design review",
                        start: start,
                        end: start.addingTimeInterval(1800),
                        isAllDay: false,
                        isCancelled: false,
                        currentUserDeclined: false
                    )
                ],
                reminders: []
            )
        )
        let service = CalendarService(catalog: catalog, now: { now })
        await service.refresh()
        #expect(service.nextItem?.title == "Design review")
        #expect(service.nextItem?.kind == .event)
    }

    @Test func refreshReReadsAuthorization() async {
        let catalog = FakeCatalog(
            eventsAccess: .denied,
            remindersAccess: .denied,
            snapshot: .empty(eventsAccess: .denied, remindersAccess: .denied)
        )
        let service = CalendarService(catalog: catalog)
        await service.refresh()
        #expect(service.eventsGranted == false)
        catalog.eventsAccess = .granted
        catalog.remindersAccess = .granted
        catalog.snapshot = CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .granted,
            events: [
                CalendarOccurrence(
                    title: "After grant",
                    start: Date().addingTimeInterval(120),
                    end: Date().addingTimeInterval(600),
                    isAllDay: false,
                    isCancelled: false,
                    currentUserDeclined: false
                )
            ],
            reminders: []
        )
        await service.refresh()
        #expect(service.eventsGranted)
        #expect(service.nextItem?.title == "After grant")
    }

    @Test func storeChangeNotificationTriggersRefresh() async {
        let catalog = FakeCatalog(
            eventsAccess: .granted,
            remindersAccess: .granted,
            snapshot: .empty(eventsAccess: .granted, remindersAccess: .granted)
        )
        let service = CalendarService(catalog: catalog)
        service.beginObservingStoreChanges()
        await service.refresh()
        let before = service.snapshotLoadCount
        catalog.snapshot = CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .granted,
            events: [
                CalendarOccurrence(
                    title: "From notification",
                    start: Date().addingTimeInterval(180),
                    end: Date().addingTimeInterval(900),
                    isAllDay: false,
                    isCancelled: false,
                    currentUserDeclined: false
                )
            ],
            reminders: []
        )
        await catalog.simulateStoreChange()
        #expect(service.snapshotLoadCount == before + 1)
        #expect(service.nextItem?.title == "From notification")
    }

    @Test func requestAccessUsesCatalogAndDoesNotSkipRefresh() async {
        let catalog = FakeCatalog(
            eventsAccess: .notDetermined,
            remindersAccess: .notDetermined,
            snapshot: .empty(eventsAccess: .notDetermined, remindersAccess: .notDetermined)
        )
        catalog.requestResult = (.granted, .denied, nil)
        catalog.eventsAccess = .granted
        catalog.snapshot = CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .denied,
            events: [
                CalendarOccurrence(
                    title: "After prompt",
                    start: Date().addingTimeInterval(90),
                    end: Date().addingTimeInterval(400),
                    isAllDay: false,
                    isCancelled: false,
                    currentUserDeclined: false
                )
            ],
            reminders: []
        )
        let service = CalendarService(catalog: catalog)
        await service.requestAccessAndRefresh()
        #expect(catalog.didRequestAccess)
        #expect(service.nextItem?.title == "After prompt")
        #expect(service.canRequestCalendarAccess == false)
    }

    @Test func canRequestCalendarAccessWhileEitherSideIsUndetermined() async {
        let catalog = FakeCatalog(
            eventsAccess: .notDetermined,
            remindersAccess: .denied,
            snapshot: .empty(eventsAccess: .notDetermined, remindersAccess: .denied)
        )
        let service = CalendarService(catalog: catalog)
        await service.refresh()
        #expect(service.canRequestCalendarAccess)
    }

    @Test func reminderTimeoutIsDistinctFromAnEmptyList() async {
        let now = Date(timeIntervalSince1970: 5_000)
        let catalog = FakeCatalog(
            eventsAccess: .granted,
            remindersAccess: .granted,
            snapshot: CalendarSnapshot(
                eventsAccess: .granted,
                remindersAccess: .granted,
                events: [
                    CalendarOccurrence(
                        title: "Later event",
                        start: now.addingTimeInterval(.hours(4)),
                        end: now.addingTimeInterval(.hours(5)),
                        isAllDay: false,
                        isCancelled: false,
                        currentUserDeclined: false
                    )
                ],
                reminders: [ReminderOccurrence(title: "Should not win", due: now.addingTimeInterval(-.minutes(1)))],
                remindersTimedOut: true
            )
        )
        let service = CalendarService(catalog: catalog, now: { now })
        await service.refresh()
        #expect(service.lastError == CalendarService.remindersTimedOutMessage)
        #expect(service.nextItem?.title == "Later event")
    }

    @Test func overlappingRefreshPublishesOnlyTheCurrentGeneration() async {
        let now = Date(timeIntervalSince1970: 8_000)
        let older = CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .denied,
            events: [
                CalendarOccurrence(
                    title: "Older",
                    start: now.addingTimeInterval(120),
                    end: now.addingTimeInterval(600),
                    isAllDay: false,
                    isCancelled: false,
                    currentUserDeclined: false
                )
            ],
            reminders: []
        )
        let newer = CalendarSnapshot(
            eventsAccess: .granted,
            remindersAccess: .denied,
            events: [
                CalendarOccurrence(
                    title: "Newer",
                    start: now.addingTimeInterval(180),
                    end: now.addingTimeInterval(700),
                    isAllDay: false,
                    isCancelled: false,
                    currentUserDeclined: false
                )
            ],
            reminders: []
        )
        let catalog = FakeCatalog(eventsAccess: .granted, remindersAccess: .denied, snapshot: older)
        catalog.holdLoads = true
        let service = CalendarService(catalog: catalog, now: { now })
        let first = Task { await service.refresh() }
        while catalog.heldLoadCount < 1 { await Task.yield() }
        catalog.snapshot = newer
        let second = Task { await service.refresh() }
        while catalog.heldLoadCount < 2 { await Task.yield() }
        catalog.resumeOldestHeldLoad()
        catalog.resumeOldestHeldLoad()
        await first.value
        await second.value
        #expect(service.nextItem?.title == "Newer")
        #expect(service.snapshotLoadCount == 1)
    }
}

struct ReminderFetchGateTests {
    @Test func timeoutIsNotAnEmptyDraftListAndLateDraftsDoNotReplaceIt() async {
        let load = await withCheckedContinuation { continuation in
            let gate = ReminderFetchGate()
            gate.complete(.timedOut, continuation)
            gate.complete(
                .drafts([ReminderDraft(title: "Late", due: Date())]),
                continuation
            )
        }
        #expect(load == .timedOut)
    }

    @Test func firstDraftsWinOverALaterTimeout() async {
        let draft = ReminderDraft(title: "Due", due: Date())
        let load = await withCheckedContinuation { continuation in
            let gate = ReminderFetchGate()
            gate.complete(.drafts([draft]), continuation)
            gate.complete(.timedOut, continuation)
        }
        #expect(load == .drafts([draft]))
    }
}

@MainActor
private final class FakeCatalog: CalendarCataloging {
    var eventsAccess: CalendarAccess
    var remindersAccess: CalendarAccess
    var snapshot: CalendarSnapshot
    var requestResult: (CalendarAccess, CalendarAccess, String?)?
    var didRequestAccess = false
    var holdLoads = false
    private var heldLoads: [(CalendarSnapshot, CheckedContinuation<CalendarSnapshot, Never>)] = []
    private var handler: (@MainActor () async -> Void)?

    init(eventsAccess: CalendarAccess, remindersAccess: CalendarAccess, snapshot: CalendarSnapshot) {
        self.eventsAccess = eventsAccess
        self.remindersAccess = remindersAccess
        self.snapshot = snapshot
    }

    func currentAccess() -> (events: CalendarAccess, reminders: CalendarAccess) {
        (eventsAccess, remindersAccess)
    }

    func requestAccess() async -> (events: CalendarAccess, reminders: CalendarAccess, error: String?) {
        didRequestAccess = true
        if let requestResult {
            eventsAccess = requestResult.0
            remindersAccess = requestResult.1
            return requestResult
        }
        return (eventsAccess, remindersAccess, nil)
    }

    func loadSnapshot(at now: Date) async -> CalendarSnapshot {
        let copy = preparedSnapshot()
        if holdLoads {
            return await withCheckedContinuation { continuation in
                heldLoads.append((copy, continuation))
            }
        }
        return copy
    }

    private func preparedSnapshot() -> CalendarSnapshot {
        var copy = snapshot
        copy.eventsAccess = eventsAccess
        copy.remindersAccess = remindersAccess
        if !eventsAccess.canRead {
            copy.events = []
        }
        if !remindersAccess.canRead {
            copy.reminders = []
            copy.remindersTimedOut = false
        }
        return copy
    }

    var heldLoadCount: Int { heldLoads.count }

    func resumeOldestHeldLoad() {
        let pair = heldLoads.removeFirst()
        pair.1.resume(returning: pair.0)
    }

    func startObservingChanges(_ handler: @escaping @MainActor () async -> Void) {
        self.handler = handler
    }

    func simulateStoreChange() async {
        await handler?()
    }
}
