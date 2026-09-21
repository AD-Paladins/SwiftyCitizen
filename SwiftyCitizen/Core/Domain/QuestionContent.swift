import Foundation

enum AnswerCardinality: Codable, Hashable {
    case exactly(Int)
}

struct QuestionContent: Codable, Hashable, Identifiable {
    let stableID: String
    let testVersion: USCISTestVersion
    let officialQuestion: String
    let acceptedAnswerVariants: [String]
    let answerCardinality: AnswerCardinality
    let topic: String
    let sourceURL: URL?
    let sourceRevision: String
    let verificationDate: Date?
    let isJurisdictionDependent: Bool
    let isSixtyFiveTwentyQuestion: Bool

    var id: String { stableID }
}

enum QuestionContentValidationField: String, Equatable {
    case sourceURL
    case sourceRevision
    case verificationDate
}

enum QuestionContentValidationError: Equatable {
    case emptyID(index: Int)
    case emptyQuestionText(id: String)
    case emptyTopic(id: String)
    case emptyAcceptedAnswers(id: String)
    case duplicateID(id: String)
    case invalidAnswerCardinality(id: String)
    case invalidQuestionCount(expected: Int, actual: Int)
    case missingSourceMetadata(id: String, field: QuestionContentValidationField)
    case questionAssignedToWrongBank(id: String, expected: USCISTestVersion, actual: USCISTestVersion)
}

struct QuestionContentValidationFailure: Error, Equatable {
    let errors: [QuestionContentValidationError]
}

struct QuestionContentValidator {
    static func validate(
        _ questions: [QuestionContent],
        for configuration: TestConfiguration
    ) -> Result<Void, QuestionContentValidationFailure> {
        var errors: [QuestionContentValidationError] = []
        var seenIDs = Set<String>()

        if questions.count != configuration.questionBankCount {
            errors.append(.invalidQuestionCount(
                expected: configuration.questionBankCount,
                actual: questions.count
            ))
        }

        for (index, question) in questions.enumerated() {
            let id = question.stableID.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = question.officialQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
            let topic = question.topic.trimmingCharacters(in: .whitespacesAndNewlines)

            if id.isEmpty {
                errors.append(.emptyID(index: index))
            } else if !seenIDs.insert(id).inserted {
                errors.append(.duplicateID(id: id))
            }

            if text.isEmpty {
                errors.append(.emptyQuestionText(id: id))
            }

            if topic.isEmpty {
                errors.append(.emptyTopic(id: id))
            }

            if question.acceptedAnswerVariants.isEmpty || question.acceptedAnswerVariants.contains(where: {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }) {
                errors.append(.emptyAcceptedAnswers(id: id))
            }

            switch question.answerCardinality {
            case .exactly(let count) where count > 0 && count <= question.acceptedAnswerVariants.count:
                break
            default:
                errors.append(.invalidAnswerCardinality(id: id))
            }

            if question.sourceURL?.scheme == nil || question.sourceURL?.host == nil {
                errors.append(.missingSourceMetadata(id: id, field: .sourceURL))
            }

            if question.sourceRevision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.missingSourceMetadata(id: id, field: .sourceRevision))
            }

            if question.verificationDate == nil {
                errors.append(.missingSourceMetadata(id: id, field: .verificationDate))
            }

            if question.testVersion != configuration.version {
                errors.append(.questionAssignedToWrongBank(
                    id: id,
                    expected: configuration.version,
                    actual: question.testVersion
                ))
            }
        }

        if errors.isEmpty {
            return .success(())
        }
        return .failure(QuestionContentValidationFailure(errors: errors))
    }
}

extension QuestionContent {
    enum AnswerInputMode {
        case selection
        case text
    }

    var answerInputMode: AnswerInputMode {
        guard acceptedAnswerVariants.count >= 2 else {
            return .text
        }
        let hasVariableAnswer = acceptedAnswerVariants.contains { variant in
            let lower = variant.lowercased()
            return lower.contains("answers will vary") || lower.contains("testupdates")
        }
        return hasVariableAnswer ? .text : .selection
    }

    private static let distractorPoolMax = 4

    static func distractorOptions(
        for question: QuestionContent,
        from bank: [QuestionContent]
    ) -> [String] {
        let ownVariants = Set(question.acceptedAnswerVariants)
        var candidates: [String] = []
        for other in bank where other.topic == question.topic && other.stableID != question.stableID {
            for variant in other.acceptedAnswerVariants {
                if variant.isEmpty || ownVariants.contains(variant) { continue }
                let lower = variant.lowercased()
                if lower.contains("answers will vary") || lower.contains("testupdates") { continue }
                candidates.append(variant)
            }
        }
        let unique = Array(Set(candidates))
        return Array(unique.sorted().prefix(distractorPoolMax))
    }

    static func shuffleSeed(for stableID: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in stableID.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x85ebca6787bcb64c
        }
        return hash
    }
}

struct SeededShuffle: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9e3779b97f4a7c15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 26
        return state
    }
}