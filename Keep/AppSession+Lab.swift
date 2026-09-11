import Foundation

/// Lab-only session controls. `AppSession` remains the composition root.
extension AppSession {
    /// `hour24` is 0...23. 0 = 12 AM (midnight), 12 = 12 PM (midday).
    func pinWallClock(hour24: Int, minute: Int = 1) {
        pinnedPhase = nil
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour24
        components.minute = minute
        components.second = 0
        clockAnchor = Calendar.current.date(from: components)
        clockPinnedAt = Date()
        pinnedClockLabel = switch hour24 {
        case 0: "midnight"
        case 12: "noon"
        default: String(format: "%02d:%02d", hour24, minute)
        }
        refreshSolar(at: Date())
    }

    func pinPhase(_ phase: DayPhase?) {
        pinnedPhase = phase
        pinnedClockLabel = nil
        if let phase {
            clockAnchor = SolarEngine.date(
                representing: phase,
                observer: effectiveFix.solarObserver
            )
            clockPinnedAt = Date()
        } else {
            clockAnchor = nil
            clockPinnedAt = nil
        }
        refreshSolar(at: Date())
    }

    func injectMemory(title: String, minutesFromNow: Int, kind: MemoryItem.Kind, isAllDay: Bool = false) {
        hideMemory = false
        memoryOverride = MemoryItem(
            kind: kind,
            title: title,
            date: Date().addingTimeInterval(.minutes(minutesFromNow)),
            isAllDay: isAllDay
        )
    }

    func useLiveMemory() {
        hideMemory = false
        memoryOverride = nil
    }

    func injectWeatherFailure() {
        Task {
            await weather.failNextRefresh()
            await weather.refresh(
                latitude: effectiveFix.weatherLatitude,
                longitude: effectiveFix.longitude,
                force: true
            )
        }
    }

    func clearOverrides() {
        pinPhase(nil)
        weatherOverride = nil
        useLiveMemory()
        power.clearSimulations()
        userPaused = false
    }

    func replayOnboarding() {
        didOnboard = false
        OnboardingWindow.present(session: self)
    }
}
