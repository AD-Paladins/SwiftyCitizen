import Foundation

struct FlashcardAttemptRecord {
    let stableID: String
    let testVersion: USCISTestVersion
    let assessment: SelfAssessment
    let answerText: String?
}

struct FlashcardState {
    private(set) var questions: [QuestionContent]
    private(set) var currentIndex: Int
    private(set) var isRevealed: Bool
    private(set) var currentAnswer: String?
    private(set) var attempts: [FlashcardAttemptRecord]

    init(questions: [QuestionContent]) {
        self.questions = questions
        self.currentIndex = 0
        self.isRevealed = false
        self.currentAnswer = nil
        self.attempts = []
    }

    var currentQuestion: QuestionContent? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progressText: String {
        let total = questions.count
        guard total > 0 else { return "0 of 0" }
        return "\(currentIndex + 1) of \(total)"
    }

    var isComplete: Bool {
        currentIndex >= questions.count
    }

    var answeredCount: Int {
        attempts.count
    }

    mutating func reveal() {
        guard !isRevealed, !isComplete else { return }
        isRevealed = true
    }

    mutating func recordAnswer(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentAnswer = trimmed.isEmpty ? nil : trimmed
    }

    mutating func seek(to index: Int) {
        currentIndex = min(max(0, index), questions.count)
        isRevealed = false
        currentAnswer = nil
    }

    mutating func restore(attempts: [FlashcardAttemptRecord]) {
        guard self.attempts.isEmpty && attempts.allSatisfy({ record in
            questions.contains { $0.stableID == record.stableID }
        }) else { return }
        self.attempts = attempts
    }

  @discardableResult
   mutating func assess(_ assessment: SelfAssessment) -> FlashcardAttemptRecord? {
        guard !isComplete, let question = currentQuestion else { return nil }
        switch assessment {
        case .again:
            isRevealed = false
            currentAnswer = nil
            return nil
        case .hard, .gotIt:
            let attempt = FlashcardAttemptRecord(
                stableID: question.stableID,
                testVersion: question.testVersion,
                assessment: assessment,
                answerText: currentAnswer
            )
            attempts.append(attempt)
            currentIndex += 1
            isRevealed = false
            currentAnswer = nil
            return attempt
        }
    }
}