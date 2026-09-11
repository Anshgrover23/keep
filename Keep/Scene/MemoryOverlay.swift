import SwiftUI

struct MemoryOverlay: View {
    var intention: String
    var nextItem: MemoryItem?
    var now: Date
    var phase: DayPhase
    var reduceMotion: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let nextItem {
                VStack(alignment: .leading, spacing: 6) {
                    Text(nextItem.caption(now: now).uppercased())
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .tracking(3.2)
                        .foregroundStyle(phase.captionColor)
                    Text(nextItem.title)
                        .font(.system(size: nextItem.isImminent(at: now) ? 44 : 34, weight: .regular, design: .serif))
                        .foregroundStyle(phase.textColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }

            if !intention.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("KEEP")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .tracking(3.6)
                        .foregroundStyle(phase.captionColor)
                    Text(intention)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(phase.textColor)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .shadow(color: Color.black.opacity(phase == .morning || phase == .noon || phase == .afternoon ? 0.12 : 0.45), radius: 16, y: 6)
        .frame(maxWidth: 720, alignment: .leading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: nextItem?.title)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: intention)
        .accessibilityHidden(true)
    }
}
