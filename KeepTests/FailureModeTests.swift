import Foundation
import Testing
@testable import Keep

/// Gaps that were not named as failure modes in earlier suites.
/// Existing HTTP/calendar/location/wallpaper tests remain the source for those modes.

struct LocationUnavailableTests {
    @Test func notDeterminedDiscardsMeasuredGPS() {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let date = Date(timeIntervalSince1970: 0)
        let fix = LocationResolver.fix(
            access: .notDetermined,
            measured: (latitude: 37.7, longitude: -122.4),
            timeZone: zone,
            at: date
        )
        #expect(fix == .timeZone(longitude: TimezoneLongitude.degrees(timeZone: zone, at: date)))
    }

    @Test func timeZoneFixUsesEquatorForWeatherAndIsNotACity() {
        let fix = LocationFix.timeZone(longitude: 82.5)
        #expect(fix.weatherLatitude == 0)
        #expect(fix.longitude == 82.5)
        if case .gps = fix {
            Issue.record("Unavailable location must not become a GPS coordinate")
        }
    }
}

struct HTTPFailureModeTests {
    private let url = URL(string: "https://example.test/weather")!

    @Test func fiveHundredThenFourHundredStopsAfterTheRetryWithoutAThirdExchange() async {
        let client = HTTPClient(transport: FailureModeRejectingTransport())
        await client.stubNext(.response(status: 503, body: Data("down".utf8)))
        await client.stubNext(.response(status: 404, body: Data("gone".utf8)))
        await #expect(throws: HTTPError.status(code: 404, snippet: "gone")) {
            _ = try await client.get(url)
        }
        #expect(await client.exchangeCount == 2)
    }

    @Test func threeOhTwoFinalResponseIsGradedNotRetried() async throws {
        let client = HTTPClient(transport: FailureModeRejectingTransport())
        await client.stubNext(.response(status: 302, body: Data("elsewhere".utf8)))
        let data = try await client.get(url)
        #expect(String(data: data, encoding: .utf8) == "elsewhere")
        #expect(await client.exchangeCount == 1)
    }
}

@MainActor
struct SettingsDefaultsAndRelaunchTests {
    @Test func missingKeysUseSafeDefaults() {
        let suite = "app.keep.tests.settings.defaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let settings = AppSettings(defaults: defaults)
        #expect(settings.didOnboard == false)
        #expect(settings.pauseWhenFullscreen)
        #expect(settings.pauseOnLowPower)
        #expect(settings.intentionText.isEmpty)
        #expect(settings.intentionDay.isEmpty)
        #expect(settings.schemaVersion == AppSettings.currentSchemaVersion)
    }

    @Test func missingSchemaVersionDoesNotClearIntention() {
        let suite = "app.keep.tests.settings.schema.stamp.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set("Keep the day", forKey: "keep.intention.text")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.intentionText == "Keep the day")
        #expect(settings.schemaVersion == 1)
        #expect(settings.pauseWhenFullscreen)
    }

    @Test func newerSchemaVersionIsLeftAlone() {
        let suite = "app.keep.tests.settings.schema.future.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(99, forKey: "keep.schemaVersion")
        defaults.set("Keep going", forKey: "keep.intention.text")
        let settings = AppSettings(defaults: defaults)
        #expect(settings.schemaVersion == 99)
        #expect(settings.intentionText == "Keep going")
    }

    @Test func optOutsAndOnboardingSurviveANewSettingsInstance() {
        let suite = "app.keep.tests.settings.relaunch.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let first = AppSettings(defaults: defaults)
        first.didOnboard = true
        first.pauseWhenFullscreen = false
        first.pauseOnLowPower = false
        first.intentionText = "Ship Keep"
        first.intentionDay = "2026-09-11"

        let relaunched = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        #expect(relaunched.didOnboard)
        #expect(relaunched.pauseWhenFullscreen == false)
        #expect(relaunched.pauseOnLowPower == false)
        #expect(relaunched.intentionText == "Ship Keep")
        #expect(relaunched.intentionDay == "2026-09-11")
        #expect(relaunched.schemaVersion == AppSettings.currentSchemaVersion)
    }

    @Test func sessionRelaunchDoesNotAskOnboardingAgain() {
        let suite = "app.keep.tests.session.relaunch.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let firstSettings = AppSettings(defaults: defaults)
        let first = AppSession(
            settings: firstSettings,
            calendar: FailureModeCalendar(),
            weather: FailureModeWeather(),
            intention: IntentionStore(settings: firstSettings),
            location: FailureModeLocation(),
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: NoOpActivation()
        )
        first.finishOnboarding()

        let secondSettings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        let second = AppSession(
            settings: secondSettings,
            calendar: FailureModeCalendar(),
            weather: FailureModeWeather(),
            intention: IntentionStore(settings: secondSettings),
            location: FailureModeLocation(),
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: NoOpActivation()
        )
        #expect(second.needsOnboarding == false)
        #expect(second.intention.text.isEmpty)
    }

    @Test func intentionStaleFlagReloadsFromPersistedDay() {
        let suite = "app.keep.tests.intention.relaunch.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let firstSettings = AppSettings(defaults: defaults)
        let first = IntentionStore(settings: firstSettings)
        first.set("Call dad")
        first.markStaleForTesting()

        let relaunched = IntentionStore(settings: AppSettings(defaults: UserDefaults(suiteName: suite)!))
        #expect(relaunched.text == "Call dad")
        #expect(relaunched.isStale)
    }
}

@MainActor
struct SleepWakeLockIndependenceTests {
    @Test func clearingSleepDoesNotClearAnAssertedLock() {
        let power = PowerMonitor()
        power.simulatedAsleep = true
        power.simulatedScreenLocked = true
        #expect(power.pauseReason == "simulated sleep")
        power.simulatedAsleep = false
        #expect(power.systemShouldPause)
        #expect(power.pauseReason == "simulated lock")
    }
}

private struct FailureModeRejectingTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        Issue.record("Failure mode HTTP used the network: \(request.url?.absoluteString ?? "")")
        throw URLError(.notConnectedToInternet)
    }
}

@MainActor
private final class FailureModeCalendar: ObservableObject, CalendarReading {
    @Published var nextItem: MemoryItem?
    @Published var eventsGranted = false
    @Published var remindersGranted = false
    @Published var lastError: String?
    var accessGranted: Bool { false }
    func start() {}
    func requestAccessAndRefresh() async {}
    func refresh() async {}
}

@MainActor
private final class FailureModeWeather: ObservableObject, WeatherFetching {
    @Published var kind: WeatherKind = .clear
    @Published var lastUpdated: Date?
    @Published var lastError: String?
    @Published var lastWMOCode: Int?
    func refresh(latitude: Double, longitude: Double, force: Bool) async {}
    func failNextRefresh() async {}
}

@MainActor
private final class FailureModeLocation: ObservableObject, LocationProviding {
    @Published var fix: LocationFix = .timeZone(longitude: 0)
    @Published var access: LocationAccess = .denied
    @Published var lastError: String?
    var latitude: Double { fix.weatherLatitude }
    var longitude: Double { fix.longitude }
    var authorized: Bool { access.canRead }
    func start() {}
    func request() {}
}
