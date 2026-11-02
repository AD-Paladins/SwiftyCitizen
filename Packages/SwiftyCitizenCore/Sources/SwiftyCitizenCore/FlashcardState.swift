import Foundation

public struct FlashcardAttemptRecord {
    public let stableID: String
    public let testVersion: USCISTestVersion
    public let assessment: SelfAssessment
    public let answerText: String?
    /// Leitner box this result left the card in (1...`LeitnerScheduler.maxBox`). Defaults to 1.
    public let boxLevel: Int

    public init(
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

public struct FlashcardState {
    private(set) var questions: [QuestionContent]
    private(set) var currentIndex: Int
    private(set) var isRevealed: Bool
    private(set) var currentAnswer: String?
    private(set) var attempts: [FlashcardAttemptRecord]
    /// Leitner box per question (stableID -> box). New cards start in box 1.
    private(set) var boxes: [String: Int]

    public init(questions: [QuestionContent]) {
        self.questions = questions
        self.currentIndex = 0
        self.isRevealed = false
        self.currentAnswer = nil
        self.attempts = []
        self.boxes = Dictionary(uniqueKeysWithValues: questions.map { ($0.stableID, 1) })
    }

    public var currentQuestion: QuestionContent? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    /// Current Leitner box for the question in view (1...`LeitnerScheduler.maxBox`).
    public var currentBox: Int {
        guard let id = currentQuestion?.stableID else { return 1 }
        return boxes[id] ?? 1
    }

    public var progressText: String {
        let total = questions.count
        guard total > 0 else { return "0 of 0" }
        return "\(currentIndex + 1) of \(total)"
    }

    public var isComplete: Bool {
        currentIndex >= questions.count
    }

    public var answeredCount: Int {
        attempts.count
    }

    public mutating func reveal() {
        guard !isRevealed, !isComplete else { return }
        isRevealed = true
    }

    public mutating func recordAnswer(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentAnswer = trimmed.isEmpty ? nil : trimmed
    }

    public mutating func seek(to index: Int) {
        currentIndex = min(max(0, index), questions.count)
        isRevealed = false
        currentAnswer = nil
    }

    public mutating func restore(attempts: [FlashcardAttemptRecord]) {
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
   public mutating func assess(_ assessment: SelfAssessment) -> FlashcardAttemptRecord? {
        guard !isComplete, let question = currentQuestion else { return nil }
        switch assessment {
        case .again:
            // A miss is a real signal: persist it (box 1) so the Leitner scheduler, the review
            // decks, and the Progress buckets see it. The card stays in view to be re-answered,
            // so currentIndex does not advance here.
            let attempt = FlashcardAttemptRecord(
                stableID: question.stableID,
                testVersion: question.testVersion,
                assessment: .again,
                answerText: currentAnswer,
                boxLevel: 1
            )
            attempts.append(attempt)
            isRevealed = false
            currentAnswer = nil
            boxes[question.stableID] = 1   // a miss drops the card to box 1
            return attempt
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