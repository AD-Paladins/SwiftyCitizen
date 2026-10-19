import Foundation

/// A topic the learner struggled with in a completed flashcard session — an honest, per-session
/// summary built only from the session's own attempts (no invented percentages).
///
/// A card counts as "weak" when the learner missed it (`.again`) or its success rate — the fraction
/// of `.gotIt` answers over the last five attempts — is at or below the low-accuracy threshold. That
/// threshold matches Progress's "Low accuracy" queue (`ReviewDeckBuilder`, `ProgressAnalytics`), so
/// the topics here line up with what the review deck would surface.
struct WeakTopic: Equatable, Identifiable {
    /// The question topic label (from `QuestionContent.topic`). Also the stable row id — topics are
    /// grouped, so one `WeakTopic` exists per topic.
    let topic: String
    /// Distinct weak cards in this topic (missed or low-accuracy).
    let weakCards: Int

    var id: String { topic }
}

enum SessionWeakTopics {
    /// Per-card success threshold shared with Progress's "Low accuracy" queue. A card whose fraction
    /// of `.gotIt` answers is at or below this is "low accuracy".
    static let lowAccuracyThreshold = 0.5
    /// How many of a card's attempts feed its success rate (mirrors `ReviewDeckBuilder`'s lookback).
    private static let lookback = 5

    /// Weak topics for a session, sorted by topic for stable output. Empty when nothing was weak.
    static func compute(attempts: [FlashcardAttemptRecord], questions: [QuestionContent]) -> [WeakTopic] {
        let byTopic = weakCardsByTopic(attempts: attempts, questions: questions)
        return byTopic.keys.sorted().map { WeakTopic(topic: $0, weakCards: byTopic[$0]!.count) }
    }

    /// Stable IDs of every weak card (missed or low-accuracy), for the recommended review queue.
    static func weakStableIDs(attempts: [FlashcardAttemptRecord], questions: [QuestionContent]) -> Set<String> {
        Set(weakCardsByTopic(attempts: attempts, questions: questions).values.flatMap { $0 })
    }

    private static func weakCardsByTopic(
        attempts: [FlashcardAttemptRecord],
        questions: [QuestionContent]
    ) -> [String: Set<String>] {
        // First question per stableID wins; a duplicate stable ID can't crash the summary.
        var topicOf = [String: String]()
        for question in questions {
            if topicOf[question.stableID] == nil {
                topicOf[question.stableID] = question.topic
            }
        }
        let byCard = Dictionary(grouping: attempts, by: \.stableID)
        var result = [String: Set<String>]()
        for (stableID, cardAttempts) in byCard {
            guard let topic = topicOf[stableID] else { continue }
            if isWeak(cardAttempts) {
                result[topic, default: []].insert(stableID)
            }
        }
        return result
    }

    private static func isWeak(_ attempts: [FlashcardAttemptRecord]) -> Bool {
        // A miss is an unambiguous signal; otherwise fall back to the per-card success rate.
        if attempts.contains(where: { $0.assessment == .again }) { return true }
        let ordered = attempts.prefix(lookback)
        guard !ordered.isEmpty else { return false }
        let correct = ordered.filter { $0.assessment == .gotIt }.count
        return Double(correct) / Double(ordered.count) <= lowAccuracyThreshold
    }
}
