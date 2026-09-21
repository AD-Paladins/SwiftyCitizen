import Foundation

func selectQuestions(
    from bank: [QuestionContent],
    maximum: Int,
    shuffleEnabled: Bool
) -> [QuestionContent] {
    shuffleEnabled ? Array(bank.shuffled().prefix(maximum)) : Array(bank.prefix(maximum))
}