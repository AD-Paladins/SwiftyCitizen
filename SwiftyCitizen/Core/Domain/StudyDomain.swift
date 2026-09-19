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