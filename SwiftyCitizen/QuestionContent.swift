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
}