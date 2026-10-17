import Foundation

enum ReviewScope: String, Codable, CaseIterable, Identifiable {
    case due
    case unanswered
    case needsWork
    case bookmarked
    /// The exact low-accuracy set the Progress tab counts. When `weakStableIDs` is supplied the
    /// deck is those specific cards; otherwise it falls back to attempted cards whose per-card
    /// accuracy is at or below the low-accuracy threshold (the manual scope).
    case lowAccuracy

    var id: String { rawValue }

    var displayName: String {
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

    var systemImage: String {
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

struct CategorySummary: Equatable {
    var topics: [String]
    var counts: [String: Int]
}

enum ReviewDeckBuilder {
    static func build(
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

    static func questionCount(
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

    static func categorySummary(
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

    private static func scopedDeck(
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
            // whose per-card accuracy is at or below the low-accuracy threshold.
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

    // ponytail: mirrors ProgressAnalytics.perCardAccuracy so the manual "Low accuracy" scope has a
    // definition without importing that type; keep in sync if either threshold changes.
    private static func perCardAccuracy(_ attempts: [StudyAttemptSnapshot], lastN: Int) -> Double? {
        let ordered = attempts.sorted { $0.answeredAt > $1.answeredAt }.prefix(lastN)
        guard !ordered.isEmpty else { return nil }
        let correct = ordered.filter { $0.wasCorrect == true }.count
        return Double(correct) / Double(ordered.count)
    }

    // ponytail: magic low-accuracy threshold; shared concept with ProgressAnalytics.lowAccuracyThreshold.
    private static let lowAccuracyThreshold = 0.5

    private static func latestAssessmentByQuestion(
        from attempts: [StudyAttemptSnapshot]
    ) -> [String: SelfAssessment] {
        let groups = Dictionary(grouping: attempts, by: \.stableID)
        return groups.mapValues { attempts in
            attempts.max { $0.answeredAt < $1.answeredAt }.flatMap(\.assessment) ?? .again
        }
    }
}