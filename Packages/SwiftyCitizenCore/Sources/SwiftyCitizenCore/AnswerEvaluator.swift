import Foundation

public enum AnswerMatch {
    case complete
    case partial
    case none
}

public enum AnswerEvaluator {
    public static func evaluate(_ response: String, against question: QuestionContent) -> Bool {
        let answerWords = tokens(of: response)
        guard !answerWords.isEmpty else { return false }

        let variantWords = question.acceptedAnswerVariants.map(tokens)
        let validVariants = variantWords.filter { !$0.isEmpty }

        switch question.answerCardinality {
        case .exactly(let required) where required > 1:
            return namedVariantCount(answer: answerWords, variants: validVariants) >= required
        default:
            return !validVariants.isEmpty && validVariants.contains { matches(answer: answerWords, variant: $0) }
        }
    }

    public static func matchType(_ response: String, against question: QuestionContent) -> AnswerMatch {
        let answerWords = tokens(of: response)
        guard !answerWords.isEmpty else { return .none }

        let variants = question.acceptedAnswerVariants.map(tokens).filter { !$0.isEmpty }
        guard !variants.isEmpty else { return .none }

        switch question.answerCardinality {
        case .exactly(let required) where required > 1:
            let named = variants.filter { variant in variant.allSatisfy { answerWords.contains($0) } }.count
            if named >= required {
                return .complete
            }
            if named > 0 || hasCloseOverlap(answer: answerWords, variants: variants) {
                return .partial
            }
            return .none
        default:
            var hasExact = false
            var hasSubset = false
            for variant in variants {
                if answerWords == variant {
                    hasExact = true
                } else if answerWords.allSatisfy { variant.contains($0) } {
                    hasSubset = true
                }
            }
            if hasExact {
                return .complete
            }
            if hasSubset || hasCloseOverlap(answer: answerWords, variants: variants) {
                return .partial
            }
            return .none
        }
    }

    public static func namedVariantCount(
        answer: Set<String>,
        variants: [Set<String>]
    ) -> Int {
        variants.reduce(into: Set<String>()) { named, variant in
            if variant.allSatisfy { answer.contains($0) } {
                named.insert(variant.joined(separator: " "))
            }
        }.count
    }

    public static func matches(answer: Set<String>, variant: Set<String>) -> Bool {
        answer.allSatisfy { variant.contains($0) }
    }

    public static func hasCloseOverlap(answer: Set<String>, variants: [Set<String>]) -> Bool {
        variants.contains { variant in
            let overlap = answer.intersection(variant).count
            return overlap > 0 && overlap < variant.count
        }
    }

    public static func tokens(of text: String) -> Set<String> {
        Set(
            text.lowercased()
                .replacingOccurrences(of: "(", with: " ")
                .replacingOccurrences(of: ")", with: " ")
                .replacingOccurrences(of: ",", with: " ")
                .replacingOccurrences(of: ";", with: " ")
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
        )
    }

    public static func presentation(for userAnswer: String?, against question: QuestionContent) -> AnswerPresentation {
        guard let answer = userAnswer, !answer.isEmpty else {
            return AnswerPresentation(verdict: .unanswered, yourAnswer: nil, officialText: nil)
        }
        switch matchType(answer, against: question) {
        case .complete:
            return AnswerPresentation(verdict: .correct, yourAnswer: answer, officialText: acceptedText(for: question))
        case .partial:
            return AnswerPresentation(verdict: .partial, yourAnswer: answer, officialText: acceptedText(for: question))
        case .none:
            return AnswerPresentation(verdict: .incorrect, yourAnswer: answer, officialText: acceptedText(for: question))
        }
    }

    public static func acceptedText(for question: QuestionContent) -> String {
        question.acceptedAnswerVariants.joined(separator: " · ")
    }
}

public struct AnswerPresentation {
    public enum Verdict {
        case correct
        case partial
        case incorrect
        case unanswered
    }

    public let verdict: Verdict
    public let yourAnswer: String?
    public let officialText: String?
}