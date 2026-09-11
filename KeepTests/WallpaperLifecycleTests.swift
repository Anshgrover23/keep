import AppKit
import Foundation
import Testing
@testable import Keep

struct WallpaperDisplayLinkPolicyTests {
    @Test func hiddenWallpaperDetachesEvenIfSessionIsRunning() {
        #expect(
            WallpaperDisplayLinkPolicy.state(wallpaperVisible: false, sessionPaused: false) == .detached
        )
        #expect(
            WallpaperDisplayLinkPolicy.state(wallpaperVisible: false, sessionPaused: true) == .detached
        )
    }

    @Test func visibleWallpaperStaysAttachedAndPauseOnlyFreezesTheLink() {
        #expect(
            WallpaperDisplayLinkPolicy.state(wallpaperVisible: true, sessionPaused: false) == .attached(paused: false)
        )
        #expect(
            WallpaperDisplayLinkPolicy.state(wallpaperVisible: true, sessionPaused: true) == .attached(paused: true)
        )
    }
}

struct SystemPausePolicyTests {
    @Test func lockAndSleepPauseIndependently() {
        #expect(
            SystemPausePolicy.shouldPause(
                screenLocked: true,
                asleep: false,
                lowPowerMode: false,
                pauseOnLowPower: true
            )
        )
        #expect(
            SystemPausePolicy.shouldPause(
                screenLocked: false,
                asleep: true,
                lowPowerMode: false,
                pauseOnLowPower: true
            )
        )
        #expect(
            SystemPausePolicy.shouldPause(
                screenLocked: false,
                asleep: false,
                lowPowerMode: false,
                pauseOnLowPower: true
            ) == false
        )
    }

    @Test func sleepReasonIsNotReportedAsLock() {
        #expect(
            SystemPausePolicy.reason(
                screenLocked: true,
                asleep: true,
                lowPowerMode: false,
                pauseOnLowPower: true,
                lockIsSimulated: false,
                sleepIsSimulated: false,
                lowPowerIsSimulated: false
            ) == "asleep"
        )
        #expect(
            SystemPausePolicy.reason(
                screenLocked: true,
                asleep: false,
                lowPowerMode: false,
                pauseOnLowPower: true,
                lockIsSimulated: false,
                sleepIsSimulated: false,
                lowPowerIsSimulated: false
            ) == "screen locked"
        )
    }

    @Test func lowPowerDoesNotPauseUnlessOptedIn() {
        #expect(
            SystemPausePolicy.shouldPause(
                screenLocked: false,
                asleep: false,
                lowPowerMode: true,
                pauseOnLowPower: false
            ) == false
        )
        #expect(
            SystemPausePolicy.shouldPause(
                screenLocked: false,
                asleep: false,
                lowPowerMode: true,
                pauseOnLowPower: true
            )
        )
    }
}

@MainActor
struct FrameClockLifecycleTests {
    @Test func windowDisplayLinkInstallsAndDetachClearsIt() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 64, height: 64),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let clock = FrameClock()
        clock.applyDesktopPolicy(.attached(paused: false), window: window)
        #expect(clock.attachment == .window)
        #expect(clock.isLinkInstalled)
        #expect(clock.isPaused == false)

        clock.applyDesktopPolicy(.attached(paused: true), window: window)
        #expect(clock.attachment == .window)
        #expect(clock.isLinkInstalled)
        #expect(clock.isPaused)

        clock.applyDesktopPolicy(.detached, window: window)
        #expect(clock.attachment == .none)
        #expect(clock.isLinkInstalled == false)
    }

    @Test func labScreenAttachmentIsNotAWindowLink() {
        guard let screen = NSScreen.main else { return }
        let clock = FrameClock()
        clock.attach(to: screen)
        #expect(clock.attachment == .screen)
        clock.detach()
        #expect(clock.attachment == .none)
    }
}

struct FrameRateMeterTests {
    @Test func staysZeroUntilAFullSecondOfFrames() {
        var meter = FrameRateMeter(now: 0)
        let fps = Double(FrameRateMeter.preferredFramesPerSecond)
        for i in 1..<Int(fps) {
            meter.recordFrame(now: Double(i) / fps)
        }
        #expect(meter.framesPerSecond == 0)
        meter.recordFrame(now: FrameRateMeter.windowDuration)
        #expect(meter.framesPerSecond == Int(fps))
    }

    @Test func resetClearsFps() {
        var meter = FrameRateMeter(now: 0)
        meter.recordFrame(now: 1.0)
        #expect(meter.framesPerSecond > 0)
        meter.reset(now: 2)
        #expect(meter.framesPerSecond == 0)
    }
}

@MainActor
struct PowerMonitorSleepVsLockTests {
    @Test func simulatedSleepPausesWithoutClaimingTheScreenIsLocked() {
        let power = PowerMonitor()
        power.simulatedAsleep = true
        #expect(power.systemShouldPause)
        #expect(power.pauseReason == "simulated sleep")
        #expect(power.screenLocked == false)
        power.simulatedAsleep = false
        power.simulatedScreenLocked = true
        #expect(power.pauseReason == "simulated lock")
    }

    @Test func startIsIdempotentAndStopClearsObservers() {
        let power = PowerMonitor()
        power.start()
        let tokens = power.notificationTokenCount
        #expect(power.isStarted)
        #expect(tokens > 0)
        power.start()
        #expect(power.notificationTokenCount == tokens)
        power.stop()
        #expect(power.isStarted == false)
        #expect(power.notificationTokenCount == 0)
        power.start()
        #expect(power.isStarted)
        #expect(power.notificationTokenCount == tokens)
        power.stop()
    }

    @Test func lowPowerSimulationDoesNotPauseUnlessOptedIn() {
        let power = PowerMonitor()
        power.simulatedLowPower = true
        #expect(power.systemShouldPause == false)
        power.pauseOnLowPower = true
        #expect(power.systemShouldPause)
        #expect(power.pauseReason == "simulated Low Power Mode")
    }
}

@MainActor
struct AppSessionWallpaperPauseTests {
    @Test func sessionPauseReachesWallpaperPolicyWhileStartIsOptedOut() {
        let settings = AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let session = AppSession(
            settings: settings,
            calendar: SessionPauseCalendar(),
            weather: SessionPauseWeather(),
            intention: IntentionStore(settings: settings),
            location: SessionPauseLocation(),
            power: PowerMonitor(),
            wallpaper: WallpaperController(),
            activation: NoOpActivation()
        )
        session.start(observeSystem: false)
        session.userPaused = true
        #expect(session.isPaused)
        #expect(
            WallpaperDisplayLinkPolicy.state(
                wallpaperVisible: session.wallpaper.isVisible,
                sessionPaused: session.isPaused
            ) == .attached(paused: true)
        )
        session.wallpaper.setVisible(false)
        #expect(
            WallpaperDisplayLinkPolicy.state(
                wallpaperVisible: session.wallpaper.isVisible,
                sessionPaused: session.isPaused
            ) == .detached
        )
    }
}

@MainActor
private final class SessionPauseCalendar: ObservableObject, CalendarReading {
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
private final class SessionPauseWeather: ObservableObject, WeatherFetching {
    @Published var kind: WeatherKind = .clear
    @Published var lastUpdated: Date?
    @Published var lastError: String?
    @Published var lastWMOCode: Int?
    func refresh(latitude: Double, longitude: Double, force: Bool) async {}
    func failNextRefresh() async {}
}

@MainActor
private final class SessionPauseLocation: ObservableObject, LocationProviding {
    @Published var fix: LocationFix = .timeZone(longitude: 0)
    @Published var access: LocationAccess = .denied
    @Published var lastError: String?
    var latitude: Double { 0 }
    var longitude: Double { 0 }
    var authorized: Bool { false }
    func start() {}
    func request() {}
}
