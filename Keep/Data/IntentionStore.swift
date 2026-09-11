import Combine
import Foundation

@MainActor
final class IntentionStore: ObservableObject {
    @Published var text: String
    @Published private(set) var lastEditedDay: String

    private var settings: any SettingsStore

    var isStale: Bool {
        !text.isEmpty && lastEditedDay != Self.todayStamp()
    }

    init(settings: any SettingsStore) {
        self.settings = settings
        lastEditedDay = settings.intentionDay
        text = settings.intentionText
    }

    func set(_ value: String) {
        text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        lastEditedDay = Self.todayStamp()
        persist()
    }

    func markReviewedToday() {
        lastEditedDay = Self.todayStamp()
        persist()
    }

    func markStaleForTesting() {
        lastEditedDay = "2000-01-01"
        persist()
    }

    private func persist() {
        settings.intentionText = text
        settings.intentionDay = lastEditedDay
    }

    static func todayStamp(now: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now)
    }
}
