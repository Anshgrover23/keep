import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keep")
                .font(.system(size: 22, weight: .light, design: .serif))
                .accessibilityAddTraits(.isHeader)

            calendarGlanceBlock

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today’s Keep")
                        .font(.system(size: 12, weight: .medium))
                    if session.intention.isStale, !session.intention.text.isEmpty {
                        Text("from yesterday")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                }
                Button {
                    IntentionEditorWindow.present(session: session)
                } label: {
                    HStack {
                        Text(session.intention.text.isEmpty ? "One thing not to forget" : session.intention.text)
                            .foregroundStyle(session.intention.text.isEmpty ? .secondary : .primary)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit today’s Keep")
                .accessibilityValue(session.intention.text.isEmpty ? "Empty" : session.intention.text)
                if session.intention.isStale {
                    Button("Keep it today") {
                        session.intention.markReviewedToday()
                    }
                }
            }

            Divider()

            Toggle("Pause wallpaper", isOn: $session.userPaused)
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

            HStack {
                SettingsLink {
                    Text("Settings")
                }
                .accessibilityLabel("Settings")
                LabOpenButton()
                Spacer()
                Button("Quit Keep") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    @ViewBuilder
    private var calendarGlanceBlock: some View {
        switch session.calendarGlance {
        case .upcoming(let caption, let title):
            VStack(alignment: .leading, spacing: 4) {
                Text(caption.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .lineLimit(2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(caption), \(title)")
        case .empty:
            Text("Nothing upcoming. The day can stay quiet.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        case .notGranted:
            Text("Keep can show your next event.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var session: AppSession

    var body: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.monochrome)
            .help(session.menuCaption)
            .accessibilityLabel(session.menuCaption)
    }

    private var symbol: String {
        switch session.effectiveWeather {
        case .rain, .storm: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .fog: "cloud.fog.fill"
        case .cloudy: "cloud.sun.fill"
        case .clear:
            switch session.solar.phase {
            case .night: "moon.stars.fill"
            case .dawn, .dusk: "sun.horizon.fill"
            default: "sun.max.fill"
            }
        }
    }
}

/// MenuBarExtra windows cannot become key. Editing happens in this panel, which we own.
@MainActor
enum IntentionEditorWindow {
    private static var panel: KeyableEditorPanel?
    private static var closeObserver: NSObjectProtocol?

    static func present(session: AppSession) {
        if let panel {
            session.intentionEditorDidAppear()
            NSApp.setActivationPolicy(.regular)
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let root = IntentionEditorView(session: session)
        let hosting = NSHostingController(rootView: root)
        let panel = KeyableEditorPanel(contentViewController: hosting)
        panel.title = "Today’s Keep"
        panel.styleMask = [.titled, .closable]
        panel.isReleasedWhenClosed = false
        panel.setContentSize(NSSize(width: 380, height: 180))
        panel.center()
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { _ in
            Task { @MainActor in
                session.intentionEditorDidDisappear()
                Self.panel = nil
            }
        }
        session.intentionEditorDidAppear()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Self.panel = panel
    }

    static func dismiss() {
        panel?.close()
    }
}

private final class KeyableEditorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private struct IntentionEditorView: View {
    @ObservedObject var session: AppSession
    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Keep")
                .font(.system(size: 13, weight: .medium))
            TextField("One thing not to forget", text: $draft)
                .textFieldStyle(.roundedBorder)
                .focused($fieldFocused)
                .accessibilityLabel("Today’s Keep")
                .onSubmit { session.intention.set(draft) }
            HStack {
                Button("Cancel") {
                    IntentionEditorWindow.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { session.intention.set(draft) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(minWidth: 340)
        .onAppear {
            draft = session.intention.text
            fieldFocused = true
        }
    }
}

struct LabOpenButton: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Button("Lab") {
            LabWindow.present(session: session)
        }
        .accessibilityLabel("Lab")
    }
}
