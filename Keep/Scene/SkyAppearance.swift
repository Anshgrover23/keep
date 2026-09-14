import AppKit
import SwiftUI

struct SkyPalette: Sendable {
    var top: Color
    var mid: Color
    var horizon: Color
    var sun: Color
    var glow: Color
    var starOpacity: Double
    var haze: Double
}

enum SkyAppearance {
    static func palette(phase: DayPhase, weather: WeatherKind) -> SkyPalette {
        var palette: SkyPalette
        switch phase {
        case .night:
            palette = SkyPalette(
                top: Color(red: 0.04, green: 0.06, blue: 0.14),
                mid: Color(red: 0.08, green: 0.10, blue: 0.22),
                horizon: Color(red: 0.12, green: 0.12, blue: 0.24),
                sun: Color(red: 0.86, green: 0.88, blue: 0.94),
                glow: Color(red: 0.35, green: 0.40, blue: 0.62),
                starOpacity: 0.9,
                haze: 0.08
            )
        case .dawn:
            palette = SkyPalette(
                top: Color(red: 0.18, green: 0.12, blue: 0.32),
                mid: Color(red: 0.78, green: 0.32, blue: 0.34),
                horizon: Color(red: 1.0, green: 0.72, blue: 0.42),
                sun: Color(red: 1.0, green: 0.86, blue: 0.62),
                glow: Color(red: 1.0, green: 0.55, blue: 0.32),
                starOpacity: 0.15,
                haze: 0.18
            )
        case .morning:
            palette = SkyPalette(
                top: Color(red: 0.56, green: 0.78, blue: 0.94),
                mid: Color(red: 0.82, green: 0.91, blue: 0.98),
                horizon: Color(red: 0.97, green: 0.96, blue: 0.94),
                sun: Color(red: 1.0, green: 0.96, blue: 0.82),
                glow: Color(red: 1.0, green: 0.93, blue: 0.74),
                starOpacity: 0,
                haze: 0.10
            )
        case .noon:
            palette = SkyPalette(
                top: Color(red: 0.14, green: 0.40, blue: 0.80),
                mid: Color(red: 0.36, green: 0.66, blue: 0.92),
                horizon: Color(red: 0.70, green: 0.86, blue: 0.96),
                sun: Color(red: 1.0, green: 0.97, blue: 0.88),
                glow: Color(red: 1.0, green: 0.96, blue: 0.84),
                starOpacity: 0,
                haze: 0.26
            )
        case .afternoon:
            palette = SkyPalette(
                top: Color(red: 0.34, green: 0.48, blue: 0.68),
                mid: Color(red: 0.78, green: 0.66, blue: 0.52),
                horizon: Color(red: 0.98, green: 0.76, blue: 0.46),
                sun: Color(red: 1.0, green: 0.80, blue: 0.44),
                glow: Color(red: 1.0, green: 0.62, blue: 0.28),
                starOpacity: 0,
                haze: 0.18
            )
        case .dusk:
            palette = SkyPalette(
                top: Color(red: 0.12, green: 0.10, blue: 0.28),
                mid: Color(red: 0.72, green: 0.28, blue: 0.22),
                horizon: Color(red: 0.95, green: 0.48, blue: 0.22),
                sun: Color(red: 1.0, green: 0.70, blue: 0.38),
                glow: Color(red: 0.95, green: 0.35, blue: 0.18),
                starOpacity: 0.25,
                haze: 0.2
            )
        }

        switch weather {
        case .clear:
            break
        case .cloudy:
            palette.top = palette.top.mix(with: Color(white: WeatherWash.cloudyTopWhite), by: WeatherWash.cloudyTopMix)
            palette.mid = palette.mid.mix(with: Color(white: WeatherWash.cloudyMidWhite), by: WeatherWash.cloudyMidMix)
            palette.horizon = palette.horizon.mix(with: Color(white: WeatherWash.cloudyHorizonWhite), by: WeatherWash.cloudyHorizonMix)
            palette.haze += WeatherWash.cloudyHazeAdd
            palette.starOpacity *= WeatherWash.cloudyStarFactor
        case .fog:
            palette.top = palette.top.mix(with: Color(white: WeatherWash.fogTopWhite), by: WeatherWash.fogTopMix)
            palette.mid = Color(white: WeatherWash.fogMidWhite)
            palette.horizon = Color(white: WeatherWash.fogHorizonWhite)
            palette.haze = WeatherWash.fogHaze
            palette.starOpacity = 0
        case .rain, .storm:
            palette.top = palette.top.mix(with: WeatherWash.rainTop, by: WeatherWash.rainTopMix)
            palette.mid = palette.mid.mix(with: WeatherWash.rainMid, by: WeatherWash.rainMidMix)
            palette.horizon = palette.horizon.mix(with: WeatherWash.rainHorizon, by: WeatherWash.rainHorizonMix)
            palette.haze += WeatherWash.rainHazeAdd
            palette.starOpacity = 0
        case .snow:
            palette.top = palette.top.mix(with: WeatherWash.snowTop, by: WeatherWash.snowTopMix)
            palette.mid = palette.mid.mix(with: Color(white: WeatherWash.snowMidWhite), by: WeatherWash.snowMidMix)
            palette.horizon = Color(white: WeatherWash.snowHorizonWhite)
            palette.haze += WeatherWash.snowHazeAdd
            palette.starOpacity *= WeatherWash.snowStarFactor
        }

        return palette
    }
}

extension DayPhase {
    func overlayTextColor(weather: WeatherKind) -> Color {
        if overlayPrefersLightInk(weather: weather) {
            return TypeColor.light
        }
        return TypeColor.dark
    }

    func overlayCaptionColor(weather: WeatherKind) -> Color {
        overlayTextColor(weather: weather).opacity(TypeColor.captionOpacity)
    }

    func overlayShadowOpacity(weather: WeatherKind) -> Double {
        overlayPrefersLightInk(weather: weather) ? TypeColor.nightShadow : TypeColor.dayShadow
    }
}

private enum TypeColor {
    static let captionOpacity = 0.72
    static let light = Color(red: 0.93, green: 0.90, blue: 0.84)
    static let dark = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let dayShadow = 0.08
    static let nightShadow = 0.40
}

private enum WeatherWash {
    static let cloudyTopWhite = 0.42
    static let cloudyTopMix = 0.35
    static let cloudyMidWhite = 0.55
    static let cloudyMidMix = 0.4
    static let cloudyHorizonWhite = 0.62
    static let cloudyHorizonMix = 0.3
    static let cloudyHazeAdd = 0.18
    static let cloudyStarFactor = 0.15
    static let fogTopWhite = 0.55
    static let fogTopMix = 0.45
    static let fogMidWhite = 0.62
    static let fogHorizonWhite = 0.72
    static let fogHaze = 0.55
    static let rainTop = Color(red: 0.12, green: 0.16, blue: 0.22)
    static let rainTopMix = 0.55
    static let rainMid = Color(red: 0.22, green: 0.26, blue: 0.32)
    static let rainMidMix = 0.5
    static let rainHorizon = Color(red: 0.28, green: 0.32, blue: 0.36)
    static let rainHorizonMix = 0.4
    static let rainHazeAdd = 0.2
    static let snowTop = Color(red: 0.55, green: 0.62, blue: 0.72)
    static let snowTopMix = 0.4
    static let snowMidWhite = 0.78
    static let snowMidMix = 0.35
    static let snowHorizonWhite = 0.88
    static let snowHazeAdd = 0.15
    static let snowStarFactor = 0.2
}

private extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let amount = min(1, max(0, amount))
        let a = NSColor(self).usingColorSpace(.sRGB) ?? .black
        let b = NSColor(other).usingColorSpace(.sRGB) ?? .black
        let fromWeight = 1 - amount
        return Color(
            red: a.redComponent * fromWeight + b.redComponent * amount,
            green: a.greenComponent * fromWeight + b.greenComponent * amount,
            blue: a.blueComponent * fromWeight + b.blueComponent * amount
        )
    }
}
