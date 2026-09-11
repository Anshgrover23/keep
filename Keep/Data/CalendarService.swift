import Combine
import Foundation

@MainActor
final class CalendarService: ObservableObject, CalendarReading {
    @Published private(set) var nextItem: MemoryItem?
    @Published private(set) var eventsAccess: CalendarAccess = .notDetermined
    @Published private(set) var remindersAccess: CalendarAccess = .notDetermined
    @Published private(set) var lastError: String?
    @Published private(set) var snapshotLoadCount = 0

    var eventsGranted: Bool { eventsAccess.canRead }
    var remindersGranted: Bool { remindersAccess.canRead }
    var accessGranted: Bool { eventsGranted || remindersGranted }

    private let catalog: any CalendarCataloging
    private let now: () -> Date
    private var refreshGeneration: UInt64 = 0

    static let remindersTimedOutMessage = "Reminders timed out"

    init(catalog: any CalendarCataloging, now: @escaping () -> Date = Date.init) {
        self.catalog = catalog
        self.now = now
    }

    convenience init() {
        self.init(catalog: EventKitCatalog())
    }

    func start() {
        beginObservingStoreChanges()
        Task { await refresh() }
    }

    func beginObservingStoreChanges() {
        catalog.startObservingChanges { [weak self] in
            await self?.refresh()
        }
    }

    func requestAccessAndRefresh() async {
        lastError = nil
        let result = await catalog.requestAccess()
        eventsAccess = result.events
        remindersAccess = result.reminders
        lastError = result.error
        KeepLog.calendar.info("Calendar events=\(self.eventsAccess.canRead) reminders=\(self.remindersAccess.canRead)")
        await refresh()
    }

    func refresh() async {
        await refresh(at: now())
    }

    func refresh(at date: Date) async {
        refreshGeneration += 1
        let generation = refreshGeneration
        var snapshot = await catalog.loadSnapshot(at: date)
        guard generation == refreshGeneration else { return }
        snapshotLoadCount += 1
        eventsAccess = snapshot.eventsAccess
        remindersAccess = snapshot.remindersAccess
        if snapshot.remindersTimedOut {
            lastError = Self.remindersTimedOutMessage
            snapshot.reminders = []
        } else if lastError == Self.remindersTimedOutMessage {
            lastError = nil
        }
        nextItem = NextMemoryPolicy.select(snapshot, at: date)
    }
}
