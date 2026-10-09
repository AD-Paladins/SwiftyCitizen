import Foundation

enum ReviewScope: String, Codable, CaseIterable, Identifiable {
    case due
    case unanswered
    case needsWork
    case bookmarked

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
        bookmarkedIDs: Set<String> = []
    ) -> [QuestionContent] {
        let scoped = scopedDeck(questions: questions, attempts: attempts, scope: scope, bookmarkedIDs: bookmarkedIDs)
        guard !categories.isEmpty else { return scoped }
        return scoped.filter { categories.contains($0.topic) }
    }

    static func questionCount(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        categories: Set<String> = [],
        bookmarkedIDs: Set<String> = []
    ) -> Int {
        build(questions: questions, attempts: attempts, scope: scope, categories: categories, bookmarkedIDs: bookmarkedIDs).count
    }

    static func categorySummary(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        bookmarkedIDs: Set<String> = []
    ) -> CategorySummary {
        let scoped = scopedDeck(questions: questions, attempts: attempts, scope: scope, bookmarkedIDs: bookmarkedIDs)
        let counts = scoped.reduce(into: [String: Int]()) { $0[$1.topic, default: 0] += 1 }
        return CategorySummary(topics: counts.keys.sorted(), counts: counts)
    }

    private static func scopedDeck(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        bookmarkedIDs: Set<String> = []
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

    private static func latestAssessmentByQuestion(
        from attempts: [StudyAttemptSnapshot]
    ) -> [String: SelfAssessment] {
        let groups = Dictionary(grouping: attempts, by: \.stableID)
        return groups.mapValues { attempts in
            attempts.max { $0.answeredAt < $1.answeredAt }.flatMap(\.assessment) ?? .again
        }
    }
}