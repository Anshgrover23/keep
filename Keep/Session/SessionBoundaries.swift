import AppKit
import Combine
import Foundation

/// EventKit stays behind this boundary. Callers receive `MemoryItem` only.
@MainActor
protocol CalendarReading: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    var nextItem: MemoryItem? { get }
    var eventsGranted: Bool { get }
    var remindersGranted: Bool { get }
    var lastError: String? { get }
    var accessGranted: Bool { get }
    func start()
    func requestAccessAndRefresh() async
    func refresh() async
}

@MainActor
protocol WeatherFetching: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    var kind: WeatherKind { get }
    var lastUpdated: Date? { get }
    var lastError: String? { get }
    var lastWMOCode: Int? { get }
    func refresh(latitude: Double, longitude: Double, force: Bool) async
    func failNextRefresh() async
}

@MainActor
protocol LocationProviding: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    var fix: LocationFix { get }
    var access: LocationAccess { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var authorized: Bool { get }
    var lastError: String? { get }
    func start()
    func request()
}

@MainActor
protocol AppActivation {
    func becomeRegular()
    func becomeAccessory()
}

@MainActor
struct AppKitActivation: AppActivation {
    func becomeRegular() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func becomeAccessory() {
        NSApp.setActivationPolicy(.accessory)
    }
}

@MainActor
struct NoOpActivation: AppActivation {
    func becomeRegular() {}
    func becomeAccessory() {}
}
