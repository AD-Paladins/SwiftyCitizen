//
//  SelectionAnswerTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/12/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct SelectionAnswerTests {

    // MARK: - answerInputMode presentation rule

    @Test
    func selectionModeWhenMultipleOfficialVariants() {
        let question = makeQuestion(accepted: ["life", "liberty", "pursuit of happiness"], cardinality: 2)
        #expect(question.answerInputMode == .selection)
    }

    @Test
    func textModeForSingleVariant() {
        let question = makeQuestion(accepted: ["the Constitution"], cardinality: 1)
        #expect(question.answerInputMode == .text)
    }

    @Test
    func textModeWhenAnswerVaries() {
        let question = makeQuestion(accepted: ["Answers will vary. [Residents should name their governor.]"])
        #expect(question.answerInputMode == .text)
    }

    @Test
    func textModeForCurrentAnswerQuestions() {
        let question = makeQuestion(
            accepted: ["Visit uscis.gov/citizenship/testupdates for the name of the President now."]
        )
        #expect(question.answerInputMode == .text)
    }

    @Test
    func selectionModeForFixedMultiVariantGovernmentQuestion() {
        // Fixed answers despite jurisdiction flag: 2008-036 Cabinet positions.
        let question = makeQuestion(
            accepted: ["Secretary of Defense", "Secretary of the Treasury", "Attorney General"],
            cardinality: 2
        )
        #expect(question.answerInputMode == .selection)
    }

    // MARK: - Selection scoring through MockTestState (mirrors view submit)

    @Test
    func singleSelectRecordsCorrectVariant() {
        let question = makeQuestion(accepted: ["announced our independence", "declared our independence"], cardinality: 1)
        var state = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)

        let answer = state.record("declared our independence")
        #expect(answer?.isCorrect == true)
    }

    @Test
    func singleSelectRejectsUnselectedVariant() {
        let question = makeQuestion(accepted: ["announced our independence", "declared our independence"], cardinality: 1)
        var state = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)

        let answer = state.record("declared our sovereignty")
        #expect(answer?.isCorrect == false)
    }

    @Test
    func multiSelectPassesWhenRequiredVariantsNamed() {
        let question = makeQuestion(accepted: ["life", "liberty", "pursuit of happiness"], cardinality: 2)
        var state = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)

        // The view joins the selected variants with a space.
        let answer = state.record("life liberty")
        #expect(answer?.isCorrect == true)
    }

    @Test
    func multiSelectFailsWhenOnlyOneVariantNamed() {
        let question = makeQuestion(accepted: ["life", "liberty", "pursuit of happiness"], cardinality: 2)
        var state = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)

        let answer = state.record("life")
        #expect(answer?.isCorrect == false)
    }

    @Test
    func multiSelectPassesWithAnyValidPair() {
        let question = makeQuestion(accepted: ["life", "liberty", "pursuit of happiness"], cardinality: 2)

        var state1 = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)
        #expect(state1.record("liberty pursuit of happiness")?.isCorrect == true)

        var state2 = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)
        #expect(state2.record("life pursuit of happiness")?.isCorrect == true)
    }

    private func makeQuestion(
        accepted: [String] = ["the Constitution"],
        cardinality: Int = 1
    ) -> QuestionContent {
        QuestionContent(
            stableID: "sel-1",
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What are the rights?",
            acceptedAnswerVariants: accepted,
            answerCardinality: .exactly(cardinality),
            topic: "Rights",
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }
}
