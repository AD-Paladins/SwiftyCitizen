import Foundation

enum StudyMode: String, Codable, CaseIterable {
    case flashcards
    case targetedReview
    case mockTest

    var displayName: String {
        switch self {
        case .flashcards:
            "Flashcards"
        case .targetedReview:
            "Targeted review"
        case .mockTest:
            "Mock test"
        }
    }
}

enum SelfAssessment: String, Codable, CaseIterable {
    case again
    case hard
    case gotIt

    var displayName: String {
        switch self {
        case .again:
            "Again"
        case .hard:
            "Hard"
        case .gotIt:
            "Got it"
        }
    }

    var systemImage: String {
        switch self {
        case .again:
            "arrow.counterclockwise"
        case .hard:
            "graduationcap"
        case .gotIt:
            "checkmark"
        }
    }
}

func resumeFlashcardState(
    deckStableIDs: [String],
    currentIndex: Int,
    attempts: [FlashcardAttemptRecord],
    deckQuestions: [QuestionContent]
) -> FlashcardState? {
    let deckByID = Dictionary(uniqueKeysWithValues: deckQuestions.map { ($0.stableID, $0) })
    let ordered = deckStableIDs.compactMap { deckByID[$0] }
    guard !ordered.isEmpty else { return nil }

    var state = FlashcardState(questions: ordered)
    state.restore(attempts: attempts)
    state.seek(to: min(currentIndex, ordered.count))
    return state
}