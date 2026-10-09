import Foundation

/// Scheduling layer over persisted self-assessment + answer history.
///
/// Derives each card's Leitner box by replaying its self-assessments oldest→newest from box 1
/// (new cards start in box 1), reusing `LeitnerScheduler.nextBox`. The resulting box plus the
/// latest attempt time yield the next due date via `LeitnerScheduler.interval` and
/// `Date.addingTimeInterval(_:)` — the same local-date pattern `LeitnerScheduler` uses.
/// Pure, SwiftData-free, unit-testable.
enum SpacedRepetitionScheduler {

    /// Due cards for `version`, ordered by urgency.
    ///
    /// Ordering is explicit: unseen cards first (max urgency — they must be learned), then due
    /// cards most-overdue-first (smallest `dueDate`). A card surfaces once its Leitner interval
    /// has elapsed; unseen cards have no attempt and are surfaced immediately.
    static func dueCards(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        version: USCISTestVersion,
        now: Date = .now
    ) -> [QuestionContent] {
        let versionAttempts = attempts.filter { $0.testVersion == version }
        let byCard = Dictionary(grouping: versionAttempts, by: \.stableID)

        var due: [(dueDate: Date, card: QuestionContent)] = []
        var unseen: [QuestionContent] = []

        for card in questions {
            guard let cardAttempts = byCard[card.stableID], !cardAttempts.isEmpty else {
                // No history → unseen, max urgency.
                unseen.append(card)
                continue
            }
            let ordered = cardAttempts.sorted { $0.answeredAt < $1.answeredAt }
            let box = box(from: ordered)
            let interval = LeitnerScheduler.interval(forBox: box)
            let dueDate = ordered[ordered.count - 1].answeredAt.addingTimeInterval(interval)
            if LeitnerScheduler.isDue(dueDate: dueDate, now: now) {
                due.append((dueDate, card))
            }
        }

        due.sort { $0.dueDate < $1.dueDate }
        return unseen + due.map(\.card)
    }

    /// Leitner box a card is in after replaying its self-assessments from box 1.
    ///
    /// Mock-test attempts (assessment nil) are skipped — they measure, they do not schedule.
    private static func box(from orderedAttempts: [StudyAttemptSnapshot]) -> Int {
        var box = 1
        for attempt in orderedAttempts {
            guard let assessment = attempt.assessment else { continue }
            box = LeitnerScheduler.nextBox(after: assessment, currentBox: box)
        }
        return box
    }
}
