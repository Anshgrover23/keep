import SwiftUI

struct LabView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var labClock = FrameClock()
    @State private var intentionDraft = ""

    var body: some View {
        HSplitView {
            preview
                .frame(minWidth: 520, idealWidth: 640)
            controls
                .frame(minWidth: 380, idealWidth: 420, maxWidth: 480)
        }
        .frame(minWidth: 980, minHeight: 640)
        .onAppear {
            intentionDraft = session.intention.text
            session.labDidAppear()
            if let screen = NSScreen.main {
                labClock.attach(to: screen)
            }
            labClock.isPaused = session.isGloballyPaused
        }
        .onDisappear {
            labClock.detach()
        }
        .onChange(of: session.isGloballyPaused) { _, paused in
            labClock.isPaused = paused
        }
        .onChange(of: session.intention.text) { _, value in
            intentionDraft = value
        }
    }

    private var preview: some View {
        ZStack(alignment: .topLeading) {
            WallpaperRootView(session: session, clock: labClock)
                .clipShape(RoundedRectangle(cornerRadius: 0))
            VStack(alignment: .leading, spacing: 8) {
                Text("PREVIEW")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.45), in: Capsule())
                    .foregroundStyle(.white)
                Spacer()
                statusChips
            }
            .padding(16)
        }
        .background(.black)
    }

    private var statusChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            chip("\(session.solar.phase.rawValue) · \(session.effectiveWeather.rawValue) · \(session.weatherStatus.rawValue)")
            chip(session.isPaused ? "paused · \(session.power.pauseReason)" : "animating")
            if let next = session.effectiveNextItem {
                chip("\(next.caption(now: Date())) · \(next.title)")
            }
            if !session.intention.text.isEmpty {
                chip("keep · \(session.intention.text)")
            }
        }
        .foregroundStyle(.white)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.45), in: Capsule())
            .lineLimit(1)
    }

    private var controls: some View {
        Form {
            liveStatus
            livingDay
            memory
            intention
            pause
            wallpaper
            permissions
            onboarding
            Section {
                labButton("Clear all overrides") {
                    session.clearOverrides()
                }
            }
        }
        .formStyle(.grouped)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var liveStatus: some View {
        Section("Status") {
            LabeledContent("Displays", value: windowCountLabel)
            LabeledContent("Desktop wallpaper", value: session.wallpaper.isVisible ? "Visible" : "Hidden")
            fact("Desktop display link", "\(session.wallpaper.desktopClockLabLabel), \(session.wallpaper.desktopFps) fps")
            fact("Lab preview clock", "\(labPreviewClockLabel), \(labClock.framesPerSecond) fps")
            LabeledContent("Calendar", value: session.calendar.eventsGranted ? "Granted" : "Off")
            LabeledContent("Reminders", value: session.calendar.remindersGranted ? "Granted" : "Off")
            fact("Location", session.location.fix.labLabel)
            LabeledContent("Weather status", value: session.weatherStatus.rawValue)
            LabeledContent("Weather fetched", value: weatherFetchedLabel)
            if let error = session.weather.lastError {
                fact("Weather error (Lab)", error)
            }
            if let error = session.calendar.lastError {
                fact("Calendar error", error)
            }
            if let error = session.location.lastError {
                fact("Location error", error)
            }
        }
    }

    private var livingDay: some View {
        Section("Living Day") {
            Picker("Phase", selection: phaseBinding) {
                Text("Live clock").tag(DayPhase?.none)
                ForEach(DayPhase.allCases, id: \.self) { phase in
                    Text(phase.rawValue).tag(Optional(phase))
                }
            }
            .pickerStyle(.menu)
            Picker("Weather", selection: $session.weatherOverride) {
                Text("Live weather").tag(WeatherKind?.none)
                ForEach(WeatherKind.allCases) { kind in
                    Text(kind.rawValue).tag(Optional(kind))
                }
            }
            .pickerStyle(.menu)
            if let label = session.pinnedClockLabel {
                LabeledContent("Pinned clock", value: "\(label), \(session.solar.phase.rawValue)")
            }
            HStack(spacing: 8) {
                Button("Pin midnight") {
                    session.pinWallClock(hour24: 0, minute: 1)
                }
                Button("Pin noon") {
                    session.pinWallClock(hour24: 12, minute: 1)
                }
                Spacer(minLength: 0)
            }
            labButton("Force weather refresh") {
                Task {
                    await session.weather.refresh(
                        latitude: session.location.latitude,
                        longitude: session.location.longitude,
                        force: true
                    )
                }
            }
            labButton("Fail next weather request") {
                session.injectWeatherFailure()
            }
        }
    }

    private var phaseBinding: Binding<DayPhase?> {
        Binding(
            get: { session.pinnedPhase },
            set: { session.pinPhase($0) }
        )
    }

    private var memory: some View {
        Section("Ambient Memory") {
            if let live = session.calendar.nextItem, session.memoryOverride == nil, !session.hideMemory {
                fact("Live calendar", "\(live.caption(now: Date())) · \(live.title)")
            }
            labButton("Meeting in 8 min") {
                session.injectMemory(title: "Design review", minutesFromNow: 8, kind: .event)
            }
            labButton("Meeting in 2 hours") {
                session.injectMemory(title: "Ship Keep v1", minutesFromNow: 120, kind: .event)
            }
            labButton("Overdue reminder") {
                session.injectMemory(title: "Call Dad", minutesFromNow: -40, kind: .reminder)
            }
            labButton("All day event") {
                session.injectMemory(title: "Offsite", minutesFromNow: 0, kind: .event, isAllDay: true)
            }
            labButton("Hide memory overlay") {
                session.hideMemory = true
                session.memoryOverride = nil
            }
            labButton("Use live calendar") {
                session.useLiveMemory()
            }
            labButton("Refresh calendar now") {
                Task { await session.calendar.refresh() }
            }
        }
    }

    private var intention: some View {
        Section("Today’s Keep") {
            TextField("", text: $intentionDraft, prompt: Text("One thing not to forget"))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .onSubmit { session.intention.set(intentionDraft) }
            HStack(spacing: 8) {
                Button("Set") { session.intention.set(intentionDraft) }
                Button("Clear") {
                    intentionDraft = ""
                    session.intention.set("")
                }
                Button("Mark stale") { session.intention.markStaleForTesting() }
                Button("Keep it today") { session.intention.markReviewedToday() }
                Spacer(minLength: 0)
            }
            if session.intention.isStale, !session.intention.text.isEmpty {
                Text("Stale")
                    .foregroundStyle(.orange)
            }
        }
    }

    private var pause: some View {
        Section("Pause") {
            Toggle("User pause", isOn: $session.userPaused)
            Toggle(
                "Simulate sleep",
                isOn: Binding(
                    get: { session.power.simulatedAsleep },
                    set: { session.power.simulatedAsleep = $0 }
                )
            )
            Toggle(
                "Simulate screen lock",
                isOn: Binding(
                    get: { session.power.simulatedScreenLocked },
                    set: { session.power.simulatedScreenLocked = $0 }
                )
            )
            Toggle(
                "Simulate Low Power Mode",
                isOn: Binding(
                    get: { session.power.simulatedLowPower },
                    set: { session.power.simulatedLowPower = $0 }
                )
            )
            Toggle(
                "Simulate fullscreen",
                isOn: Binding(
                    get: { session.power.simulatedFullscreen },
                    set: { session.power.simulatedFullscreen = $0 }
                )
            )
            Toggle(
                "Pause in fullscreen",
                isOn: Binding(
                    get: { session.power.pauseWhenFullscreen },
                    set: { session.setPauseWhenFullscreen($0) }
                )
            )
            Toggle(
                "Pause on Low Power Mode",
                isOn: Binding(
                    get: { session.power.pauseOnLowPower },
                    set: { session.setPauseOnLowPower($0) }
                )
            )
            LabeledContent("Screen lock", value: session.power.hardwareScreenLocked ? "Locked" : "Unlocked")
            LabeledContent("Sleep", value: session.power.hardwareAsleep ? "Sleeping" : "Awake")
            LabeledContent("Low Power Mode", value: session.power.hardwareLowPowerMode ? "On" : "Off")
            fact("Display covering", session.power.occupancyLabLabel)
            LabeledContent("Wallpaper", value: session.isPaused ? "Paused, \(session.power.pauseReason)" : "Running")
        }
    }

    private var wallpaper: some View {
        Section("Desktop windows") {
            Toggle(
                "Show desktop wallpaper",
                isOn: Binding(
                    get: { session.wallpaper.isVisible },
                    set: { session.wallpaper.setVisible($0) }
                )
            )
            labButton("Rebuild display windows") {
                session.wallpaper.rebuild()
            }
        }
    }

    private var permissions: some View {
        Section("Permissions") {
            labButton("Request calendar and reminders") {
                Task { await session.calendar.requestAccessAndRefresh() }
            }
            labButton("Request location") {
                session.location.request()
            }
        }
    }

    private var onboarding: some View {
        Section("Onboarding") {
            LabeledContent("First run", value: session.didOnboard ? "Finished" : "Not finished")
            labButton("Replay first run") {
                session.replayOnboarding()
            }
        }
    }

    private var labPreviewClockLabel: String {
        let source = switch labClock.attachment {
        case .none: "Detached"
        case .window: "NSWindow.displayLink (unexpected on Lab)"
        case .screen: "NSScreen.displayLink"
        }
        let motion = labClock.isPaused ? "paused" : "running"
        return "\(source), \(motion)"
    }

    private var windowCountLabel: String {
        session.wallpaper.windowCount == 1 ? "1 window" : "\(session.wallpaper.windowCount) windows"
    }

    private var weatherFetchedLabel: String {
        let time = session.weather.lastUpdated.map { $0.formatted(date: .omitted, time: .standard) } ?? "Never"
        if let code = session.weather.lastWMOCode {
            return "\(time), code \(code)"
        }
        return time
    }

    private func fact(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labButton(_ title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Button(title, action: action)
            Spacer(minLength: 0)
        }
    }
}
