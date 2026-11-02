import Foundation

public enum ReviewScope: String, Codable, CaseIterable, Identifiable {
    case due
    case unanswered
    case needsWork
    case bookmarked
    /// The exact low-accuracy set the Progress tab counts. When `weakStableIDs` is supplied the
    /// deck is those specific cards; otherwise it falls back to attempted cards whose per-card
    /// accuracy is at or below the low-accuracy threshold (the manual scope).
    case lowAccuracy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .due:
            "Due"
        case .unanswered:
            "Unanswered"
        case .needsWork:
            "Needs work"
        case .bookmarked:
            "Bookmarked"
        case .lowAccuracy:
            "Low accuracy"
        }
    }

    public var systemImage: String {
        switch self {
        case .due:
            "calendar"
        case .unanswered:
            "questionmark.circle"
        case .needsWork:
            "exclamationmark.circle"
        case .bookmarked:
            "bookmark"
        case .lowAccuracy:
            "exclamationmark.triangle"
        }
    }
}

public struct CategorySummary: Equatable {
    public var topics: [String]
    public var counts: [String: Int]
}

public enum ReviewDeckBuilder {
    public static func build(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        categories: Set<String> = [],
        bookmarkedIDs: Set<String> = [],
        weakStableIDs: Set<String> = []
    ) -> [QuestionContent] {
        let scoped = scopedDeck(
            questions: questions,
            attempts: attempts,
            scope: scope,
            bookmarkedIDs: bookmarkedIDs,
            weakStableIDs: weakStableIDs
        )
        guard !categories.isEmpty else { return scoped }
        return scoped.filter { categories.contains($0.topic) }
    }

    public static func questionCount(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        categories: Set<String> = [],
        bookmarkedIDs: Set<String> = [],
        weakStableIDs: Set<String> = []
    ) -> Int {
        build(
            questions: questions,
            attempts: attempts,
            scope: scope,
            categories: categories,
            bookmarkedIDs: bookmarkedIDs,
            weakStableIDs: weakStableIDs
        ).count
    }

    public static func categorySummary(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        bookmarkedIDs: Set<String> = [],
        weakStableIDs: Set<String> = []
    ) -> CategorySummary {
        let scoped = scopedDeck(
            questions: questions,
            attempts: attempts,
            scope: scope,
            bookmarkedIDs: bookmarkedIDs,
            weakStableIDs: weakStableIDs
        )
        let counts = scoped.reduce(into: [String: Int]()) { $0[$1.topic, default: 0] += 1 }
        return CategorySummary(topics: counts.keys.sorted(), counts: counts)
    }

    public static func scopedDeck(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        bookmarkedIDs: Set<String> = [],
        weakStableIDs: Set<String> = []
    ) -> [QuestionContent] {
        guard let version = questions.first?.testVersion else { return [] }
        let versionAttempts = attempts.filter { $0.testVersion == version }

        switch scope {
        case .unanswered:
            let answeredIDs = Set(versionAttempts.map(\.stableID))
            return questions.filter { !answeredIDs.contains($0.stableID) }

        case .needsWork:
            let latestAssessment = latestAssessmentByQuestion(from: versionAttempts)
            return questions.filter { question in
                guard let latest = latestAssessment[question.stableID] else { return false }
                return latest != .gotIt
            }

        case .lowAccuracy:
            // The exact set the Progress tab counts wins; otherwise fall back to attempted cards
            // whose mock-test per-card accuracy is at or below the low-accuracy threshold.
            // Cards with only self-assessed (flashcard) history have no accuracy signal and are
            // excluded — "Low accuracy" means measured low, not "never mock-tested".
            if !weakStableIDs.isEmpty {
                return questions.filter { weakStableIDs.contains($0.stableID) }
            }
            let lowAccuracyCards = Set(versionAttempts.map(\.stableID)).filter { stableID in
                guard let accuracy = perCardAccuracy(attempts.filter { $0.stableID == stableID }, lastN: 5) else { return false }
                return accuracy <= lowAccuracyThreshold
            }
            return questions.filter { lowAccuracyCards.contains($0.stableID) }

        case .due:
            // Spaced-repetition scheduling over self-assessment + answer history.
            // Unseen cards surface first (max urgency), then due cards most-overdue-first.
            return SpacedRepetitionScheduler.dueCards(
                questions: questions,
                attempts: versionAttempts,
                version: version
            )

        case .bookmarked:
            // `bookmarkedIDs` is already scoped to the active version by the view layer;
            // the pure builder only filters by stable-ID membership.
            return questions.filter { bookmarkedIDs.contains($0.stableID) }
        }
    }

    /// Delegates to the single shared per-card accuracy definition (mock-test attempts only), so
    /// this scope and Progress's weak spots / needs-care can never drift apart.
    public static func perCardAccuracy(_ attempts: [StudyAttemptSnapshot], lastN: Int) -> Double? {
        StudyProgressMetrics.perCardAccuracy(attempts, lastN: lastN)
    }

    // ponytail: magic low-accuracy threshold; shared concept with ProgressAnalytics.lowAccuracyThreshold.
    public static let lowAccuracyThreshold = 0.5

    public static func latestAssessmentByQuestion(
        from attempts: [StudyAttemptSnapshot]
    ) -> [String: SelfAssessment] {
        let groups = Dictionary(grouping: attempts, by: \.stableID)
        return groups.mapValues { attempts in
            attempts.max { $0.answeredAt < $1.answeredAt }.flatMap(\.assessment) ?? .again
        }
    }
}