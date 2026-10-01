import Foundation

struct FlashcardAttemptRecord {
    let stableID: String
    let testVersion: USCISTestVersion
    let assessment: SelfAssessment
    let answerText: String?
    /// Leitner box this result left the card in (1...`LeitnerScheduler.maxBox`). Defaults to 1.
    let boxLevel: Int

    init(
        stableID: String,
        testVersion: USCISTestVersion,
        assessment: SelfAssessment,
        answerText: String?,
        boxLevel: Int = 1
    ) {
        self.stableID = stableID
        self.testVersion = testVersion
        self.assessment = assessment
        self.answerText = answerText
        self.boxLevel = boxLevel
    }
}

struct FlashcardState {
    private(set) var questions: [QuestionContent]
    private(set) var currentIndex: Int
    private(set) var isRevealed: Bool
    private(set) var currentAnswer: String?
    private(set) var attempts: [FlashcardAttemptRecord]
    /// Leitner box per question (stableID -> box). New cards start in box 1.
    private(set) var boxes: [String: Int]

    init(questions: [QuestionContent]) {
        self.questions = questions
        self.currentIndex = 0
        self.isRevealed = false
        self.currentAnswer = nil
        self.attempts = []
        self.boxes = Dictionary(uniqueKeysWithValues: questions.map { ($0.stableID, 1) })
    }

    var currentQuestion: QuestionContent? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    /// Current Leitner box for the question in view (1...`LeitnerScheduler.maxBox`).
    var currentBox: Int {
        guard let id = currentQuestion?.stableID else { return 1 }
        return boxes[id] ?? 1
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
        // Later attempts for the same card override earlier ones, so the last box wins.
        for record in attempts {
            boxes[record.stableID] = record.boxLevel
        }
    }

  @discardableResult
   mutating func assess(_ assessment: SelfAssessment) -> FlashcardAttemptRecord? {
        guard !isComplete, let question = currentQuestion else { return nil }
        switch assessment {
        case .again:
            isRevealed = false
            currentAnswer = nil
            boxes[question.stableID] = 1   // ponytail: a miss drops the card to box 1
            return nil
        case .hard, .gotIt:
            let box = LeitnerScheduler.nextBox(after: assessment, currentBox: currentBox)
            boxes[question.stableID] = box
            let attempt = FlashcardAttemptRecord(
                stableID: question.stableID,
                testVersion: question.testVersion,
                assessment: assessment,
                answerText: currentAnswer,
                boxLevel: box
            )
            attempts.append(attempt)
            currentIndex += 1
            isRevealed = false
            currentAnswer = nil
            return attempt
        }
    }
}