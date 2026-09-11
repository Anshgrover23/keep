import AppKit
import Combine
import Foundation

@MainActor
final class PowerMonitor: ObservableObject {
    @Published private(set) var hardwareScreenLocked = false
    @Published private(set) var hardwareAsleep = false
    @Published private(set) var hardwareLowPowerMode = false
    /// Per display covering from the window list. Does not include simulated fullscreen.
    @Published private(set) var occupancy: [UInt32: DisplayCovering] = [:]

    @Published var simulatedScreenLocked = false
    @Published var simulatedAsleep = false
    @Published var simulatedLowPower = false
    @Published var simulatedFullscreen = false

    @Published var pauseWhenFullscreen = true
    @Published var pauseOnLowPower = true

    private(set) var isStarted = false

    var screenLocked: Bool { hardwareScreenLocked || simulatedScreenLocked }
    var asleep: Bool { hardwareAsleep || simulatedAsleep }
    var lowPowerMode: Bool { hardwareLowPowerMode || simulatedLowPower }

    var anyTrueFullscreen: Bool {
        occupancy.values.contains(.trueFullscreen)
    }

    var occupancyLabLabel: String {
        if occupancy.isEmpty { return "None" }
        return occupancy.keys.sorted().map { id in
            let name = occupancy[id]?.labName ?? "clear"
            return "Display \(id): \(name)"
        }.joined(separator: ", ")
    }

    var systemShouldPause: Bool {
        SystemPausePolicy.shouldPause(
            screenLocked: screenLocked,
            asleep: asleep,
            lowPowerMode: lowPowerMode,
            pauseOnLowPower: pauseOnLowPower
        )
    }

    var pauseReason: String {
        let global = SystemPausePolicy.reason(
            screenLocked: screenLocked,
            asleep: asleep,
            lowPowerMode: lowPowerMode,
            pauseOnLowPower: pauseOnLowPower,
            lockIsSimulated: simulatedScreenLocked && !hardwareScreenLocked,
            sleepIsSimulated: simulatedAsleep && !hardwareAsleep,
            lowPowerIsSimulated: simulatedLowPower && !hardwareLowPowerMode
        )
        if global != "running" { return global }
        if simulatedFullscreen { return "simulated fullscreen" }
        if pauseWhenFullscreen && anyTrueFullscreen { return "true fullscreen" }
        return "running"
    }

    private var defaultCenterTokens: [NSObjectProtocol] = []
    private var distributedTokens: [NSObjectProtocol] = []
    private var workspaceTokens: [NSObjectProtocol] = []
    private var fullscreenTimer: Timer?

    var notificationTokenCount: Int {
        defaultCenterTokens.count + distributedTokens.count + workspaceTokens.count
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        hardwareLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        distributedTokens.append(DistributedNotificationCenter.default().addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareScreenLocked = true
                KeepLog.power.info("Screen locked")
            }
        })

        distributedTokens.append(DistributedNotificationCenter.default().addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareScreenLocked = false
                KeepLog.power.info("Screen unlocked")
            }
        })

        defaultCenterTokens.append(NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
        })

        workspaceTokens.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareAsleep = true
                KeepLog.power.info("System will sleep")
            }
        })

        workspaceTokens.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareAsleep = false
                KeepLog.power.info("System woke")
            }
        })

        workspaceTokens.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareAsleep = true
                KeepLog.power.info("Displays slept")
            }
        })

        workspaceTokens.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hardwareAsleep = false
                KeepLog.power.info("Displays woke")
            }
        })

        workspaceTokens.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshOccupancy() }
        })
        workspaceTokens.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshOccupancy() }
        })
        defaultCenterTokens.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshOccupancy() }
        })

        fullscreenTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshOccupancy() }
        }
        refreshOccupancy()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        fullscreenTimer?.invalidate()
        fullscreenTimer = nil
        for token in distributedTokens {
            DistributedNotificationCenter.default().removeObserver(token)
        }
        distributedTokens.removeAll()
        for token in defaultCenterTokens {
            NotificationCenter.default.removeObserver(token)
        }
        defaultCenterTokens.removeAll()
        for token in workspaceTokens {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        workspaceTokens.removeAll()
    }

    func clearSimulations() {
        simulatedScreenLocked = false
        simulatedAsleep = false
        simulatedLowPower = false
        simulatedFullscreen = false
    }

    private func refreshOccupancy() {
        occupancy = Self.liveOccupancy(ownPID: ProcessInfo.processInfo.processIdentifier)
    }

    static func liveOccupancy(ownPID: pid_t) -> [UInt32: DisplayCovering] {
        let displays = NSScreen.screens.map { screen -> DisplayGeometry in
            DisplayGeometry(
                id: displayID(for: screen),
                frame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        }
        let primaryHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.screens.first?.frame.height
            ?? 0
        let windows = cgWindows(primaryHeight: primaryHeight)
        return FullscreenClassification.occupancy(
            windows: windows,
            displays: displays,
            ownPID: ownPID
        )
    }

    private static func displayID(for screen: NSScreen) -> UInt32 {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }

    private static func cgWindows(primaryHeight: CGFloat) -> [ObservedWindow] {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return info.compactMap { window in
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 else { return nil }
            let pid = window[kCGWindowOwnerPID as String] as? pid_t ?? 0
            guard let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat] else { return nil }
            let cg = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            return ObservedWindow(
                ownerPID: pid,
                layer: layer,
                bounds: FullscreenClassification.cocoaRect(fromCGWindowBounds: cg, primaryHeight: primaryHeight)
            )
        }
    }
}
