import SwiftUI

struct MemoryOverlay: View {
    var intention: String
    var nextItem: MemoryItem?
    var now: Date
    var phase: DayPhase
    var weather: WeatherKind
    var reduceMotion: Bool = false

    var body: some View {
        let ink = phase.overlayTextColor(weather: weather)
        let caption = phase.overlayCaptionColor(weather: weather)
        VStack(alignment: .leading, spacing: 22) {
            if let nextItem {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextItem.caption(now: now).uppercased())
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .tracking(3.2)
                        .foregroundStyle(caption)
                    Text(nextItem.title)
                        .font(.system(size: nextItem.isImminent(at: now) ? 44 : 34, weight: .regular, design: .serif))
                        .foregroundStyle(ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }

            if !intention.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("KEEP")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .tracking(3.6)
                        .foregroundStyle(caption)
                    Text(intention)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(ink)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .shadow(color: Color.black.opacity(phase.overlayShadowOpacity(weather: weather)), radius: 16, y: 6)
        .frame(maxWidth: 720, alignment: .leading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: nextItem?.title)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: intention)
        .accessibilityHidden(true)
    }
}
