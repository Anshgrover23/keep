import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var session: AppSession
    @State private var intentionDraft = ""
    @FocusState private var intentionFocused: Bool

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
                TextField("", text: $intentionDraft, prompt: Text("One thing not to forget"))
                    .textFieldStyle(.roundedBorder)
                    .focused($intentionFocused)
                    .labelsHidden()
                    .accessibilityLabel("Today’s Keep")
                    .onSubmit { commitIntention() }
                if session.intention.isStale {
                    Button("Keep it today") {
                        session.intention.markReviewedToday()
                    }
                }
            }
            .background(ExtraKeyAttempt())

            Divider()

            Toggle("Pause wallpaper", isOn: $session.userPaused)

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
        .onAppear {
            intentionDraft = session.intention.text
            session.menuExtraDidAppear()
            intentionFocused = true
        }
        .onDisappear {
            commitIntention()
            session.menuExtraDidDisappear()
        }
        .onChange(of: session.intention.text) { _, value in
            if value != intentionDraft.trimmingCharacters(in: .whitespacesAndNewlines) {
                intentionDraft = value
            }
        }
    }

    private func commitIntention() {
        session.intention.set(intentionDraft)
        intentionDraft = session.intention.text
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

/// Asks the extra window to take keys without swapping its class.
private struct ExtraKeyAttempt: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ExtraKeyAttemptView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class ExtraKeyAttemptView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
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
