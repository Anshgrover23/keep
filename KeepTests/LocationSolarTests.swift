import CoreLocation
import Foundation
import Testing
@testable import Keep

struct TimezoneLongitudeTests {
    @Test func indiaOffsetIsEightyTwoPointFiveDegrees() {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let date = wallClock(year: 2026, month: 9, day: 11, hour: 0, minute: 1, timeZone: zone)
        #expect(TimezoneLongitude.degrees(timeZone: zone, at: date) == 82.5)
    }

    @Test func newYorkLongitudeShiftsWithDST() {
        let zone = TimeZone(identifier: "America/New_York")!
        let winter = wallClock(year: 2026, month: 1, day: 15, hour: 12, minute: 0, timeZone: zone)
        let summer = wallClock(year: 2026, month: 7, day: 15, hour: 12, minute: 0, timeZone: zone)
        #expect(TimezoneLongitude.degrees(timeZone: zone, at: winter) == -75)
        #expect(TimezoneLongitude.degrees(timeZone: zone, at: summer) == -60)
    }
}

struct LocationResolverTests {
    @Test func deniedAccessIgnoresMeasuredCoordinatesAndDoesNotInventLatitude23() {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let date = wallClock(year: 2026, month: 9, day: 11, hour: 0, minute: 1, timeZone: zone)
        let fix = LocationResolver.fix(
            access: .denied,
            measured: (latitude: 23, longitude: -122),
            timeZone: zone,
            at: date
        )
        #expect(fix == .timeZone(longitude: 82.5))
        if case .gps = fix {
            Issue.record("Denied location must not keep GPS or a fake tropic latitude")
        }
    }

    @Test func grantedMeasuredPositionIsGPS() {
        let fix = LocationResolver.fix(
            access: .granted,
            measured: (latitude: 64.15, longitude: -21.94),
            timeZone: TimeZone(identifier: "Atlantic/Reykjavik")!,
            at: Date()
        )
        #expect(fix == .gps(latitude: 64.15, longitude: -21.94))
    }

    @Test func grantedWithoutFixFallsBackToTimeZoneLongitude() {
        let zone = TimeZone(secondsFromGMT: Int(-TimeInterval.hours(8)))!
        let date = Date(timeIntervalSince1970: 0)
        let fix = LocationResolver.fix(access: .granted, measured: nil, timeZone: zone, at: date)
        #expect(fix == .timeZone(longitude: -120))
    }
}

struct SolarObserverTests {
    @Test func solarTimeFallbackKeepsMidnightNightAndNoonDayInIndia() {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let midnight = wallClock(year: 2026, month: 9, day: 11, hour: 0, minute: 1, timeZone: zone)
        let noon = wallClock(year: 2026, month: 9, day: 11, hour: 12, minute: 1, timeZone: zone)
        let observer = SolarObserver.solarTime(longitude: 82.5)
        #expect(SolarEngine.context(at: midnight, observer: observer).phase == .night)
        #expect(SolarEngine.context(at: midnight, observer: observer).isDay == false)
        let noonContext = SolarEngine.context(at: noon, observer: observer)
        #expect(noonContext.isDay)
        #expect(noonContext.phase != .night)
    }

    @Test func geographicTropicsStillMatchesLegacyGoldenCase() {
        let zone = TimeZone(identifier: "Asia/Kolkata")!
        let midnight = wallClock(year: 2026, month: 9, day: 11, hour: 0, minute: 1, timeZone: zone)
        let noon = wallClock(year: 2026, month: 9, day: 11, hour: 12, minute: 1, timeZone: zone)
        #expect(Daylight.context(at: midnight, latitude: 19, longitude: 72.8).phase == .night)
        #expect(Daylight.context(at: noon, latitude: 19, longitude: 72.8).isDay)
    }

    @Test func latitudeChangesPolarSummerMidnightWhichIsWhyWeDoNotInvent23Degrees() {
        let zone = TimeZone(identifier: "Atlantic/Reykjavik")!
        let midnight = wallClock(year: 2026, month: 6, day: 21, hour: 0, minute: 1, timeZone: zone)
        let lon = TimezoneLongitude.degrees(timeZone: zone, at: midnight)
        let geographic = SolarEngine.context(
            at: midnight,
            observer: .geographic(latitude: 64.15, longitude: lon)
        )
        let fakeTropic = SolarEngine.context(
            at: midnight,
            observer: .geographic(latitude: 23, longitude: lon)
        )
        let fallback = SolarEngine.context(at: midnight, observer: .solarTime(longitude: lon))
        #expect(fakeTropic.phase == .night)
        #expect(geographic.phase != .night)
        #expect(fallback.phase == .night)
    }
}

struct LocationAccessMappingTests {
    @Test func deniedAndRestrictedCannotRead() {
        #expect(LocationAccess.denied.canRead == false)
        #expect(LocationAccess.restricted.canRead == false)
        #expect(LocationAccess.notDetermined.canRead == false)
        #expect(LocationAccess.granted.canRead)
    }

    @Test func knownCoreLocationStatusesMapWithoutRawValueThree() {
        #expect(LocationProvider.map(.authorized) == .granted)
        #expect(LocationProvider.map(.authorizedAlways) == .granted)
        #expect(LocationProvider.map(.denied) == .denied)
        #expect(LocationProvider.map(.notDetermined) == .notDetermined)
        #expect(LocationProvider.map(.restricted) == .restricted)
    }

    @Test func unknownRawStatusIsDenied() {
        let mystery = CLAuthorizationStatus(rawValue: 99)!
        #expect(LocationProvider.map(mystery) == .denied)
    }
}

private func wallClock(year: Int, month: Int, day: Int, hour: Int, minute: Int, timeZone: TimeZone) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components)!
}
