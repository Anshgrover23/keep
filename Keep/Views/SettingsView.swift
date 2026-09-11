import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Form {
            Section("Wallpaper") {
                Toggle(
                    "Show Keep on the desktop",
                    isOn: Binding(
                        get: { session.wallpaper.isVisible },
                        set: { session.wallpaper.setVisible($0) }
                    )
                )
            }
            Section("Atmosphere") {
                LabeledContent("Phase", value: session.solar.phase.rawValue.capitalized)
                LabeledContent("Weather", value: session.effectiveWeather.rawValue.capitalized)
                LabeledContent("Status", value: session.weatherStatus.rawValue.capitalized)
                Button("Refresh weather") {
                    Task {
                        await session.weather.refresh(
                            latitude: session.effectiveFix.weatherLatitude,
                            longitude: session.effectiveFix.longitude,
                            force: true
                        )
                    }
                }
            }
            Section("Calendar") {
                Toggle(
                    "Show events from Calendar",
                    isOn: Binding(
                        get: { session.showCalendarEvents },
                        set: { on in Task { await session.setShowCalendarEvents(on) } }
                    )
                )
                .accessibilityHint("Keep can show your next event from Calendar.")
                Text("Keep can show your next event from Calendar.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            Section("Location") {
                Toggle(
                    "Use local weather",
                    isOn: Binding(
                        get: { session.useLocalWeather },
                        set: { on in Task { await session.setUseLocalWeather(on) } }
                    )
                )
                .accessibilityHint("Keep can use your location for weather and daylight where you are.")
                Text("Keep can use your location for weather and daylight where you are.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            Section("Power") {
                Toggle(
                    "Pause in fullscreen apps",
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
            }
            Section("Menu bar") {
                Text("If Keep is running but the icon is gone, open System Settings, choose Menu Bar, and turn Keep on.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 560)
    }
}
