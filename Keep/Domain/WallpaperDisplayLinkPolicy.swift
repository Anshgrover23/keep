import Foundation

/// Desired CADisplayLink state for a desktop wallpaper window.
/// Lab's `NSScreen.displayLink` is a different clock and must not use this policy as proof.
enum WallpaperDisplayLinkPolicy {
    enum State: Equatable, Sendable {
        /// Window ordered out; link invalidated. Hidden wallpaper must not keep a running callback.
        case detached
        /// `NSWindow.displayLink` on that wallpaper window. Pause freezes frames without detaching
        /// so resume stays on the same display.
        case attached(paused: Bool)
    }

    static func state(wallpaperVisible: Bool, sessionPaused: Bool) -> State {
        guard wallpaperVisible else { return .detached }
        return .attached(paused: sessionPaused)
    }
}

/// Lock and sleep always pause. Low Power Mode only if the Settings opt in is on. True fullscreen is per display.
enum SystemPausePolicy {
    static func shouldPause(
        screenLocked: Bool,
        asleep: Bool,
        lowPowerMode: Bool,
        pauseOnLowPower: Bool
    ) -> Bool {
        if screenLocked || asleep { return true }
        if pauseOnLowPower && lowPowerMode { return true }
        return false
    }

    static func reason(
        screenLocked: Bool,
        asleep: Bool,
        lowPowerMode: Bool,
        pauseOnLowPower: Bool,
        lockIsSimulated: Bool,
        sleepIsSimulated: Bool,
        lowPowerIsSimulated: Bool
    ) -> String {
        if asleep {
            return sleepIsSimulated ? "simulated sleep" : "asleep"
        }
        if screenLocked {
            return lockIsSimulated ? "simulated lock" : "screen locked"
        }
        if pauseOnLowPower && lowPowerMode {
            return lowPowerIsSimulated ? "simulated Low Power Mode" : "Low Power Mode"
        }
        return "running"
    }
}
