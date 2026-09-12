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
        stableID: String = "sel-1",
        topic: String = "Rights",
        accepted: [String] = ["the Constitution"],
        cardinality: Int = 1
    ) -> QuestionContent {
        QuestionContent(
            stableID: stableID,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What are the rights?",
            acceptedAnswerVariants: accepted,
            answerCardinality: .exactly(cardinality),
            topic: topic,
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    // MARK: - Distractor pool (runtime topic-pool generation)

    @Test func distractorPoolIsDeterministic() {
        let bank = [
            makeQuestion(stableID: "q-1", topic: "Government", accepted: ["life", "liberty"]),
            makeQuestion(stableID: "q-2", topic: "Government", accepted: ["freedom of speech", "freedom of religion"]),
            makeQuestion(stableID: "q-3", topic: "Government", accepted: ["the right to assemble", "the right to petition"])
        ]
        let question = bank[0]
        let first = QuestionContent.distractorOptions(for: question, from: bank)
        let second = QuestionContent.distractorOptions(for: question, from: bank)
        #expect(first == second)
    }

    @Test func distractorsNeverOverlapOwnAcceptedVariants() {
        let bank = [
            makeQuestion(stableID: "q-1", topic: "Government", accepted: ["life", "liberty"]),
            makeQuestion(stableID: "q-2", topic: "Government", accepted: ["life", "liberty", "pursuit of happiness"])
        ]
        let question = bank[0]
        let distractors = QuestionContent.distractorOptions(for: question, from: bank)
        #expect(distractors.allSatisfy { $0 != "life" && $0 != "liberty" })
    }

    @Test func distractorsExcludeVariableAnswerVariants() {
        let bank = [
            makeQuestion(stableID: "q-1", topic: "Government", accepted: ["life", "liberty"]),
            makeQuestion(stableID: "q-2", topic: "Government", accepted: ["Answers will vary. [Name your governor.]"])
        ]
        let question = bank[0]
        let distractors = QuestionContent.distractorOptions(for: question, from: bank)
        #expect(!distractors.contains { $0.lowercased().contains("answers will vary") })
    }

    @Test func distractorsAreCappedAtFour() {
        let bank = [
            makeQuestion(stableID: "q-1", topic: "Government", accepted: ["life", "liberty"]),
            makeQuestion(stableID: "q-2", topic: "Government", accepted: ["a", "b", "c", "d", "e", "f"])
        ]
        let question = bank[0]
        let distractors = QuestionContent.distractorOptions(for: question, from: bank)
        #expect(distractors.count <= 4)
    }

    @Test func thinTopicYieldsNoDistractors() {
        let bank = [makeQuestion(stableID: "q-1", topic: "Sole", accepted: ["only answer"])]
        let question = bank[0]
        let distractors = QuestionContent.distractorOptions(for: question, from: bank)
        #expect(distractors.isEmpty)
    }

    @Test func seededShuffleIsDeterministicAndPermutations() {
        let array = ["a", "b", "c", "d"]
        let first = array.seededShuffled(seed: 42)
        let second = array.seededShuffled(seed: 42)
        #expect(first == second)
        #expect(Set(first) == Set(array))
    }

    @Test func distractorSelectionScoresIncorrect() {
        let bank = [
            makeQuestion(stableID: "q-1", topic: "Government", accepted: ["life", "liberty"], cardinality: 2),
            makeQuestion(stableID: "q-2", topic: "Government", accepted: ["the right to assemble"])
        ]
        let question = bank[0]
        var state = MockTestState(questions: [question], maximumQuestionsAsked: 1, passingScore: 1)
        // A distractor ("the right to assemble") is not one of the two accepted variants.
        let answer = state.record("liberty the right to assemble")
        #expect(answer?.isCorrect == false)
    }

    // MARK: - Next advances to the following question (feedback-ON cycle)

    @Test func nextAdvancesAfterRecordingWithoutAdvancing() {
        // Mirrors MockTestSessionView: feedback ON records without advancing, then "Next" advances.
        let questions = [
            makeQuestion(stableID: "q-1", topic: "Government", accepted: ["life"], cardinality: 1),
            makeQuestion(stableID: "q-2", topic: "Government", accepted: ["liberty"], cardinality: 1)
        ]
        var state = MockTestState(questions: questions, maximumQuestionsAsked: 20, passingScore: 12)

        let recorded = state.record("life")          // submit() records, does not advance
        #expect(recorded?.isCorrect == true)
        #expect(state.currentIndex == 0)

        state.advance()                              // Next tap moves to the following question
        #expect(state.currentIndex == 1)
        #expect(state.currentQuestion?.stableID == "q-2")
    }
}
