import Foundation
import os

struct ReminderDraft: Equatable, Sendable {
    var title: String
    var due: Date?
}

enum ReminderLoad: Equatable, Sendable {
    case drafts([ReminderDraft])
    case timedOut
}

/// First outcome wins. A timeout is not an empty draft list. A late EventKit result cannot replace a timeout.
final class ReminderFetchGate: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: Optional<ReminderLoad>.none)

    func complete(_ load: ReminderLoad, _ continuation: CheckedContinuation<ReminderLoad, Never>) {
        let first = state.withLock { current -> Bool in
            if current != nil { return false }
            current = load
            return true
        }
        if first {
            continuation.resume(returning: load)
        }
    }
}
