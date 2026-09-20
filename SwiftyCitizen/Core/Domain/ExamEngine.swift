import Foundation

func makeState(
    from bank: [QuestionContent],
    configuration: TestConfiguration,
    shuffleEnabled: Bool
) -> MockTestState {
    let questions = selectQuestions(
        from: bank,
        maximum: configuration.maximumQuestionsAsked,
        shuffleEnabled: shuffleEnabled
    )
    return MockTestState(
        questions: questions,
        maximumQuestionsAsked: configuration.maximumQuestionsAsked,
        passingScore: configuration.passingScore
    )
}

func selectQuestions(
    from bank: [QuestionContent],
    maximum: Int,
    shuffleEnabled: Bool
) -> [QuestionContent] {
    shuffleEnabled ? Array(bank.shuffled().prefix(maximum)) : Array(bank.prefix(maximum))
}