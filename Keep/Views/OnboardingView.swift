import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var session: AppSession
    var onDone: () -> Void
    @State private var draft = ""
    @State private var requestingCalendar = false
    @FocusState private var intentionFocused: Bool

    private var canStart: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Keep")
                .font(.system(size: 34, weight: .light, design: .serif))
            Text("Your wallpaper becomes a living day: light, weather, and today’s Keep.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Today’s Keep")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.4)
                TextField("Ship the wallpaper, call Dad…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($intentionFocused)
                    .accessibilityLabel("Today’s Keep")
                    .accessibilityHint("This line sits on the desktop.")
                    .onSubmit { finish() }
                helper("This line sits on the desktop.")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Optional")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Toggle(
                    "Show events from Calendar",
                    isOn: Binding(
                        get: { session.showCalendarEvents },
                        set: { on in
                            Task {
                                requestingCalendar = true
                                await session.setShowCalendarEvents(on)
                                requestingCalendar = false
                            }
                        }
                    )
                )
                .disabled(requestingCalendar)
                .accessibilityHint("Keep can show your next event from Calendar.")
                helper("Keep can show your next event from Calendar.")
                Toggle(
                    "Use local weather",
                    isOn: Binding(
                        get: { session.useLocalWeather },
                        set: { on in Task { await session.setUseLocalWeather(on) } }
                    )
                )
                .accessibilityHint("Keep can use your location for weather and daylight.")
                helper("Keep can use your location for weather and daylight.")
            }

            HStack {
                Spacer()
                Button("Start the day") { finish() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canStart)
            }
        }
        .padding(28)
        .frame(width: 480)
        .onAppear {
            draft = session.intention.text
            intentionFocused = true
        }
    }

    private func helper(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
    }

    private func finish() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        session.intention.set(text)
        session.finishOnboarding()
        onDone()
    }
}

@MainActor
enum OnboardingWindow {
    private static var window: NSWindow?
    private static var closeObserver: NSObjectProtocol?

    static var retainedWindowForTesting: NSWindow? { window }

    static func resetForTesting() {
        if let observer = closeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        closeObserver = nil
        window?.close()
        window = nil
    }

    static func present(session: AppSession) {
        if let window {
            session.onboardingDidAppear()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let root = OnboardingView(session: session) {
            window?.close()
        }
        let hosting = NSHostingController(rootView: root)
        let panel = NSWindow(contentViewController: hosting)
        panel.title = "Keep"
        panel.styleMask = [.titled, .closable]
        panel.isReleasedWhenClosed = false
        panel.center()
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { _ in
            Task { @MainActor in
                session.onboardingDidDisappear()
                Self.window = nil
            }
        }
        session.onboardingDidAppear()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
    }
}

@MainActor
enum LabWindow {
    private static var window: NSWindow?
    private static var closeObserver: NSObjectProtocol?

    static func present(session: AppSession) {
        if let window {
            NSApp.setActivationPolicy(.regular)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            session.labDidAppear()
            return
        }
        let hosting = NSHostingController(rootView: LabView().environmentObject(session))
        let panel = NSWindow(contentViewController: hosting)
        panel.title = "Keep Lab"
        panel.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        panel.setContentSize(NSSize(width: 1180, height: 740))
        panel.minSize = NSSize(width: 900, height: 560)
        panel.center()
        panel.isReleasedWhenClosed = false
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { _ in
            Task { @MainActor in
                session.labDidDisappear()
            }
        }
        NSApp.setActivationPolicy(.regular)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = panel
    }
}
