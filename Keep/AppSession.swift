import Combine
import Foundation

/// Composition root. Coordinates services; does not own EventKit, URLSession, or CoreLocation types.
@MainActor
final class AppSession: ObservableObject {
    let settings: any SettingsStore
    let calendar: any CalendarReading
    let weather: any WeatherFetching
    let intention: IntentionStore
    let location: any LocationProviding
    let power: PowerMonitor
    let wallpaper: WallpaperController
    private let activation: any AppActivation

    @Published var solar: SolarContext
    @Published var userPaused = false
    @Published var didOnboard: Bool {
        didSet { settings.didOnboard = didOnboard }
    }

    @Published var pinnedPhase: DayPhase?
    @Published var weatherOverride: WeatherKind?
    @Published var memoryOverride: MemoryItem?
    @Published var hideMemory = false
    @Published private(set) var isLabOpen = false
    @Published private(set) var isMenuExtraOpen = false
    @Published private(set) var isOnboardingOpen = false
    @Published var pinnedClockLabel: String?

    var clockAnchor: Date?
    var clockPinnedAt: Date?

    /// How often the wallpaper solar sample runs.
    static let solarTickInterval: TimeInterval = 2
    /// How often calendar reloads while Keep is running.
    static let calendarPollInterval: TimeInterval = 30
    /// Degrees of movement before the solar ticker forces a weather refresh.
    static let weatherMoveEpsilonDegrees = 0.0001
    /// How often the session asks weather to refresh while Keep is running.
    static let weatherPollInterval: TimeInterval = .minutes(15)

    var needsOnboarding: Bool { !didOnboard }

    var isGloballyPaused: Bool {
        userPaused || power.systemShouldPause
    }

    var isPaused: Bool {
        isGloballyPaused
            || power.simulatedFullscreen
            || (power.pauseWhenFullscreen && power.anyTrueFullscreen)
    }

    var effectiveWeather: WeatherKind {
        weatherOverride ?? weather.kind
    }

    var weatherStatus: WeatherStatus {
        WeatherStatus.resolve(
            lastUpdated: weather.lastUpdated,
            lastError: weather.lastError,
            fix: effectiveFix
        )
    }

    var showCalendarEvents: Bool { settings.showCalendarEvents }
    var useLocalWeather: Bool { settings.useLocalWeather }

    var effectiveFix: LocationFix {
        guard useLocalWeather else {
            return .timeZone(longitude: TimezoneLongitude.degrees(timeZone: .current, at: Date()))
        }
        return location.fix
    }

    /// Extra glance uses wall clock `Date()`, not Lab-pinned `effectiveDate`.
    var calendarGlance: CalendarGlance {
        CalendarGlance.resolve(
            wantsEvents: showCalendarEvents || memoryOverride != nil,
            accessGranted: calendar.accessGranted,
            nextItem: effectiveNextItem,
            now: Date()
        )
    }

    var effectiveNextItem: MemoryItem? {
        if hideMemory { return nil }
        if let memoryOverride { return memoryOverride }
        guard showCalendarEvents else { return nil }
        return calendar.nextItem
    }

    var menuCaption: String {
        var parts: [String] = []
        if let next = effectiveNextItem {
            parts.append(next.caption(now: Date()))
        }
        if !intention.text.isEmpty {
            parts.append("Keep: \(intention.text)")
        }
        return parts.isEmpty ? "Living desktop" : parts.joined(separator: " · ")
    }

    private var cancellables: Set<AnyCancellable> = []
    private var tick: AnyCancellable?
    private var weatherPoll: Task<Void, Never>?
    private var started = false

    static func makeProduction() -> AppSession {
        let settings = AppSettings.production
        return AppSession(
            settings: settings,
            calendar: CalendarService(),
            weather: WeatherService(client: HTTPClient.makeProduction()),
            intention: IntentionStore(settings: settings),
            location: LocationProvider(),
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: AppKitActivation()
        )
    }

    init(
        settings: any SettingsStore,
        calendar: any CalendarReading,
        weather: any WeatherFetching,
        intention: IntentionStore,
        location: any LocationProviding,
        power: PowerMonitor,
        wallpaper: WallpaperController,
        activation: any AppActivation
    ) {
        self.settings = settings
        self.calendar = calendar
        self.weather = weather
        self.intention = intention
        self.location = location
        self.power = power
        self.wallpaper = wallpaper
        self.activation = activation
        didOnboard = settings.didOnboard
        power.pauseWhenFullscreen = settings.pauseWhenFullscreen
        power.pauseOnLowPower = settings.pauseOnLowPower
        let observer: SolarObserver
        if settings.useLocalWeather {
            observer = location.fix.solarObserver
        } else {
            observer = LocationFix.timeZone(
                longitude: TimezoneLongitude.degrees(timeZone: .current, at: Date())
            ).solarObserver
        }
        solar = SolarEngine.context(at: Date(), observer: observer)
    }

    /// `observeSystem` false keeps tests from opening wallpaper windows or EventKit.
    func start(observeSystem: Bool = true) {
        guard !started else { return }
        started = true
        KeepLog.session.info("Session starting")

        calendar.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        weather.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        location.objectWillChange.sink { [weak self] _ in
            guard let self else { return }
            self.reconcileLocationPreference()
            self.objectWillChange.send()
        }.store(in: &cancellables)
        intention.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        power.objectWillChange.sink { [weak self] _ in
            guard let self else { return }
            self.objectWillChange.send()
            self.wallpaper.syncLifecycle()
        }.store(in: &cancellables)
        wallpaper.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        $userPaused.sink { [weak self] _ in self?.wallpaper.syncLifecycle() }.store(in: &cancellables)

        guard observeSystem else { return }

        wallpaper.attach(session: self)
        wallpaper.start()
        wallpaper.syncLifecycle()
        if showCalendarEvents {
            calendar.start()
        }
        if useLocalWeather {
            location.start()
        }
        power.start()
        startWeatherPolling()

        tick = Timer.publish(every: Self.solarTickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.refreshSolar(at: date)
                self?.refreshWeatherIfLocationMoved()
            }

        Timer.publish(every: Self.calendarPollInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    guard let self, self.showCalendarEvents else { return }
                    await self.calendar.refresh()
                }
            }
            .store(in: &cancellables)
    }

    func effectiveDate(from timelineDate: Date) -> Date {
        guard let clockAnchor, let clockPinnedAt else { return timelineDate }
        return clockAnchor.addingTimeInterval(timelineDate.timeIntervalSince(clockPinnedAt))
    }

    func setPauseWhenFullscreen(_ value: Bool) {
        power.pauseWhenFullscreen = value
        settings.pauseWhenFullscreen = value
        objectWillChange.send()
    }

    func setPauseOnLowPower(_ value: Bool) {
        power.pauseOnLowPower = value
        settings.pauseOnLowPower = value
        objectWillChange.send()
    }

    func setShowCalendarEvents(_ on: Bool) async {
        if !on {
            settings.showCalendarEvents = false
            objectWillChange.send()
            return
        }
        settings.showCalendarEvents = true
        objectWillChange.send()
        calendar.start()
        await calendar.requestAccessAndRefresh()
        if !calendar.accessGranted {
            settings.showCalendarEvents = false
            objectWillChange.send()
        }
    }

    func setUseLocalWeather(_ on: Bool) async {
        if !on {
            settings.useLocalWeather = false
            refreshSolar()
            await refreshWeatherFromEffectiveFix(force: true)
            objectWillChange.send()
            return
        }
        settings.useLocalWeather = true
        objectWillChange.send()
        location.request()
        if location.access != .notDetermined, !location.authorized {
            settings.useLocalWeather = false
            objectWillChange.send()
            return
        }
        await refreshWeatherFromEffectiveFix(force: true)
        refreshSolar()
        objectWillChange.send()
    }

    private func reconcileLocationPreference() {
        guard useLocalWeather else { return }
        if location.access == .denied || location.access == .restricted {
            settings.useLocalWeather = false
        }
        refreshSolar()
        if effectiveFix.isMeasured {
            Task { await refreshWeatherFromEffectiveFix(force: true) }
        }
    }

    func finishOnboarding() {
        didOnboard = true
        restoreAccessoryIfIdle()
    }

    func onboardingDidAppear() {
        isOnboardingOpen = true
        activation.becomeRegular()
    }

    func onboardingDidDisappear() {
        isOnboardingOpen = false
        restoreAccessoryIfIdle()
    }

    /// Window style extra can take keys only while Keep is regular. No class swap on SwiftUI’s extra window.
    func menuExtraDidAppear() {
        isMenuExtraOpen = true
        activation.becomeRegular()
    }

    func menuExtraDidDisappear() {
        isMenuExtraOpen = false
        restoreAccessoryIfIdle()
    }

    func labDidAppear() {
        isLabOpen = true
        activation.becomeRegular()
    }

    func labDidDisappear() {
        isLabOpen = false
        restoreAccessoryIfIdle()
    }

    func restoreAccessoryIfIdle() {
        if !isLabOpen, !isMenuExtraOpen, !isOnboardingOpen {
            activation.becomeAccessory()
        }
    }

    func refreshSolar(at date: Date = Date()) {
        solar = SolarEngine.context(
            at: effectiveDate(from: date),
            observer: effectiveFix.solarObserver
        )
    }

    private var lastWeatherLatitude: Double?
    private var lastWeatherLongitude: Double?

    private func refreshWeatherIfLocationMoved() {
        guard effectiveFix.isMeasured else { return }
        let latitude = effectiveFix.weatherLatitude
        let longitude = effectiveFix.longitude
        if let lastWeatherLatitude, let lastWeatherLongitude,
           hypot(latitude - lastWeatherLatitude, longitude - lastWeatherLongitude) < Self.weatherMoveEpsilonDegrees {
            return
        }
        lastWeatherLatitude = latitude
        lastWeatherLongitude = longitude
        Task {
            await weather.refresh(latitude: latitude, longitude: longitude, force: true)
        }
    }

    private func refreshWeatherFromEffectiveFix(force: Bool) async {
        guard effectiveFix.isMeasured else { return }
        let latitude = effectiveFix.weatherLatitude
        let longitude = effectiveFix.longitude
        lastWeatherLatitude = latitude
        lastWeatherLongitude = longitude
        await weather.refresh(latitude: latitude, longitude: longitude, force: force)
    }

    private func startWeatherPolling() {
        weatherPoll?.cancel()
        weatherPoll = Task { [weak self] in
            guard let session = self else { return }
            await session.refreshWeatherFromEffectiveFix(force: true)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.weatherPollInterval))
                guard let session = self else { return }
                await session.refreshWeatherFromEffectiveFix(force: false)
            }
        }
    }
}
