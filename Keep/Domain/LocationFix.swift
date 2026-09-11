import Foundation

enum LocationAccess: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
    case restricted

    var canRead: Bool { self == .granted }
}

/// Where Keep thinks the observer is. GPS is measured; time zone longitude is a Keep fallback, not a city.
enum LocationFix: Equatable, Sendable {
    case gps(latitude: Double, longitude: Double)
    /// Longitude only (15 degrees per hour of GMT offset, DST aware). Latitude is unknown.
    case timeZone(longitude: Double)

    var longitude: Double {
        switch self {
        case .gps(_, let longitude), .timeZone(let longitude):
            return longitude
        }
    }

    /// Open Meteo still needs a latitude. Unknown latitude uses the equator and must be labeled as approximate.
    var weatherLatitude: Double {
        switch self {
        case .gps(let latitude, _):
            return latitude
        case .timeZone:
            return SolarMath.equatorLatitude
        }
    }

    var isMeasured: Bool {
        if case .gps = self { return true }
        return false
    }

    var solarObserver: SolarObserver {
        switch self {
        case .gps(let latitude, let longitude):
            return .geographic(latitude: latitude, longitude: longitude)
        case .timeZone(let longitude):
            return .solarTime(longitude: longitude)
        }
    }

    var labLabel: String {
        switch self {
        case .gps(let latitude, let longitude):
            return String(format: "GPS %.2f, %.2f", latitude, longitude)
        case .timeZone(let longitude):
            return String(format: "TZ longitude %.1f° (latitude unknown)", longitude)
        }
    }
}

enum SolarObserver: Equatable, Sendable {
    /// Full elevation model.
    case geographic(latitude: Double, longitude: Double)
    /// Keep fallback: phase from solar time at this longitude. Day length is not polar accurate.
    case solarTime(longitude: Double)
}

/// Keep fallback: zone offset at `date` times 15 degrees. Not Apple geography and not a city coordinate.
enum TimezoneLongitude {
    static func degrees(timeZone: TimeZone, at date: Date) -> Double {
        let hours = Double(timeZone.secondsFromGMT(for: date)) / KeepTime.secondsPerHour
        return SolarMath.longitudeDegrees(fromOffsetHours: hours)
    }
}

enum LocationResolver {
    static func fix(
        access: LocationAccess,
        measured: (latitude: Double, longitude: Double)?,
        timeZone: TimeZone,
        at date: Date
    ) -> LocationFix {
        if access.canRead, let measured {
            return .gps(latitude: measured.latitude, longitude: measured.longitude)
        }
        return .timeZone(longitude: TimezoneLongitude.degrees(timeZone: timeZone, at: date))
    }
}
