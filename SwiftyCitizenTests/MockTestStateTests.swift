//
//  MockTestStateTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/11/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct MockTestStateTests {

    private func makeQuestion(id: String = "1") -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What is the supreme law of the land?",
            acceptedAnswerVariants: ["the Constitution"],
            answerCardinality: .exactly(1),
            topic: "Government",
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    @Test
    func recordDoesNotAdvanceIndex() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1")],
            maximumQuestionsAsked: 3,
            passingScore: 1
        )

        let recorded = state.record("the Constitution", answeredAt: Date())

        #expect(state.currentIndex == 0)
        #expect(state.answers.count == 1)
        #expect(recorded != nil)
    }

    @Test
    func recordReturnsEvaluatedAnswer() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1")],
            maximumQuestionsAsked: 3,
            passingScore: 1
        )

        let recorded = state.record("the Constitution", answeredAt: Date())

        #expect(recorded?.questionStableID == "1")
        #expect(recorded?.response == "the Constitution")
        #expect(recorded?.isCorrect == true)
    }

    @Test
    func recordPreservesResponseForReview() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1")],
            maximumQuestionsAsked: 3,
            passingScore: 1
        )

        let recorded = state.record("wrong answer", answeredAt: Date())

        #expect(recorded?.response == "wrong answer")
    }

    @Test
    func submitAdvancesIndex() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1"), makeQuestion(id: "2")],
            maximumQuestionsAsked: 3,
            passingScore: 1
        )

        state.submit("the Constitution", answeredAt: Date())

        #expect(state.currentIndex == 1)
    }

    @Test
    func recordKeepsIndexWhileSubmitAdvances() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1"), makeQuestion(id: "2")],
            maximumQuestionsAsked: 3,
            passingScore: 3
        )

        let recorded = state.record("the Constitution", answeredAt: Date())
        #expect(state.currentIndex == 0)

        _ = recorded
        state.submit("the Constitution", answeredAt: Date())
        #expect(state.currentIndex == 1)
    }

    @Test
    func advanceIsNoOpWhileActive() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1"), makeQuestion(id: "2")],
            maximumQuestionsAsked: 3,
            passingScore: 1
        )

        state.advance()

        #expect(state.currentIndex == 0)
    }

    @Test
    func advanceAdvancesWhenComplete() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1"), makeQuestion(id: "2")],
            maximumQuestionsAsked: 2,
            passingScore: 1
        )
        state.submit("the Constitution", answeredAt: Date())

        #expect(state.isComplete)
        let before = state.currentIndex
        state.advance()
        #expect(state.currentIndex == before + 1)
    }

    @Test
    func lenientAnswerIsFlaggedAsWarning() {
        var state = MockTestState(
            questions: [makeQuestion(id: "1")],
            maximumQuestionsAsked: 3,
            passingScore: 1
        )
        let recorded = state.record("Constitution", answeredAt: Date())

        #expect(recorded?.isCorrect == true)
        #expect(recorded?.matchType == .partial)
    }
}
