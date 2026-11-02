import Foundation

public struct MockTestAnswer: Equatable {
    public let questionStableID: String
    public let response: String
    public let isCorrect: Bool
    public let matchType: AnswerMatch
    public let answeredAt: Date

    public var needsOfficialAnswerReveal: Bool {
        !isCorrect
    }
}

public enum MockTestOutcome: Equatable {
    case inProgress
    case passed
    case failed
}

public enum MockTestPhase: Equatable {
    case active
    case complete(MockTestOutcome)
}

public struct MockTestState {
    public let questions: [QuestionContent]
    public let maximumQuestionsAsked: Int
    public let passingScore: Int

    private(set) var currentIndex: Int
    private(set) var answers: [MockTestAnswer]
    private(set) var skippedIDs: [String]

    public init(
        questions: [QuestionContent],
        maximumQuestionsAsked: Int,
        passingScore: Int
    ) {
        self.questions = questions
        self.maximumQuestionsAsked = maximumQuestionsAsked
        self.passingScore = passingScore
        self.currentIndex = 0
        self.answers = []
        self.skippedIDs = []
    }

    public var currentQuestion: QuestionContent? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    public var progressText: String {
        "\(currentIndex + 1) of \(maximumQuestionsAsked)"
    }

    public var correctCount: Int {
        answers.filter(\.isCorrect).count
    }

    public var incorrectCount: Int {
        answers.filter { !$0.isCorrect }.count
    }

    public var phase: MockTestPhase {
        if correctCount >= passingScore {
            return .complete(.passed)
        }
        if correctCount + (maximumQuestionsAsked - currentIndex) < passingScore {
            return .complete(.failed)
        }
        if currentIndex >= maximumQuestionsAsked {
            return .complete(correctCount >= passingScore ? .passed : .failed)
        }
        return .active
    }

    public var isComplete: Bool {
        if case .complete = phase { return true }
        return false
    }

    public mutating func record(_ response: String, answeredAt: Date = .now) -> MockTestAnswer? {
        guard let question = currentQuestion, phase == .active else { return nil }

        let matchType = AnswerEvaluator.matchType(response, against: question)
        let answer = MockTestAnswer(
            questionStableID: question.stableID,
            response: response,
            isCorrect: AnswerEvaluator.evaluate(response, against: question),
            matchType: matchType,
            answeredAt: answeredAt
        )
        answers.append(answer)
        return answer
    }

    @discardableResult
    public mutating func submit(_ response: String, answeredAt: Date = .now) -> MockTestPhase {
        guard let question = currentQuestion, phase == .active else { return phase }
        record(response, answeredAt: answeredAt)
        currentIndex += 1
        return phase
    }

    public mutating func advance() {
        if case .complete = phase {
            return
        }
        currentIndex += 1
    }

    @discardableResult
    public mutating func skip() -> Bool {
        guard let question = currentQuestion, phase == .active else { return false }
        if !skippedIDs.contains(question.stableID) {
            skippedIDs.append(question.stableID)
        }
        currentIndex += 1
        return true
    }

    public var skippedCount: Int {
        skippedIDs.count
    }
}