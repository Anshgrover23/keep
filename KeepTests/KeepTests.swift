import AppKit
import Foundation
import Testing
@testable import Keep

struct SolarEngineTests {
    private let india = TimeZone(identifier: "Asia/Kolkata")!

    @Test func twelveOhOneAMIsNightNotNoon() {
        let date = wallClock(year: 2026, month: 9, day: 11, hour: 0, minute: 1, timeZone: india)
        let ctx = Daylight.context(at: date, latitude: 23, longitude: 82.5)
        #expect(ctx.phase == .night)
        #expect(ctx.isDay == false)
    }

    @Test func twelveOhOnePMIsDay() {
        let date = wallClock(year: 2026, month: 9, day: 11, hour: 12, minute: 1, timeZone: india)
        let ctx = Daylight.context(at: date, latitude: 23, longitude: 82.5)
        #expect(ctx.isDay == true)
        #expect(ctx.phase != .night)
    }

    private func wallClock(year: Int, month: Int, day: Int, hour: Int, minute: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}

struct WeatherKindTests {
    @Test func mapsWMOCodes() {
        #expect(WeatherKind(wmoCode: 0) == .clear)
        #expect(WeatherKind(wmoCode: 3) == .cloudy)
        #expect(WeatherKind(wmoCode: 61) == .rain)
        #expect(WeatherKind(wmoCode: 71) == .snow)
        #expect(WeatherKind(wmoCode: 95) == .storm)
        #expect(WeatherKind(wmoCode: 45) == .fog)
    }
}

struct MemoryItemTests {
    @Test func captionsCoverImminentDueAndAllDay() {
        let now = Date()
        let soon = MemoryItem(kind: .event, title: "Review", date: now.addingTimeInterval(.minutes(8)))
        #expect(soon.caption(now: now) == "in 8 min")
        #expect(soon.isImminent(at: now))

        let due = MemoryItem(kind: .reminder, title: "Call", date: now.addingTimeInterval(-.minutes(1)))
        #expect(due.caption(now: now) == "due now")

        let allDay = MemoryItem(kind: .event, title: "Offsite", date: now, isAllDay: true)
        #expect(allDay.caption(now: now) == "today")
        #expect(allDay.isImminent(at: now) == false)
    }
}

@MainActor
struct IntentionStoreTests {
    @Test func persistsAndMarksStaleInIsolatedDefaults() {
        let defaults = UserDefaults(suiteName: "app.keep.tests.intention")!
        defaults.removePersistentDomain(forName: "app.keep.tests.intention")
        let settings = AppSettings(defaults: defaults)
        let store = IntentionStore(settings: settings)
        store.set("Ship Keep")
        #expect(store.text == "Ship Keep")
        #expect(store.isStale == false)
        store.markStaleForTesting()
        #expect(store.isStale)
        #expect(settings.intentionText == "Ship Keep")
    }
}

@MainActor
struct AppSessionInjectionTests {
    @Test func usesInjectedCalendarNotASingleton() {
        let calendar = FakeCalendar()
        let weather = FakeWeather()
        let location = FakeLocation()
        calendar.nextItem = MemoryItem(kind: .event, title: "Injected event", date: Date().addingTimeInterval(600))
        weather.kind = .rain
        weather.lastUpdated = Date()
        location.fix = .gps(latitude: 23, longitude: 82.5)
        location.access = .granted

        let now = Date()
        let session = makeSession(calendar: calendar, weather: weather, location: location)
        session.settings.showCalendarEvents = true
        session.settings.useLocalWeather = true
        session.refreshSolar(at: now)

        #expect(session.effectiveNextItem?.title == "Injected event")
        #expect(session.effectiveWeather == .rain)
        #expect(session.weatherStatus == .available)
        #expect(session.solar.phase == SolarEngine.context(at: now, observer: location.fix.solarObserver).phase)
    }

    @Test func memoryOverrideBeatsInjectedCalendarAndHideClearsOverlay() {
        let calendar = FakeCalendar()
        calendar.nextItem = MemoryItem(kind: .event, title: "Live", date: Date().addingTimeInterval(600))
        let session = makeSession(calendar: calendar, weather: FakeWeather(), location: FakeLocation())
        session.settings.showCalendarEvents = true

        #expect(session.effectiveNextItem?.title == "Live")
        session.injectMemory(title: "Lab event", minutesFromNow: 8, kind: .event)
        #expect(session.effectiveNextItem?.title == "Lab event")
        session.hideMemory = true
        #expect(session.effectiveNextItem == nil)
        session.useLiveMemory()
        #expect(session.effectiveNextItem?.title == "Live")
    }

    @Test func timeZoneWeatherIsApproximateAndGpsSuccessIsAvailable() {
        let weather = FakeWeather()
        weather.kind = .rain
        weather.lastUpdated = Date()

        let timeZoneLocation = FakeLocation()
        timeZoneLocation.fix = .timeZone(longitude: 75)
        let approximateSession = makeSession(
            calendar: FakeCalendar(),
            weather: weather,
            location: timeZoneLocation
        )
        #expect(approximateSession.weatherStatus == .approximate)
        #expect(approximateSession.weatherStatus.extraLine == "Weather is approximate")

        let gps = FakeLocation()
        gps.fix = .gps(latitude: 19, longitude: 72)
        gps.access = .granted
        let availableSession = makeSession(
            calendar: FakeCalendar(),
            weather: weather,
            location: gps
        )
        availableSession.settings.useLocalWeather = true
        #expect(availableSession.weatherStatus == .available)
        #expect(availableSession.weatherStatus.extraLine == nil)
    }

    @Test func calendarGlanceSeparatesNotGrantedFromEmpty() async {
        let calendar = FakeCalendar()
        calendar.grantOnRequest = false
        let session = makeSession(calendar: calendar, weather: FakeWeather(), location: FakeLocation())
        #expect(session.calendarGlance == .off)

        await session.setShowCalendarEvents(true)
        #expect(session.showCalendarEvents == false)
        #expect(session.calendarGlance == .off)

        calendar.grantOnRequest = true
        await session.setShowCalendarEvents(true)
        #expect(session.showCalendarEvents)
        #expect(session.calendarGlance == .empty)
        #expect(session.calendarGlance.emptyLine == "Nothing upcoming. The day can stay quiet.")

        calendar.nextItem = MemoryItem(kind: .event, title: "Standup", date: Date().addingTimeInterval(600))
        if case .upcoming(_, let title) = session.calendarGlance {
            #expect(title == "Standup")
        } else {
            Issue.record("Expected an upcoming calendar glance")
        }
    }

    @Test func turningOnCalendarAsksAndKeepsThePreferenceWhenGranted() async {
        let calendar = FakeCalendar()
        let session = makeSession(calendar: calendar, weather: FakeWeather(), location: FakeLocation())
        await session.setShowCalendarEvents(true)
        #expect(calendar.eventsGranted)
        #expect(session.showCalendarEvents)
    }

    @Test func turningOnLocalWeatherAsksLocation() async {
        let location = FakeLocation()
        let weather = FakeWeather()
        let session = makeSession(calendar: FakeCalendar(), weather: weather, location: location)
        #expect(weather.refreshCount == 0)
        await session.setUseLocalWeather(false)
        #expect(weather.refreshCount == 0)
        await session.setUseLocalWeather(true)
        #expect(location.didRequest)
        #expect(session.useLocalWeather)
        #expect(weather.refreshCount == 1)
        if case .gps = session.effectiveFix {
            // Fake grants GPS on request.
        } else {
            Issue.record("Expected GPS fix after local weather is on")
        }
        await session.setUseLocalWeather(false)
        #expect(weather.refreshCount == 1)
        if case .timeZone = session.effectiveFix {
            // Time zone sky when the toggle is off. No forecast for the equator.
        } else {
            Issue.record("Expected time zone fix when local weather is off")
        }
        #expect(session.weatherStatus == .approximate)
    }

    @Test func weatherOverrideAndPauseComeFromInjectedCollaborators() {
        let weather = FakeWeather()
        weather.kind = .clear
        let session = makeSession(calendar: FakeCalendar(), weather: weather, location: FakeLocation())
        session.weatherOverride = .snow
        #expect(session.effectiveWeather == .snow)

        session.userPaused = true
        #expect(session.isPaused)
        session.userPaused = false
        session.power.simulatedScreenLocked = true
        #expect(session.isPaused)
        #expect(session.power.systemShouldPause)
    }

    @Test func onboardingPersistsThroughSettingsStoreWithoutActivation() {
        let defaults = UserDefaults(suiteName: "app.keep.tests.session")!
        defaults.removePersistentDomain(forName: "app.keep.tests.session")
        let settings = AppSettings(defaults: defaults)
        let session = makeSession(
            settings: settings,
            calendar: FakeCalendar(),
            weather: FakeWeather(),
            location: FakeLocation()
        )
        #expect(session.needsOnboarding)
        session.finishOnboarding()
        #expect(session.needsOnboarding == false)
        #expect(settings.didOnboard)
    }

    @Test func openingMenuExtraBecomesRegularSoTheFieldCanType() {
        let activation = RecordingActivation()
        let session = makeSession(
            calendar: FakeCalendar(),
            weather: FakeWeather(),
            location: FakeLocation(),
            activation: activation
        )
        session.finishOnboarding()
        let accessoryAfterOnboard = activation.accessoryCount
        session.menuExtraDidAppear()
        #expect(session.isMenuExtraOpen)
        #expect(activation.regularCount == 1)
        session.menuExtraDidDisappear()
        #expect(session.isMenuExtraOpen == false)
        #expect(activation.accessoryCount == accessoryAfterOnboard + 1)
    }

    @Test func closingMenuExtraDoesNotHideLab() {
        let activation = RecordingActivation()
        let session = makeSession(
            calendar: FakeCalendar(),
            weather: FakeWeather(),
            location: FakeLocation(),
            activation: activation
        )
        session.finishOnboarding()
        session.labDidAppear()
        let accessoryBefore = activation.accessoryCount
        session.menuExtraDidAppear()
        session.menuExtraDidDisappear()
        #expect(session.isLabOpen)
        #expect(activation.accessoryCount == accessoryBefore)
    }

    private func makeSession(
        settings: AppSettings? = nil,
        calendar: FakeCalendar,
        weather: FakeWeather,
        location: FakeLocation,
        activation: any AppActivation = NoOpActivation()
    ) -> AppSession {
        let settings = settings ?? AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        return AppSession(
            settings: settings,
            calendar: calendar,
            weather: weather,
            intention: IntentionStore(settings: settings),
            location: location,
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: activation
        )
    }
}

@MainActor
private final class RecordingActivation: AppActivation {
    private(set) var regularCount = 0
    private(set) var accessoryCount = 0
    func becomeRegular() { regularCount += 1 }
    func becomeAccessory() { accessoryCount += 1 }
}

@MainActor
private final class FakeCalendar: ObservableObject, CalendarReading {
    @Published var nextItem: MemoryItem?
    @Published var eventsGranted = false
    @Published var remindersGranted = false
    @Published var lastError: String?
    var accessGranted: Bool { eventsGranted || remindersGranted }
    var canRequestCalendarAccess = true
    var grantOnRequest = true
    func start() {}
    func requestAccessAndRefresh() async {
        guard grantOnRequest else { return }
        eventsGranted = true
        canRequestCalendarAccess = false
    }
    func refresh() async {}
}

@MainActor
private final class FakeWeather: ObservableObject, WeatherFetching {
    @Published var kind: WeatherKind = .clear
    @Published var lastUpdated: Date?
    @Published var lastError: String?
    @Published var lastWMOCode: Int?
    private(set) var refreshCount = 0
    func refresh(latitude: Double, longitude: Double, force: Bool) async {
        refreshCount += 1
    }
    func failNextRefresh() async { lastError = "Injected weather failure" }
}

@MainActor
private final class FakeLocation: ObservableObject, LocationProviding {
    @Published var fix: LocationFix = .timeZone(longitude: 0)
    @Published var access: LocationAccess = .denied
    @Published var lastError: String?
    var latitude: Double { fix.weatherLatitude }
    var longitude: Double { fix.longitude }
    var authorized: Bool { access.canRead }
    var didRequest = false
    func start() {}
    func request() {
        didRequest = true
        access = .granted
        fix = .gps(latitude: 37.7, longitude: -122.4)
    }
}

struct SceneMotionTests {
    @Test func reduceMotionFreezesAnimationTime() {
        let date = Date(timeIntervalSinceReferenceDate: 12_345)
        #expect(SceneMotion.timeInterval(from: date, reduceMotion: true) == 0)
        #expect(SceneMotion.timeInterval(from: date, reduceMotion: false) == 12_345)
    }

    @Test func reduceMotionSkipsPrecipitation() {
        #expect(SceneMotion.drawsPrecipitation(reduceMotion: true) == false)
        #expect(SceneMotion.drawsPrecipitation(reduceMotion: false) == true)
    }
}

@MainActor
struct OnboardingWindowLifecycleTests {
    @Test func presentClosePresentLeavesOneLiveWindow() async {
        OnboardingWindow.resetForTesting()
        let settings = AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let session = AppSession(
            settings: settings,
            calendar: FakeCalendar(),
            weather: FakeWeather(),
            intention: IntentionStore(settings: settings),
            location: FakeLocation(),
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: NoOpActivation()
        )
        OnboardingWindow.present(session: session)
        let first = OnboardingWindow.retainedWindowForTesting
        #expect(first != nil)
        OnboardingWindow.present(session: session)
        #expect(OnboardingWindow.retainedWindowForTesting === first)
        first?.close()
        for _ in 0..<40 {
            if OnboardingWindow.retainedWindowForTesting == nil { break }
            await Task.yield()
        }
        #expect(OnboardingWindow.retainedWindowForTesting == nil)
        OnboardingWindow.present(session: session)
        let second = OnboardingWindow.retainedWindowForTesting
        #expect(second != nil)
        OnboardingWindow.present(session: session)
        #expect(OnboardingWindow.retainedWindowForTesting === second)
        OnboardingWindow.resetForTesting()
    }
}

