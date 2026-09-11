import Foundation

@MainActor
protocol SettingsStore: AnyObject {
    var didOnboard: Bool { get set }
    var pauseWhenFullscreen: Bool { get set }
    var pauseOnLowPower: Bool { get set }
    var intentionText: String { get set }
    var intentionDay: String { get set }
    var showCalendarEvents: Bool { get set }
    var useLocalWeather: Bool { get set }
}

@MainActor
final class AppSettings: SettingsStore {
    var defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        ensureSchema()
    }

    static let production = AppSettings(defaults: .standard)

    /// Current Keep settings layout. Missing key becomes this value. A higher stored value is left alone.
    static let currentSchemaVersion = 1

    private enum Key {
        static let schemaVersion = "keep.schemaVersion"
        static let didOnboard = "keep.didOnboard"
        static let pauseFullscreen = "keep.pauseFullscreen"
        static let pauseLowPower = "keep.pauseLowPower"
        static let intentionText = "keep.intention.text"
        static let intentionDay = "keep.intention.day"
        static let showCalendarEvents = "keep.showCalendarEvents"
        static let useLocalWeather = "keep.useLocalWeather"
    }

    var schemaVersion: Int {
        guard defaults.object(forKey: Key.schemaVersion) != nil else { return 0 }
        return defaults.integer(forKey: Key.schemaVersion)
    }

    /// Stamp version 1 when absent. Do not rewrite other keys. Do not downgrade a newer version.
    private func ensureSchema() {
        if defaults.object(forKey: Key.schemaVersion) == nil {
            defaults.set(Self.currentSchemaVersion, forKey: Key.schemaVersion)
        }
    }

    var didOnboard: Bool {
        get { defaults.bool(forKey: Key.didOnboard) }
        set { defaults.set(newValue, forKey: Key.didOnboard) }
    }

    var pauseWhenFullscreen: Bool {
        get { defaults.object(forKey: Key.pauseFullscreen) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.pauseFullscreen) }
    }

    var pauseOnLowPower: Bool {
        get { defaults.object(forKey: Key.pauseLowPower) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.pauseLowPower) }
    }

    var intentionText: String {
        get { defaults.string(forKey: Key.intentionText) ?? "" }
        set { defaults.set(newValue, forKey: Key.intentionText) }
    }

    var intentionDay: String {
        get { defaults.string(forKey: Key.intentionDay) ?? "" }
        set { defaults.set(newValue, forKey: Key.intentionDay) }
    }

    var showCalendarEvents: Bool {
        get { defaults.object(forKey: Key.showCalendarEvents) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.showCalendarEvents) }
    }

    var useLocalWeather: Bool {
        get { defaults.object(forKey: Key.useLocalWeather) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.useLocalWeather) }
    }

    func resetForTests() {
        [Key.schemaVersion, Key.didOnboard, Key.pauseFullscreen, Key.pauseLowPower, Key.intentionText, Key.intentionDay, Key.showCalendarEvents, Key.useLocalWeather]
            .forEach { defaults.removeObject(forKey: $0) }
    }
}
