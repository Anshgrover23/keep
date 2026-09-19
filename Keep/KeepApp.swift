import SwiftUI

@main
struct KeepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.session)
        } label: {
            MenuBarLabel(session: appDelegate.session)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.session)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let session: AppSession

    override init() {
        session = AppSession.makeProduction()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["KEEP_GLASS_CYCLE"] == "1" {
            NSApp.setActivationPolicy(.regular)
            session.start()
            Task {
                await GlassCycleWindow.record(session: session, thenQuit: true)
            }
            return
        }
        session.start()
        NSApp.setActivationPolicy(.accessory)
        if session.needsOnboarding {
            OnboardingWindow.present(session: session)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if session.needsOnboarding {
            OnboardingWindow.present(session: session)
            return false
        }
        LabWindow.present(session: session)
        return false
    }
}
