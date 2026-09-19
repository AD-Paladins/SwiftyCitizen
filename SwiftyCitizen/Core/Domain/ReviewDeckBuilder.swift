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

    var summary: String {
        switch self {
        case .due:
            "Questions you haven't answered yet or didn't mark as got it."
        case .unanswered:
            "Questions with no recorded attempt yet."
        case .needsWork:
            "Answered questions whose latest self-assessment is not Got it."
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

enum ReviewDeckBuilder {
    static func build(
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

    static func questionCount(
        questions: [QuestionContent],
        attempts: [StudyAttemptSnapshot],
        scope: ReviewScope
    ) -> Int {
        build(questions: questions, attempts: attempts, scope: scope).count
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