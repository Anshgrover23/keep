import SwiftUI

/// Lab promo: Keep sky plus real Liquid Glass. Not a product surface.
enum GlassCycleFilm {
    static let canvas = CGSize(width: 960, height: 480)
    static let pill = CGSize(width: 700, height: 176)
    /// Sit the pill a little low so noon sun stays above the glass, not glued to the rim.
    static let pillOffsetY: CGFloat = 40
    static let duration: TimeInterval = 10
    /// Open 500ms later than the locked still so the sun is already in frame.
    static let openingSkip: TimeInterval = 0.5
    static let framesPerSecond = 30

    static var frameCount: Int { Int(duration * TimeInterval(framesPerSecond)) }

    static func playhead(_ progress: Double) -> Double {
        let skip = openingSkip / duration
        let p = min(1, max(0, progress))
        return skip + (1 - skip) * p
    }

    /// Keep the whole sun on canvas, just left of the glass, like the locked still.
    static var startSunMinX: CGFloat {
        let radius = 38 * SceneReadability.glassCycle.bodyScale
        return radius + 16
    }

    static func civilDate(progress: Double, near reference: Date, observer: SolarObserver) -> Date {
        let start = firstDawnWithSunOnCanvas(near: reference, observer: observer)
        var end = lastDate(of: .dusk, near: reference, observer: observer)
        if end <= start {
            end = start.addingTimeInterval(8 * 60 * 60)
        }
        let span = max(end.timeIntervalSince(start), 60)
        return start.addingTimeInterval(playhead(progress) * span)
    }

    /// Dawn, but skip the first samples where the sun is clipped off the left edge.
    static func firstDawnWithSunOnCanvas(near reference: Date, observer: SolarObserver) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let dayStart = calendar.startOfDay(for: reference)
        for minute in stride(from: 0, to: SolarEngine.minutesPerDay, by: SolarEngine.phaseSampleStrideMinutes) {
            let date = dayStart.addingTimeInterval(.minutes(minute))
            let solar = SolarEngine.context(at: date, observer: observer)
            guard solar.phase == .dawn else { continue }
            let sun = DaySceneView.bodyPoint(
                size: canvas,
                progress: solar.isDay ? solar.sunProgress : solar.moonProgress,
                readability: .glassCycle
            )
            if sun.x >= startSunMinX {
                return date
            }
        }
        return firstDate(of: .dawn, near: reference, observer: observer)
    }

    /// First sample of a phase that day, so the sun begins low on the left.
    static func firstDate(of phase: DayPhase, near reference: Date, observer: SolarObserver) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let dayStart = calendar.startOfDay(for: reference)
        for minute in stride(from: 0, to: SolarEngine.minutesPerDay, by: SolarEngine.phaseSampleStrideMinutes) {
            let date = dayStart.addingTimeInterval(.minutes(minute))
            if SolarEngine.context(at: date, observer: observer).phase == phase {
                return date
            }
        }
        return SolarEngine.date(representing: phase, near: reference, observer: observer)
    }

    /// Last sample of a phase that day, so the sun finishes low on the right.
    static func lastDate(of phase: DayPhase, near reference: Date, observer: SolarObserver) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let dayStart = calendar.startOfDay(for: reference)
        var last: Date?
        for minute in stride(from: 0, to: SolarEngine.minutesPerDay, by: SolarEngine.phaseSampleStrideMinutes) {
            let date = dayStart.addingTimeInterval(.minutes(minute))
            if SolarEngine.context(at: date, observer: observer).phase == phase {
                last = date
            }
        }
        return last ?? SolarEngine.date(representing: phase, near: reference, observer: observer)
    }

    /// 1 at the ends, punches in at mid cycle.
    static func zoomScale(progress: Double) -> CGFloat {
        let p = playhead(progress)
        return 1 + 0.28 * CGFloat(sin(p * .pi))
    }

    static func zoomAnchor(sun: CGPoint, canvas: CGSize) -> UnitPoint {
        UnitPoint(
            x: min(0.78, max(0.22, sun.x / canvas.width)),
            y: min(0.68, max(0.32, sun.y / canvas.height))
        )
    }
}

@MainActor
final class GlassCycleDriver: ObservableObject {
    @Published var progress: Double = 0
}

struct GlassCycleView: View {
    var progress: Double
    var observer: SolarObserver
    var reduceMotion: Bool = false

    var body: some View {
        let date = GlassCycleFilm.civilDate(progress: progress, near: Date(), observer: observer)
        let solar = SolarEngine.context(at: date, observer: observer)
        let palette = SkyAppearance.palette(phase: solar.phase, weather: .clear)
        let ink = solar.phase.overlayPrefersLightInk(weather: .clear)
            ? Color.white
            : Color(red: 0.12, green: 0.10, blue: 0.08)

        let sun = DaySceneView.bodyPoint(
            size: GlassCycleFilm.canvas,
            progress: solar.isDay ? solar.sunProgress : solar.moonProgress,
            readability: .glassCycle
        )
        let zoom = GlassCycleFilm.zoomScale(progress: progress)
        let anchor = GlassCycleFilm.zoomAnchor(sun: sun, canvas: GlassCycleFilm.canvas)

        ZStack {
            DaySceneView(
                date: date,
                solar: solar,
                palette: palette,
                weather: .clear,
                reduceMotion: reduceMotion,
                readability: .glassCycle
            )
            .allowsHitTesting(false)
            keepGlass(solar: solar, palette: palette, ink: ink)
        }
        .scaleEffect(zoom, anchor: anchor)
        .frame(width: GlassCycleFilm.canvas.width, height: GlassCycleFilm.canvas.height)
        .clipped()
    }

    @ViewBuilder
    private func keepGlass(solar: SolarContext, palette: SkyPalette, ink: Color) -> some View {
        let canvas = GlassCycleFilm.canvas
        let pill = GlassCycleFilm.pill
        let sun = DaySceneView.bodyPoint(
            size: canvas,
            progress: solar.isDay ? solar.sunProgress : solar.moonProgress,
            readability: .glassCycle
        )
        let pillOrigin = CGPoint(
            x: (canvas.width - pill.width) / 2,
            y: (canvas.height - pill.height) / 2 + GlassCycleFilm.pillOffsetY
        )
        let localSun = CGPoint(x: sun.x - pillOrigin.x, y: sun.y - pillOrigin.y)

        ZStack {
            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 0) {
                    Color.clear
                        .frame(width: pill.width, height: pill.height)
                        .glassEffect(.clear.interactive(), in: Capsule())
                }
            } else {
                Capsule().fill(.ultraThinMaterial)
            }
            sunThroughGlass(at: localSun, sun: palette.sun, glow: palette.glow)
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.1)
                .allowsHitTesting(false)
            KeepWord(ink: ink)
        }
        .frame(width: pill.width, height: pill.height)
        .clipShape(Capsule())
        .position(
            x: canvas.width / 2,
            y: canvas.height / 2 + GlassCycleFilm.pillOffsetY
        )
        .allowsHitTesting(true)
    }

    /// Bloom of the real sun, clipped to the pill. No second sun inside the glass.
    private func sunThroughGlass(at point: CGPoint, sun: Color, glow: Color) -> some View {
        RadialGradient(
            colors: [
                Color.white.opacity(0.9),
                sun.opacity(0.45),
                glow.opacity(0.15),
                Color.clear,
            ],
            center: .center,
            startRadius: 4,
            endRadius: 70
        )
        .frame(width: 150, height: 150)
        .position(point)
        .blur(radius: 8)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

private struct KeepWord: View {
    var ink: Color

    var body: some View {
        Text("Keep")
            .font(.system(size: 72, weight: .light, design: .serif))
            .foregroundStyle(ink)
            .frame(width: GlassCycleFilm.pill.width, height: GlassCycleFilm.pill.height)
    }
}

struct GlassCycleDrivenHost: View {
    @ObservedObject var driver: GlassCycleDriver
    var observer: SolarObserver

    var body: some View {
        GlassCycleView(
            progress: driver.progress,
            observer: observer,
            reduceMotion: false
        )
    }
}

struct GlassCycleLiveView: View {
    var observer: SolarObserver
    @State private var startedAt = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)
            let loop = elapsed.truncatingRemainder(dividingBy: GlassCycleFilm.duration)
            GlassCycleView(
                progress: loop / GlassCycleFilm.duration,
                observer: observer
            )
        }
    }
}
