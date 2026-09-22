import Foundation

enum ReviewScope: String, Codable, CaseIterable, Identifiable {
    case due
    case unanswered
    case needsWork

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .due:
            "Due"
        case .unanswered:
            "Unanswered"
        case .needsWork:
            "Needs work"
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
        categories: Set<String> = []
    ) -> [QuestionContent] {
        let scoped = scopedDeck(questions: questions, attempts: attempts, scope: scope)
        guard !categories.isEmpty else { return scoped }
        return scoped.filter { categories.contains($0.topic) }
    }

    static func questionCount(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope,
        categories: Set<String> = []
    ) -> Int {
        build(questions: questions, attempts: attempts, scope: scope, categories: categories).count
    }

    static func categorySummary(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope
    ) -> CategorySummary {
        let scoped = scopedDeck(questions: questions, attempts: attempts, scope: scope)
        let counts = scoped.reduce(into: [String: Int]()) { $0[$1.topic, default: 0] += 1 }
        return CategorySummary(topics: counts.keys.sorted(), counts: counts)
    }

    private static func scopedDeck(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope
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
            let latestAssessment = latestAssessmentByQuestion(from: versionAttempts)
            return questions.filter { question in
                guard let latest = latestAssessment[question.stableID] else { return true }
                return latest != .gotIt
            }
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