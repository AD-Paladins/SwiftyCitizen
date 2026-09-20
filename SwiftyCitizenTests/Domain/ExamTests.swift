//
//  ExamTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct ExamTests {

    @Test
    func evaluatorAcceptsExactSingleAnswer() {
        let question = makeQuestion(
            accepted: ["the Constitution"],
            cardinality: 1
        )

        #expect(AnswerEvaluator.evaluate("The Constitution", against: question))
        #expect(AnswerEvaluator.evaluate("  the  constitution ", against: question))
        #expect(!AnswerEvaluator.evaluate("", against: question))
        #expect(!AnswerEvaluator.evaluate("The Bill of Rights", against: question))
    }

    @Test
    func evaluatorAcceptsOneKeywordForLongerVariant() {
        let question = makeQuestion(
            accepted: ["sets up the government", "defines the government"],
            cardinality: 1
        )

        #expect(AnswerEvaluator.evaluate("sets up the government", against: question))
        #expect(AnswerEvaluator.evaluate("defines the government", against: question))
        #expect(!AnswerEvaluator.evaluate("declares war", against: question))
    }

    @Test
    func evaluatorRequiresDistinctPairsForCardinalityTwo() {
        let question = makeQuestion(
            accepted: ["life", "liberty", "pursuit of happiness"],
            cardinality: 2
        )

        #expect(AnswerEvaluator.evaluate("life and liberty", against: question))
        #expect(AnswerEvaluator.evaluate("liberty, pursuit of happiness", against: question))
        #expect(!AnswerEvaluator.evaluate("life", against: question))
        #expect(!AnswerEvaluator.evaluate("life and life", against: question))
    }

    @Test
    func evaluatorHandlesParenthesizedOptionalText() {
        let question = makeQuestion(
            accepted: ["Missouri (River)", "Mississippi (River)"],
            cardinality: 1
        )

        #expect(AnswerEvaluator.evaluate("Missouri River", against: question))
        #expect(AnswerEvaluator.evaluate("Mississippi", against: question))
    }

    @Test(arguments: TestConfiguration.all)
    func stateSelectsMaximumQuestionsPerConfiguration(configuration: TestConfiguration) throws {
        let bank = try QuestionBankLoader().load(version: configuration.version)

        let state = makeState(
            from: bank,
            configuration: configuration,
            shuffleEnabled: false
        )

        #expect(state.questions.count == configuration.maximumQuestionsAsked)
        #expect(state.maximumQuestionsAsked == configuration.maximumQuestionsAsked)
        #expect(state.passingScore == configuration.passingScore)
        #expect(state.phase == .active)
    }

    @Test
    func stateStopsEarlyOnPassingScore() {
        let questions = [makeQuestion(id: "1"), makeQuestion(id: "2"), makeQuestion(id: "3")]
        var state = MockTestState(
            questions: questions,
            maximumQuestionsAsked: 10,
            passingScore: 2
        )

        state.submit("the Constitution", answeredAt: Date())
        state.submit("the Constitution", answeredAt: Date())

        #expect(state.correctCount == 2)
        #expect(state.phase == .complete(.passed))
        #expect(state.isComplete)
    }

    @Test
    func stateStopsEarlyWhenPassingBecomesImpossible() {
        let questions = [makeQuestion(id: "1"), makeQuestion(id: "2"), makeQuestion(id: "3")]
        var state = MockTestState(
            questions: questions,
            maximumQuestionsAsked: 3,
            passingScore: 2
        )

        state.submit("wrong", answeredAt: Date())
        state.submit("wrong", answeredAt: Date())

        #expect(state.incorrectCount == 2)
        #expect(state.phase == .complete(.failed))
    }

    @Test
    func stateRunsFullDeckWhenOutcomeIsStillOpen() {
        let questions = [
            makeQuestion(id: "1"),
            makeQuestion(id: "2"),
            makeQuestion(id: "3"),
        ]
        var state = MockTestState(
            questions: questions,
            maximumQuestionsAsked: 3,
            passingScore: 2
        )

        state.submit("wrong", answeredAt: Date())
        state.submit("the Constitution", answeredAt: Date())
        state.submit("wrong", answeredAt: Date())

        #expect(state.answers.count == 3)
        #expect(state.phase == .complete(.failed))
    }

    @Test
    func stateIgnoresSubmissionsAfterCompletion() {
        let questions = [makeQuestion(id: "1")]
        var state = MockTestState(
            questions: questions,
            maximumQuestionsAsked: 1,
            passingScore: 1
        )

        let first = state.submit("the Constitution")
        let second = state.submit("the Constitution")

        #expect(first == .complete(.passed))
        #expect(second == .complete(.passed))
        #expect(state.answers.count == 1)
    }

    @Test
    func missingAnswerReportsCorrectCounts() {
        let question = makeQuestion(
            accepted: ["the Constitution"],
            cardinality: 1
        )
        var state = MockTestState(
            questions: [question],
            maximumQuestionsAsked: 1,
            passingScore: 1
        )

        state.submit("obamacare", answeredAt: Date())

        #expect(state.correctCount == 0)
        #expect(state.incorrectCount == 1)
        #expect(state.phase == .complete(.failed))
    }

    @Test
    func mockTestAttemptPersistsAnswerAndResult() throws {
        let modelContainer = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let session = StudySession(mode: .mockTest, testVersion: .twoThousandTwentyFive)
        let attempt = QuestionAttempt(
            questionStableID: "2025-001",
            testVersion: .twoThousandTwentyFive,
            answerText: "The Constitution",
            wasCorrect: true
        )
        session.attempts.append(attempt)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<QuestionAttempt>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.answerText == "The Constitution")
        #expect(fetched.first?.wasCorrect == true)
        #expect(fetched.first?.assessment == nil)
    }

    @Test
    func revisableBankCardinalityMatchesQuestionType() throws {
        let bank2025 = try QuestionBankLoader().load(version: .twoThousandTwentyFive)
        let bank2008 = try QuestionBankLoader().load(version: .twoThousandEight)

        #expect(bank2025.first { $0.stableID == "2025-028" }?.answerCardinality == .exactly(1))
        #expect(bank2008.first { $0.stableID == "2008-088" }?.answerCardinality == .exactly(1))
    }

    private func makeQuestion(
        id: String = "1",
        version: USCISTestVersion = .twoThousandTwentyFive,
        accepted: [String] = ["the Constitution"],
        cardinality: Int = 1
    ) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: version,
            officialQuestion: "What is the supreme law of the land?",
            acceptedAnswerVariants: accepted,
            answerCardinality: .exactly(cardinality),
            topic: "Government",
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    @Test
    func savedConfigurationPreservesShuffleSetting() throws {
        let modelContainer = try ModelContainer(
            for: SavedOnboardingConfiguration.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let config = OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: true
        )
        context.insert(SavedOnboardingConfiguration(configuration: config))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedOnboardingConfiguration>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.configuration?.shuffleQuestions == true)
    }

    @Test
    func selectQuestionsRespectsShuffleFlag() {
        let bank = [
            makeQuestion(id: "a"),
            makeQuestion(id: "b"),
            makeQuestion(id: "c"),
            makeQuestion(id: "d"),
        ]

        let ordered = selectQuestions(from: bank, maximum: 2, shuffleEnabled: false)
        #expect(ordered.map(\.stableID) == ["a", "b"])

        let shuffled = selectQuestions(from: bank, maximum: 4, shuffleEnabled: true)
        #expect(Set(shuffled.map(\.stableID)) == Set(bank.map(\.stableID)))
    }
}