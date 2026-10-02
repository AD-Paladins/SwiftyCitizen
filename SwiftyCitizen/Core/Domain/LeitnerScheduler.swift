import Foundation

/// Lightweight Leitner spaced-repetition core.
///
/// Five boxes (1...`maxBox`), each with a review interval. Transitions and due dates are pure
/// local date math — no networking, no scoring model, no external state.
///
/// Assumptions (tunable; see design-redesign-plan Phase 3):
/// - Interval is derived from the *resulting box*, not from the button pressed.
/// - `again` resets to box 1, `hard` drops one box (min 1), `got it` advances one box (max `maxBox`).
struct LeitnerScheduler {

    /// Mastered ceiling. A card stops climbing once it reaches this box.
    static let maxBox = 5

    /// Review interval per box (index 0 == box 1). Kept as a single tunable constant table.
    /// - `again` maps to box 1 (`0`), so a missed card is re-presented immediately.
    static let intervalsByBox: [TimeInterval] = [
        0,                                    // box 1: re-present now
        60 * 60 * 24 * 1,                     // box 2: 1 day
        60 * 60 * 24 * 3,                     // box 3: 3 days
        60 * 60 * 24 * 7,                     // box 4: 7 days
        60 * 60 * 24 * 14,                    // box 5: 14 days (mastered)
    ]

    /// Resulting box, interval, and next due date for a grade applied to `currentBox`.
    struct Outcome {
        let box: Int
        let interval: TimeInterval
        let dueDate: Date
    }

    static func interval(forBox box: Int) -> TimeInterval {
        guard (1...maxBox).contains(box) else { return intervalsByBox[0] }
        return intervalsByBox[box - 1]
    }

    /// Next box after applying `assessment` to `currentBox`.
    static func nextBox(after assessment: SelfAssessment, currentBox: Int) -> Int {
        switch assessment {
        case .again: return 1
        case .hard:  return max(1, currentBox - 1)
        case .gotIt: return min(maxBox, currentBox + 1)
        }
    }

    /// Full outcome for a grade applied at `lastReviewed` to a card in `currentBox`.
    static func outcome(
        after assessment: SelfAssessment,
        currentBox: Int,
        from lastReviewed: Date
    ) -> Outcome {
        let box = nextBox(after: assessment, currentBox: currentBox)
        let interval = interval(forBox: box)
        return Outcome(box: box, interval: interval, dueDate: lastReviewed.addingTimeInterval(interval))
    }

    /// Whether a card is due for review at `now` given its last `dueDate`.
    static func isDue(dueDate: Date, now: Date = .now) -> Bool {
        dueDate <= now
    }
}
