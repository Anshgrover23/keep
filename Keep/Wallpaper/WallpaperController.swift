import AppKit
import SwiftUI

@MainActor
final class WallpaperController: ObservableObject {
    @Published private(set) var windowCount = 0
    @Published private(set) var isVisible = true

    private var windows: [CGDirectDisplayID: DesktopWallpaperWindow] = [:]
    private var session: AppSession?
    private var observers: [NSObjectProtocol] = []
    private var started = false

    var desktopFps: Int {
        windows.values.compactMap(\.clock?.framesPerSecond).max() ?? 0
    }

    var desktopClockLabLabel: String {
        if !isVisible {
            return "Detached, \(windowCount) windows"
        }
        var running = 0
        var paused = 0
        for (id, window) in windows {
            guard window.clock?.attachment == .window, window.clock?.isLinkInstalled == true else { continue }
            if sessionPausedForDisplay(id) {
                paused += 1
            } else {
                running += 1
            }
        }
        return "\(running) running, \(paused) paused, NSWindow.displayLink"
    }

    func attach(session: AppSession) {
        self.session = session
    }

    func start() {
        guard !started else { return }
        started = true
        rebuild()
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                KeepLog.wallpaper.info("Screen parameters changed: rebuilding wallpaper windows")
                self?.rebuild()
            }
        })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.raiseAll() }
        })
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
        applyLifecycle()
        objectWillChange.send()
    }

    func syncLifecycle() {
        applyLifecycle()
        objectWillChange.send()
    }

    func rebuild() {
        guard let session else { return }
        let screens = NSScreen.screens
        var seen: Set<CGDirectDisplayID> = []

        for screen in screens {
            let id = Self.displayID(for: screen)
            seen.insert(id)
            if let window = windows[id] {
                window.apply(screen: screen)
                continue
            }
            windows[id] = makeWindow(for: screen, session: session)
        }

        for (id, window) in windows where !seen.contains(id) {
            window.clock?.detach()
            window.orderOut(nil)
            windows.removeValue(forKey: id)
        }
        windowCount = windows.count
        applyLifecycle()
        KeepLog.wallpaper.info("Wallpaper windows=\(self.windowCount) visible=\(self.isVisible) clocks=\(self.desktopClockLabLabel)")
        objectWillChange.send()
    }

    private func applyLifecycle() {
        for (id, window) in windows {
            let paused = sessionPausedForDisplay(id)
            let state = WallpaperDisplayLinkPolicy.state(wallpaperVisible: isVisible, sessionPaused: paused)
            window.clock?.applyDesktopPolicy(state, window: window)
            switch state {
            case .detached:
                window.orderOut(nil)
            case .attached:
                window.orderFrontRegardless()
            }
        }
    }

    private func sessionPausedForDisplay(_ id: CGDirectDisplayID) -> Bool {
        guard let session else { return false }
        if session.userPaused || session.power.systemShouldPause { return true }
        if session.power.simulatedFullscreen { return true }
        return FullscreenClassification.shouldPauseDisplay(
            covering: session.power.occupancy[id] ?? .clear,
            pauseWhenFullscreen: session.power.pauseWhenFullscreen
        )
    }

    private func raiseAll() {
        guard isVisible else { return }
        for window in windows.values {
            window.orderFrontRegardless()
        }
    }

    private func makeWindow(for screen: NSScreen, session: AppSession) -> DesktopWallpaperWindow {
        let window = DesktopWallpaperWindow(screen: screen)
        let clock = FrameClock()
        let hosting = NSHostingView(rootView: WallpaperRootView(session: session, clock: clock))
        hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
        hosting.setAccessibilityElement(false)
        hosting.setAccessibilityHidden(true)
        window.contentView = hosting
        window.clock = clock
        return window
    }

    private static func displayID(for screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }
}

/// Sits just under Finder icons and above the system wallpaper, never becoming key.
final class DesktopWallpaperWindow: NSWindow {
    var clock: FrameClock?
    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        apply(screen: screen)
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        isRestorable = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        let iconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        level = NSWindow.Level(rawValue: iconLevel - 1)
        sharingType = .readOnly
        title = "Keep Wallpaper"
        hidesOnDeactivate = false
        setAccessibilityElement(false)
        setAccessibilityHidden(true)
    }

    func apply(screen: NSScreen) {
        setFrame(screen.frame, display: true)
        contentView?.frame = CGRect(origin: .zero, size: screen.frame.size)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
