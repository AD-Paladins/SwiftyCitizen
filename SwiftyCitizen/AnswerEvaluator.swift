import Foundation

enum AnswerEvaluator {
    static func evaluate(_ response: String, against question: QuestionContent) -> Bool {
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

    private static func namedVariantCount(
        answer: Set<String>,
        variants: [Set<String>]
    ) -> Int {
        variants.reduce(into: Set<String>()) { named, variant in
            if variant.isSubset(of: answer) {
                named.insert(variant.joined(separator: " "))
            }
        }.count
    }

    private static func matches(answer: Set<String>, variant: Set<String>) -> Bool {
        answer.isSubset(of: variant)
    }

    private static func tokens(of text: String) -> Set<String> {
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
}