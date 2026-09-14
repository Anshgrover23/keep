import SwiftUI

struct DaySceneView: View {
    var date: Date
    var solar: SolarContext
    var palette: SkyPalette
    var weather: WeatherKind
    var reduceMotion: Bool = false

    var body: some View {
        Canvas { context, size in
            drawSky(context: &context, size: size)
            drawStars(context: &context, size: size)
            drawGlow(context: &context, size: size)
            if solar.isDay {
                drawBody(context: &context, size: size, progress: solar.sunProgress, radius: Metrics.sunRadius, isMoon: false)
            } else {
                drawBody(context: &context, size: size, progress: solar.moonProgress, radius: Metrics.moonRadius, isMoon: true)
            }
            drawHorizonHaze(context: &context, size: size)
            drawCloudBands(context: &context, size: size)
            WeatherParticles.draw(
                context: &context,
                size: size,
                date: date,
                weather: weather,
                reduceMotion: reduceMotion
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawSky(context: inout GraphicsContext, size: CGSize) {
        let sky = Gradient(colors: [palette.top, palette.mid, palette.horizon])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                sky,
                startPoint: CGPoint(x: size.width / Metrics.diameterFactor, y: 0),
                endPoint: CGPoint(x: size.width / Metrics.diameterFactor, y: size.height)
            )
        )
    }

    private func drawStars(context: inout GraphicsContext, size: CGSize) {
        guard palette.starOpacity > Metrics.starVisibilityFloor else { return }
        var rng = SceneRNG(seed: Metrics.starSeed)
        let t = SceneMotion.timeInterval(from: date, reduceMotion: reduceMotion)
        for i in 0..<Metrics.starCount {
            let x = rng.next() * size.width
            let y = rng.next() * size.height * Metrics.starFieldHeight
            let twinkle = reduceMotion
                ? 1.0
                : Metrics.twinkleBase + Metrics.twinkleSpread * sin(t * Metrics.twinkleSpeed + Double(i) * Metrics.twinklePhase)
            let radius = Metrics.starRadiusMin + rng.next() * Metrics.starRadiusSpread
            var star = context
            star.opacity = palette.starOpacity * twinkle
            star.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                with: .color(.white)
            )
        }
    }

    private func drawGlow(context: inout GraphicsContext, size: CGSize) {
        let body = bodyPoint(size: size, progress: solar.isDay ? solar.sunProgress : solar.moonProgress)
        let glowRadius = solar.isDay ? Metrics.dayGlowRadius : Metrics.nightGlowRadius
        let rect = CGRect(
            x: body.x - glowRadius,
            y: body.y - glowRadius,
            width: glowRadius * Metrics.diameterFactor,
            height: glowRadius * Metrics.diameterFactor
        )
        var glow = context
        glow.addFilter(.blur(radius: Metrics.skyGlowBlur))
        glow.opacity = Metrics.skyGlowOpacity
        glow.fill(Path(ellipseIn: rect), with: .color(palette.glow))
    }

    private func drawBody(context: inout GraphicsContext, size: CGSize, progress: Double, radius: CGFloat, isMoon: Bool) {
        let point = bodyPoint(size: size, progress: progress)
        let rect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * Metrics.diameterFactor,
            height: radius * Metrics.diameterFactor
        )
        var glow = context
        glow.addFilter(.blur(radius: Metrics.bodyGlowBlur))
        glow.opacity = Metrics.bodyGlowOpacity
        glow.fill(
            Path(ellipseIn: rect.insetBy(dx: Metrics.bodyGlowInset, dy: Metrics.bodyGlowInset)),
            with: .color(palette.sun.opacity(Metrics.bodyGlowFillOpacity))
        )
        context.fill(Path(ellipseIn: rect), with: .color(palette.sun))
        if isMoon {
            let shadow = CGRect(
                x: point.x + radius * Metrics.moonShadowX,
                y: point.y - radius * Metrics.moonShadowY,
                width: radius * Metrics.moonShadowSize,
                height: radius * Metrics.moonShadowSize
            )
            var crater = context
            crater.opacity = Metrics.moonCraterOpacity
            crater.fill(Path(ellipseIn: shadow), with: .color(palette.mid))
        }
    }

    private func drawHorizonHaze(context: inout GraphicsContext, size: CGSize) {
        let hazeHeight = size.height * (Metrics.hazeBaseHeight + palette.haze * Metrics.hazeHeightGain)
        let rect = CGRect(x: 0, y: size.height - hazeHeight, width: size.width, height: hazeHeight)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [palette.horizon.opacity(0), palette.horizon.opacity(Metrics.hazeHorizonOpacity + palette.haze)]),
                startPoint: CGPoint(x: size.width / Metrics.diameterFactor, y: rect.minY),
                endPoint: CGPoint(x: size.width / Metrics.diameterFactor, y: rect.maxY)
            )
        )
    }

    private func drawCloudBands(context: inout GraphicsContext, size: CGSize) {
        guard weather == .cloudy || weather == .fog || weather == .storm else { return }
        let t = SceneMotion.timeInterval(from: date, reduceMotion: reduceMotion)
        let bands = weather == .fog ? Metrics.fogBandCount : Metrics.cloudBandCount
        for i in 0..<bands {
            let y = size.height * (Metrics.bandStartY + Double(i) * Metrics.bandYStride)
            let drift = reduceMotion ? 0 : CGFloat(sin(t * Metrics.bandDriftSpeed + Double(i)) * Metrics.bandDriftAmplitude)
            var band = context
            band.opacity = weather == .fog ? Metrics.fogBandOpacity : Metrics.cloudBandOpacity
            band.addFilter(.blur(radius: weather == .fog ? Metrics.fogBandBlur : Metrics.cloudBandBlur))
            let rect = CGRect(
                x: Metrics.bandXOffset + drift,
                y: y,
                width: size.width + Metrics.bandExtraWidth,
                height: weather == .fog ? Metrics.fogBandHeight : Metrics.cloudBandHeight
            )
            band.fill(Path(roundedRect: rect, cornerRadius: Metrics.bandCornerRadius), with: .color(palette.horizon))
        }
    }

    private func bodyPoint(size: CGSize, progress: Double) -> CGPoint {
        let clamped = min(Metrics.progressMax, max(Metrics.progressMin, progress))
        let x = size.width * (Metrics.bodyXStart + Metrics.bodyXSpan * clamped)
        let arc = sin(clamped * .pi)
        let y = size.height * (Metrics.bodyYBase - Metrics.bodyYArc * arc)
        return CGPoint(x: x, y: y)
    }
}

private enum Metrics {
    static let sunRadius: CGFloat = 38
    static let moonRadius: CGFloat = 26
    static let starVisibilityFloor = 0.01
    static let starSeed: UInt64 = 42
    static let starCount = 90
    static let starFieldHeight = 0.62
    static let twinkleBase = 0.55
    static let twinkleSpread = 0.45
    static let twinkleSpeed = 0.7
    static let twinklePhase = 0.6
    static let starRadiusMin = 0.6
    static let starRadiusSpread = 1.4
    static let dayGlowRadius = 280.0
    static let nightGlowRadius = 180.0
    static let diameterFactor: CGFloat = 2
    static let skyGlowBlur: CGFloat = 64
    static let skyGlowOpacity = 0.42
    static let bodyGlowBlur: CGFloat = 28
    static let bodyGlowOpacity = 0.85
    static let bodyGlowInset: CGFloat = -12
    static let bodyGlowFillOpacity = 0.7
    static let moonShadowX = 0.15
    static let moonShadowY = 0.35
    static let moonShadowSize = 0.85
    static let moonCraterOpacity = 0.16
    static let hazeBaseHeight = 0.22
    static let hazeHeightGain = 0.2
    static let hazeHorizonOpacity = 0.55
    static let fogBandCount = 5
    static let cloudBandCount = 3
    static let bandStartY = 0.18
    static let bandYStride = 0.12
    static let bandDriftSpeed = 0.03
    static let bandDriftAmplitude = 40.0
    static let fogBandOpacity = 0.14
    static let cloudBandOpacity = 0.08
    static let fogBandBlur: CGFloat = 48
    static let cloudBandBlur: CGFloat = 32
    static let bandXOffset: CGFloat = -80
    static let bandExtraWidth: CGFloat = 160
    static let fogBandHeight: CGFloat = 90
    static let cloudBandHeight: CGFloat = 56
    static let bandCornerRadius: CGFloat = 40
    static let progressMax = 1.15
    static let progressMin = -0.15
    static let bodyXStart = 0.12
    static let bodyXSpan = 0.76
    static let bodyYBase = 0.72
    static let bodyYArc = 0.48
}
