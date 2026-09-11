import SwiftUI

enum SceneMotion {
    static func timeInterval(from date: Date, reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0 : date.timeIntervalSinceReferenceDate
    }

    /// Rain and snow streaks. Sky palette still shows weather when this is false.
    static func drawsPrecipitation(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }
}

/// SplitMix64 unit interval. Constants are the published mixer, not Keep policy.
struct SceneRNG {
    private var state: UInt64

    static let goldenGamma: UInt64 = 0x9E3779B97F4A7C15
    static let particleSalt: UInt64 = 0xA5A5A5A5A5A5A5A5
    private static let mix1: UInt64 = 0xBF58476D1CE4E5B9
    private static let mix2: UInt64 = 0x94D049BB133111EB
    private static let shift1: UInt64 = 30
    private static let shift2: UInt64 = 27
    private static let shift3: UInt64 = 31
    private static let unitDenominator: UInt64 = 10_000

    init(seed: UInt64, salt: UInt64 = goldenGamma) {
        state = seed &+ salt
    }

    mutating func next() -> Double {
        state &+= Self.goldenGamma
        var z = state
        z = (z ^ (z >> Self.shift1)) &* Self.mix1
        z = (z ^ (z >> Self.shift2)) &* Self.mix2
        z = z ^ (z >> Self.shift3)
        return Double(z % Self.unitDenominator) / Double(Self.unitDenominator)
    }
}

enum WeatherParticles {
    private enum Rain {
        static let stormCount = 140
        static let showerCount = 90
        static let seed: UInt64 = 7
        static let baseSpeed = 380.0
        static let speedSpread = 280.0
        static let baseLength = 12.0
        static let lengthSpread = 16.0
        static let swayPeriod = 0.4
        static let swayAmplitude = 8.0
        static let wrapPadding = 40.0
        static let yOffset = 20.0
        static let stormOpacity = 0.35
        static let showerOpacity = 0.22
        static let slant = 3.0
        static let lineWidth: CGFloat = 1
    }

    private enum Snow {
        static let count = 70
        static let seed: UInt64 = 19
        static let baseSpeed = 28.0
        static let speedSpread = 42.0
        static let baseSize = 2.0
        static let sizeSpread = 3.2
        static let driftPeriod = 0.6
        static let driftPhase = 0.4
        static let driftAmplitude = 18.0
        static let wrapPadding = 20.0
        static let opacity = 0.7
    }

    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        date: Date,
        weather: WeatherKind,
        reduceMotion: Bool
    ) {
        guard SceneMotion.drawsPrecipitation(reduceMotion: reduceMotion) else { return }
        switch weather {
        case .rain, .storm:
            rain(context: &context, size: size, date: date, storm: weather == .storm, reduceMotion: reduceMotion)
        case .snow:
            snow(context: &context, size: size, date: date, reduceMotion: reduceMotion)
        case .fog:
            break
        case .clear, .cloudy:
            break
        }
    }

    private static func rain(
        context: inout GraphicsContext,
        size: CGSize,
        date: Date,
        storm: Bool,
        reduceMotion: Bool
    ) {
        let t = SceneMotion.timeInterval(from: date, reduceMotion: reduceMotion)
        let count = storm ? Rain.stormCount : Rain.showerCount
        var rng = SceneRNG(seed: Rain.seed, salt: SceneRNG.particleSalt)
        for i in 0..<count {
            let col = rng.next()
            let speed = Rain.baseSpeed + rng.next() * Rain.speedSpread
            let length = Rain.baseLength + rng.next() * Rain.lengthSpread
            let x = col * size.width + sin(t * Rain.swayPeriod + Double(i)) * Rain.swayAmplitude
            let travel = (t * speed + rng.next() * size.height).truncatingRemainder(
                dividingBy: size.height + Rain.wrapPadding
            )
            let y = travel - Rain.yOffset
            var stroke = context
            stroke.opacity = storm ? Rain.stormOpacity : Rain.showerOpacity
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + Rain.slant, y: y + length))
            stroke.stroke(path, with: .color(.white), lineWidth: Rain.lineWidth)
        }
    }

    private static func snow(
        context: inout GraphicsContext,
        size: CGSize,
        date: Date,
        reduceMotion: Bool
    ) {
        let t = SceneMotion.timeInterval(from: date, reduceMotion: reduceMotion)
        var rng = SceneRNG(seed: Snow.seed, salt: SceneRNG.particleSalt)
        for i in 0..<Snow.count {
            let col = rng.next()
            let speed = Snow.baseSpeed + rng.next() * Snow.speedSpread
            let flake = Snow.baseSize + rng.next() * Snow.sizeSpread
            let drift = sin(t * Snow.driftPeriod + Double(i) * Snow.driftPhase) * Snow.driftAmplitude
            let x = col * size.width + drift
            let travel = (t * speed + rng.next() * size.height).truncatingRemainder(
                dividingBy: size.height + Snow.wrapPadding
            )
            let y = travel
            var flakeCtx = context
            flakeCtx.opacity = Snow.opacity
            flakeCtx.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: flake, height: flake)),
                with: .color(.white)
            )
        }
    }
}
