import AppKit
import Foundation
import Testing
@testable import Keep

@MainActor
struct DayFilmTests {
    private let zone = TimeZone(identifier: "Asia/Kolkata")!

    @Test func stillsCoverDawnThroughNight() {
        let session = makeLaunchSession()
        for sample in DayFilm.heroHours {
            let date = civil(hour: sample.hour, minute: 0)
            session.weatherOverride = sample.weather
            let frame = DayFilm.render(session: session, at: date, size: DayFilm.checkSize)
            #expect(frame != nil, "Missing still at \(sample.hour):00 \(sample.weather.rawValue)")
            #expect(frame?.width == Int(DayFilm.checkSize.width))
            #expect(frame?.height == Int(DayFilm.checkSize.height))
        }
    }

    @Test func socialPreviewMakesBodiesAndWeatherLargerThanWallpaper() {
        #expect(SceneReadability.socialPreview.bodyScale > SceneReadability.wallpaper.bodyScale)
        #expect(SceneReadability.socialPreview.particleScale > SceneReadability.wallpaper.particleScale)
        #expect(SceneReadability.socialPreview.particleStrokeScale > SceneReadability.wallpaper.particleStrokeScale)
    }

    @Test func civilDayTouchesEveryWeatherKind() {
        let dates = DayFilm.civilDates(year: 2026, month: 9, day: 11, strideMinutes: 60, timeZone: zone)
        let kinds = Set(dates.map { DayFilm.weather(at: $0, timeZone: zone) })
        #expect(kinds == Set(WeatherKind.allCases))
    }

    @Test func glassCycleCivilDateMovesFromDawnTowardDusk() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 11
        let near = calendar.date(from: components)!
        let observer = SolarObserver.geographic(latitude: 23, longitude: 82.5)
        let dawn = GlassCycleFilm.civilDate(progress: 0, near: near, observer: observer)
        let dusk = GlassCycleFilm.civilDate(progress: 1, near: near, observer: observer)
        #expect(dusk > dawn)
        #expect(SolarEngine.context(at: dawn, observer: observer).phase == .dawn)
        #expect(SolarEngine.context(at: dusk, observer: observer).phase == .dusk)
        let startSun = DaySceneView.bodyPoint(
            size: GlassCycleFilm.canvas,
            progress: SolarEngine.context(at: dawn, observer: observer).sunProgress
        )
        #expect(startSun.x >= GlassCycleFilm.startSunMinX)
        let noon = GlassCycleFilm.civilDate(progress: 0.5, near: near, observer: observer)
        let afternoon = GlassCycleFilm.civilDate(progress: 0.68, near: near, observer: observer)
        #expect(SolarEngine.context(at: noon, observer: observer).phase == .noon)
        #expect(SolarEngine.context(at: afternoon, observer: observer).phase == .afternoon)
    }

    @Test func writesLaunchFilmWhenAsked() throws {
        // xcodebuild passes TEST_RUNNER_KEEP_DAY_FILM into the host as KEEP_DAY_FILM.
        guard ProcessInfo.processInfo.environment["KEEP_DAY_FILM"] == "1" else { return }

        let session = makeLaunchSession()
        let stride = Int(ProcessInfo.processInfo.environment["KEEP_DAY_FILM_STRIDE"] ?? "") ?? DayFilm.defaultStrideMinutes
        let dates = DayFilm.civilDates(year: 2026, month: 9, day: 11, strideMinutes: stride, timeZone: zone)
        #expect(!dates.isEmpty)

        let folder = outputFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var index = 1
        for date in dates {
            session.weatherOverride = DayFilm.weather(at: date, timeZone: zone)
            guard let frame = DayFilm.render(session: session, at: date, size: DayFilm.launchSize) else {
                Issue.record("Render failed for \(date)")
                continue
            }
            let name = String(format: "frame-%04d.png", index)
            try DayFilm.writePNG(frame, to: folder.appendingPathComponent(name))
            index += 1
        }
        for sample in DayFilm.heroHours {
            session.weatherOverride = sample.weather
            let date = civil(hour: sample.hour, minute: 0)
            guard let frame = DayFilm.render(session: session, at: date, size: DayFilm.launchSize) else {
                Issue.record("Hero still failed for \(sample.weather.rawValue)")
                continue
            }
            try DayFilm.writePNG(
                frame,
                to: folder.appendingPathComponent("hero-\(sample.weather.rawValue).png")
            )
        }
        #expect(index > 1)
        let line = "KEEP_DAY_FILM_WROTE=\(folder.path)\n"
        if let data = line.data(using: .utf8) {
            FileHandle.standardError.write(data)
            FileHandle.standardOutput.write(data)
        }
    }

    private func civil(hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 11
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private func outputFolder() -> URL {
        if let raw = ProcessInfo.processInfo.environment["KEEP_DAY_FILM_DIR"], !raw.isEmpty {
            return URL(fileURLWithPath: raw, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("keep-day-film", isDirectory: true)
    }

    private func makeLaunchSession() -> AppSession {
        let settings = AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let location = FilmLocation()
        location.access = .granted
        location.fix = .gps(latitude: 28.61, longitude: 77.21)
        let session = AppSession(
            settings: settings,
            calendar: FilmCalendar(),
            weather: FilmWeather(),
            intention: IntentionStore(settings: settings),
            location: location,
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: FilmActivation()
        )
        session.intention.set("Bread and Butter")
        session.memoryOverride = MemoryItem(
            kind: .event,
            title: "Offsite",
            date: civil(hour: 12, minute: 0),
            isAllDay: true
        )
        return session
    }
}

@MainActor
private final class FilmActivation: AppActivation {
    func becomeRegular() {}
    func becomeAccessory() {}
}

@MainActor
private final class FilmCalendar: ObservableObject, CalendarReading {
    @Published var nextItem: MemoryItem?
    @Published var eventsGranted = true
    @Published var remindersGranted = false
    @Published var lastError: String?
    var accessGranted: Bool { true }
    var canRequestCalendarAccess = false
    func start() {}
    func requestAccessAndRefresh() async {}
    func refresh() async {}
}

@MainActor
private final class FilmWeather: ObservableObject, WeatherFetching {
    @Published var kind: WeatherKind = .clear
    @Published var lastUpdated: Date?
    @Published var lastError: String?
    @Published var lastWMOCode: Int?
    func refresh(latitude: Double, longitude: Double, force: Bool) async {}
    func failNextRefresh() async {}
}

@MainActor
private final class FilmLocation: ObservableObject, LocationProviding {
    @Published var fix: LocationFix = .timeZone(longitude: 77)
    @Published var access: LocationAccess = .granted
    @Published var lastError: String?
    var latitude: Double { fix.weatherLatitude }
    var longitude: Double { fix.longitude }
    var authorized: Bool { access.canRead }
    func start() {}
    func request() {}
}
