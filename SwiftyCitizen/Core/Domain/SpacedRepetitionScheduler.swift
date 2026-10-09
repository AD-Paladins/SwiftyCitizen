import Foundation

/// Scheduling layer over persisted self-assessment + answer history.
///
/// Reads each card's Leitner box from its latest attempt (`StudyAttemptSnapshot.boxLevel`,
/// populated from `QuestionAttempt.boxLevel`) and computes the next due date via
/// `LeitnerScheduler.interval` and `Date.addingTimeInterval(_:)` — the same local-date
/// pattern `LeitnerScheduler` uses. Pure, SwiftData-free, unit-testable.
enum SpacedRepetitionScheduler {

    /// Due cards for `version`, ordered by urgency.
    ///
    /// Unseen cards first (max urgency — they must be learned), then due cards
    /// most-overdue-first (smallest `dueDate`). A card surfaces once its Leitner interval
    /// has elapsed; an unanswered card (`boxLevel` nil) is surfaced immediately.
    static func dueCards(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        version: USCISTestVersion,
        now: Date = .now
    ) -> [QuestionContent] {
        let versionAttempts = attempts.filter { $0.testVersion == version }

        var due: [(dueDate: Date, card: QuestionContent)] = []
        var unseen: [QuestionContent] = []

        for card in questions {
            guard let attempt = latestAttempt(versionAttempts, for: card.stableID),
                  let boxLevel = attempt.boxLevel else {
                // No attempt, or unanswered (boxLevel nil) → max urgency.
                unseen.append(card)
                continue
            }
            let interval = LeitnerScheduler.interval(forBox: boxLevel)
            let dueDate = attempt.answeredAt.addingTimeInterval(interval)
            if LeitnerScheduler.isDue(dueDate: dueDate, now: now) {
                due.append((dueDate, card))
            }
        }

        due.sort { $0.dueDate < $1.dueDate }
        return unseen + due.map(\.card)
    }

    /// Latest attempt for a card (max `answeredAt`), or nil when the card has none.
    private static func latestAttempt(
        _ attempts: [StudyAttemptSnapshot],
        for stableID: String
    ) -> StudyAttemptSnapshot? {
        attempts
            .filter { $0.stableID == stableID }
            .max { $0.answeredAt < $1.answeredAt }
    }
}
