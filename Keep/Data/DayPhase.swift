import Foundation

enum DayPhase: String, CaseIterable, Sendable {
    case night
    case dawn
    case morning
    case noon
    case afternoon
    case dusk

    /// Light ink when the sky is dark: night bands, or a weather wash that greys the day.
    func overlayPrefersLightInk(weather: WeatherKind) -> Bool {
        if weather.darkensSky { return true }
        switch self {
        case .night, .dusk, .dawn: return true
        case .morning, .noon, .afternoon: return false
        }
    }
}

enum WeatherKind: String, CaseIterable, Identifiable, Sendable {
    var id: String { rawValue }
    case clear
    case cloudy
    case fog
    case rain
    case snow
    case storm

    /// Rain, storm, and fog darken the wash. Overlay ink follows that, not phase alone.
    var darkensSky: Bool {
        switch self {
        case .rain, .storm, .fog: return true
        case .clear, .cloudy, .snow: return false
        }
    }

    init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1, 2, 3: self = .cloudy
        case 45, 48: self = .fog
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: self = .rain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .storm
        default: self = .cloudy
        }
    }
}

struct SolarContext: Sendable {
    var phase: DayPhase
    var sunProgress: Double
    var moonProgress: Double
    var elevation: Double
    var isDay: Bool
}

/// Astronomical day model. Does not invent wall clock noon from the 12 hour clock.
enum SolarEngine {
    /// Minutes from midnight to midnight. Used to sample phases across one civil day.
    static let minutesPerDay = KeepTime.minutesPerCivilDay
    /// Sample stride in minutes when hunting a date for a pinned Lab phase.
    static let phaseSampleStrideMinutes = 8

    static func context(at date: Date, observer: SolarObserver) -> SolarContext {
        switch observer {
        case .geographic(let latitude, let longitude):
            return Daylight.elevationContext(at: date, latitude: latitude, longitude: longitude)
        case .solarTime(let longitude):
            return Daylight.solarTimeContext(at: date, longitude: longitude)
        }
    }

    static func context(at date: Date, latitude: Double, longitude: Double) -> SolarContext {
        context(at: date, observer: .geographic(latitude: latitude, longitude: longitude))
    }

    static func date(
        representing phase: DayPhase,
        near reference: Date = Date(),
        observer: SolarObserver
    ) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: reference)
        var matches: [Date] = []
        for minute in stride(from: 0, to: minutesPerDay, by: phaseSampleStrideMinutes) {
            let date = start.addingTimeInterval(.minutes(minute))
            if context(at: date, observer: observer).phase == phase {
                matches.append(date)
            }
        }
        if matches.isEmpty { return reference }
        return matches[matches.count / 2]
    }

    static func date(
        representing phase: DayPhase,
        near reference: Date = Date(),
        latitude: Double,
        longitude: Double
    ) -> Date {
        date(
            representing: phase,
            near: reference,
            observer: .geographic(latitude: latitude, longitude: longitude)
        )
    }
}

/// Named solar and earth measures used by elevation and time zone longitude.
enum SolarMath {
    static let fullCircleDegrees = 360.0
    static let halfCircleDegrees = 180.0
    static let rightAngleDegrees = 90.0
    static let earthObliquityDegrees = 23.44
    static let meanTropicalYearDays = 365.0
    static let solsticeOffsetDays = 10.0
    static let degreesPerHour = 15.0
    static let solarMiddayHours = 12.0
    static let approximateSunsetHours = 18.0
    static let sunriseRefractionDegrees = 0.83
    static let nightElevationDegrees = -6.0
    static let twilightElevationDegrees = 8.0
    static let noonHourAngleDegrees = 22.0
    static let noonElevationDegrees = 28.0
    static let dayNightElevationDegrees = -0.5
    static let minimumSpanHours = 0.5
    static let bothSidesOfNoon = 2.0
    static let sunProgressMax = 1.2
    static let sunProgressMin = -0.2
    static let equatorLatitude = 0.0
    static let uncomputedElevation = 0.0
    static let maxLongitudeDegrees = 180.0
    static let dawnStartHour = 5.0
    static let morningStartHour = 7.0
    static let noonStartHour = 11.0
    static let afternoonStartHour = 13.0
    static let duskStartHour = 17.0
    static let nightStartHour = 19.0
    static let approximateDayLengthHours = 12.0

    static func hourAngleDegrees(solarTimeHours: Double) -> Double {
        (solarTimeHours - solarMiddayHours) * degreesPerHour
    }

    static func longitudeDegrees(fromOffsetHours hours: Double) -> Double {
        let raw = hours * degreesPerHour
        return min(maxLongitudeDegrees, max(-maxLongitudeDegrees, raw))
    }

    static func hoursFromLongitude(_ longitude: Double) -> Double {
        longitude / degreesPerHour
    }

    static func dayAngleDegrees(dayOfYear: Double) -> Double {
        (fullCircleDegrees / meanTropicalYearDays) * (dayOfYear + solsticeOffsetDays)
    }

    static func declinationDegrees(dayOfYear: Double) -> Double {
        -earthObliquityDegrees * cos(degreesToRadians(dayAngleDegrees(dayOfYear: dayOfYear)))
    }

    static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / halfCircleDegrees
    }

    static func radiansToDegrees(_ radians: Double) -> Double {
        radians * halfCircleDegrees / .pi
    }

    static func sineOfElevation(latitudeRadians: Double, declinationRadians: Double, hourAngleRadians: Double) -> Double {
        sin(latitudeRadians) * sin(declinationRadians)
            + cos(latitudeRadians) * cos(declinationRadians) * cos(hourAngleRadians)
    }

    static func cosineOfSunriseHourAngle(latitudeRadians: Double, declinationRadians: Double) -> Double {
        let refraction = sin(degreesToRadians(-sunriseRefractionDegrees))
        return (refraction - sin(latitudeRadians) * sin(declinationRadians))
            / (cos(latitudeRadians) * cos(declinationRadians))
    }

    static func daylightSpanHours(halfDayHourAngleDegrees: Double) -> Double {
        max(minimumSpanHours, (bothSidesOfNoon * halfDayHourAngleDegrees) / degreesPerHour)
    }

    static func sunProgress(hourAngleDegrees: Double, halfDayHourAngleDegrees: Double) -> Double {
        (hourAngleDegrees + halfDayHourAngleDegrees) / (bothSidesOfNoon * halfDayHourAngleDegrees)
    }

    static func hoursAfterSunset(solarTimeHours: Double, halfDayHourAngleDegrees: Double) -> Double {
        solarTimeHours - (solarMiddayHours + halfDayHourAngleDegrees / degreesPerHour)
    }

    static func approximateSunProgress(hourAngleDegrees: Double) -> Double {
        (hourAngleDegrees + rightAngleDegrees) / halfCircleDegrees
    }
}

enum Daylight {
    /// Sky from solar elevation at a known latitude/longitude.
    static func context(at date: Date, latitude: Double, longitude: Double) -> SolarContext {
        elevationContext(at: date, latitude: latitude, longitude: longitude)
    }

    static func elevationContext(at date: Date, latitude: Double, longitude: Double) -> SolarContext {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC")!

        let dayOfYear = Double(utcCalendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let declination = SolarMath.declinationDegrees(dayOfYear: dayOfYear)
        let latRad = SolarMath.degreesToRadians(latitude)
        let decRad = SolarMath.degreesToRadians(declination)

        let utcHours = hoursInDay(date, calendar: utcCalendar)
        // Local solar time at this longitude. SolarMath.solarMiddayHours is solar midday, not 12:00 AM.
        let solarTime = wrapDay(utcHours + SolarMath.hoursFromLongitude(longitude))
        let hourAngleDeg = SolarMath.hourAngleDegrees(solarTimeHours: solarTime)
        let hourAngleRad = SolarMath.degreesToRadians(hourAngleDeg)

        let sinEl = SolarMath.sineOfElevation(
            latitudeRadians: latRad,
            declinationRadians: decRad,
            hourAngleRadians: hourAngleRad
        )
        let elevation = SolarMath.radiansToDegrees(asin(min(1, max(-1, sinEl))))

        let cosHA = SolarMath.cosineOfSunriseHourAngle(latitudeRadians: latRad, declinationRadians: decRad)
        let ha = acos(min(1, max(-1, cosHA)))
        let haDeg = SolarMath.radiansToDegrees(ha)
        let daySpan = SolarMath.daylightSpanHours(halfDayHourAngleDegrees: haDeg)
        let sunProgress = SolarMath.sunProgress(hourAngleDegrees: hourAngleDeg, halfDayHourAngleDegrees: haDeg)
        let nightSpan = max(SolarMath.minimumSpanHours, Double(KeepTime.hoursPerDay) - daySpan)
        let hoursAfterSunset = wrapDay(SolarMath.hoursAfterSunset(solarTimeHours: solarTime, halfDayHourAngleDegrees: haDeg))
        let moonProgress = elevation <= 0 ? min(1, hoursAfterSunset / nightSpan) : 0
        let rising = hourAngleDeg < 0

        let phase: DayPhase
        if elevation < SolarMath.nightElevationDegrees {
            phase = .night
        } else if elevation < SolarMath.twilightElevationDegrees {
            phase = rising ? .dawn : .dusk
        } else if abs(hourAngleDeg) < SolarMath.noonHourAngleDegrees, elevation >= SolarMath.noonElevationDegrees {
            phase = .noon
        } else if rising {
            phase = .morning
        } else {
            phase = .afternoon
        }

        return SolarContext(
            phase: phase,
            sunProgress: min(SolarMath.sunProgressMax, max(SolarMath.sunProgressMin, sunProgress)),
            moonProgress: min(1, max(0, moonProgress)),
            elevation: elevation,
            isDay: elevation > SolarMath.dayNightElevationDegrees
        )
    }

    /// Keep fallback when latitude is unknown. Phase follows local solar time at `longitude`.
    /// Day length is a 12 hour visual approximation, not polar astronomy.
    static func solarTimeContext(at date: Date, longitude: Double) -> SolarContext {
        let solarTime = solarTimeHours(at: date, longitude: longitude)
        let hourAngleDeg = SolarMath.hourAngleDegrees(solarTimeHours: solarTime)
        let phase: DayPhase
        switch solarTime {
        case SolarMath.dawnStartHour..<SolarMath.morningStartHour: phase = .dawn
        case SolarMath.morningStartHour..<SolarMath.noonStartHour: phase = .morning
        case SolarMath.noonStartHour..<SolarMath.afternoonStartHour: phase = .noon
        case SolarMath.afternoonStartHour..<SolarMath.duskStartHour: phase = .afternoon
        case SolarMath.duskStartHour..<SolarMath.nightStartHour: phase = .dusk
        default: phase = .night
        }
        let sunProgress = SolarMath.approximateSunProgress(hourAngleDegrees: hourAngleDeg)
        let hoursAfterSunset = wrapDay(solarTime - SolarMath.approximateSunsetHours)
        let moonProgress = phase == .night ? min(1, hoursAfterSunset / SolarMath.approximateDayLengthHours) : 0
        return SolarContext(
            phase: phase,
            sunProgress: min(SolarMath.sunProgressMax, max(SolarMath.sunProgressMin, sunProgress)),
            moonProgress: min(1, max(0, moonProgress)),
            elevation: SolarMath.uncomputedElevation,
            isDay: phase != .night
        )
    }

    static func solarTimeHours(at date: Date, longitude: Double) -> Double {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "UTC")!
        return wrapDay(hoursInDay(date, calendar: utcCalendar) + SolarMath.hoursFromLongitude(longitude))
    }

    private static func hoursInDay(_ date: Date, calendar: Calendar) -> Double {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double(parts.hour ?? 0)
            + Double(parts.minute ?? 0) / Double(KeepTime.minutesPerHour)
            + Double(parts.second ?? 0) / KeepTime.secondsPerHour
    }

    private static func wrapDay(_ hours: Double) -> Double {
        let length = Double(KeepTime.hoursPerDay)
        var value = hours.truncatingRemainder(dividingBy: length)
        if value < 0 { value += length }
        return value
    }

    static func date(
        representing phase: DayPhase,
        near reference: Date = Date(),
        latitude: Double,
        longitude: Double
    ) -> Date {
        SolarEngine.date(
            representing: phase,
            near: reference,
            latitude: latitude,
            longitude: longitude
        )
    }
}
