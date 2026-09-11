import Foundation

enum ExamEngine {
    static func selectQuestions(
        from bank: [QuestionContent],
        maximum: Int,
        shuffle: (([QuestionContent]) -> [QuestionContent]) = { $0.shuffled() }
    ) -> [QuestionContent] {
        Array(shuffle(bank).prefix(maximum))
    }

    static func makeState(
        from bank: [QuestionContent],
        configuration: TestConfiguration,
        shuffle: (([QuestionContent]) -> [QuestionContent]) = { $0.shuffled() }
    ) -> MockTestState {
        let questions = selectQuestions(
            from: bank,
            maximum: configuration.maximumQuestionsAsked,
            shuffle: shuffle
        )
        return MockTestState(
            questions: questions,
            maximumQuestionsAsked: configuration.maximumQuestionsAsked,
            passingScore: configuration.passingScore
        )
    }
}