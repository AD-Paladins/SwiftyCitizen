import Foundation

struct MockTestAnswer: Equatable {
    let questionStableID: String
    let response: String
    let isCorrect: Bool
    let matchType: AnswerMatch
    let answeredAt: Date
}

enum MockTestOutcome: Equatable {
    case inProgress
    case passed
    case failed
}

enum MockTestPhase: Equatable {
    case active
    case complete(MockTestOutcome)
}

struct MockTestState {
    let questions: [QuestionContent]
    let maximumQuestionsAsked: Int
    let passingScore: Int

    private(set) var currentIndex: Int
    private(set) var answers: [MockTestAnswer]

    init(
        questions: [QuestionContent],
        maximumQuestionsAsked: Int,
        passingScore: Int
    ) {
        self.questions = questions
        self.maximumQuestionsAsked = maximumQuestionsAsked
        self.passingScore = passingScore
        self.currentIndex = 0
        self.answers = []
    }

    var currentQuestion: QuestionContent? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progressText: String {
        "\(currentIndex + 1) of \(maximumQuestionsAsked)"
    }

    var correctCount: Int {
        answers.filter(\.isCorrect).count
    }

    var incorrectCount: Int {
        answers.filter { !$0.isCorrect }.count
    }

    var phase: MockTestPhase {
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

    var isComplete: Bool {
        if case .complete = phase { return true }
        return false
    }

    mutating func record(_ response: String, answeredAt: Date = .now) -> MockTestAnswer? {
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
    mutating func submit(_ response: String, answeredAt: Date = .now) -> MockTestPhase {
        guard let question = currentQuestion, phase == .active else { return phase }
        record(response, answeredAt: answeredAt)
        currentIndex += 1
        return phase
    }

    mutating func advance() {
        if case .complete = phase {
            return
        }
        currentIndex += 1
    }
}