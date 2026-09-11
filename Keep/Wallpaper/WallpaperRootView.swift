import SwiftUI

struct WallpaperRootView: View {
    @ObservedObject var session: AppSession
    @ObservedObject var clock: FrameClock
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let clockDate = session.effectiveDate(from: clock.date)
        let solar = SolarEngine.context(
            at: clockDate,
            observer: session.location.fix.solarObserver
        )
        let weather = session.effectiveWeather
        let palette = SkyAppearance.palette(phase: solar.phase, weather: weather)

        ZStack(alignment: .bottomLeading) {
            DaySceneView(
                date: clockDate,
                solar: solar,
                palette: palette,
                weather: weather,
                reduceMotion: reduceMotion
            )
            MemoryOverlay(
                intention: session.intention.text,
                nextItem: session.effectiveNextItem,
                now: clockDate,
                phase: solar.phase,
                reduceMotion: reduceMotion
            )
            .padding(.leading, 72)
            .padding(.bottom, 88)
            .padding(.trailing, 120)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
