import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationProvider: NSObject, ObservableObject, LocationProviding {
    @Published private(set) var fix: LocationFix
    @Published private(set) var access: LocationAccess
    @Published private(set) var lastError: String?

    var latitude: Double { fix.weatherLatitude }
    var longitude: Double { fix.longitude }
    var authorized: Bool { access.canRead }

    private let manager = CLLocationManager()
    private var measured: (latitude: Double, longitude: Double)?
    private let timeZone: TimeZone
    private let now: () -> Date

    init(timeZone: TimeZone = .current, now: @escaping () -> Date = Date.init) {
        self.timeZone = timeZone
        self.now = now
        access = .notDetermined
        fix = .timeZone(longitude: TimezoneLongitude.degrees(timeZone: timeZone, at: now()))
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        apply(status: manager.authorizationStatus)
    }

    /// Use existing permission if any; do not prompt.
    func start() {
        apply(status: manager.authorizationStatus)
        if access.canRead {
            manager.requestLocation()
        }
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        if access.canRead {
            manager.requestLocation()
        }
    }

    private func apply(status: CLAuthorizationStatus) {
        access = Self.map(status)
        fix = LocationResolver.fix(
            access: access,
            measured: measured,
            timeZone: timeZone,
            at: now()
        )
    }

    nonisolated static func map(_ status: CLAuthorizationStatus) -> LocationAccess {
        switch status {
        case .authorized, .authorizedAlways:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            KeepLog.location.error("Unknown CoreLocation authorization status")
            return .denied
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            apply(status: status)
            if access.canRead {
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        Task { @MainActor in
            measured = (latitude, longitude)
            lastError = nil
            apply(status: self.manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            lastError = message
            apply(status: self.manager.authorizationStatus)
        }
    }
}
