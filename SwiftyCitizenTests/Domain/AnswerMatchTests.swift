//
//  AnswerMatchTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/11/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct AnswerMatchTests {

    private func makeQuestion(
        id: String = "1",
        accepted: [String] = ["the Constitution"],
        cardinality: Int = 1
    ) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
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
    func completeWhenAnswerMatchesVariantExactly() {
        let question = makeQuestion()

        let match = AnswerEvaluator.matchType("the Constitution", against: question)

        #expect(match == .complete)
    }

    @Test
    func partialWhenAnswerIsSubsetOfVariant() {
        let question = makeQuestion()

        // "Constitution" alone is a subset of "the Constitution": evaluate passes,
        // but it is not an exact match, so it is the lenient warning case.
        let match = AnswerEvaluator.matchType("Constitution", against: question)
        let evaluated = AnswerEvaluator.evaluate("Constitution", against: question)

        #expect(match == .partial)
        #expect(evaluated)
    }

    @Test
    func partialWhenAnswerHasCloseOverlapButIsRejected() {
        let question = makeQuestion()

        // "Constitution Act" overlaps the variant but is not a subset, so it is
        // rejected yet still classified as partial via close overlap.
        let match = AnswerEvaluator.matchType("Constitution Act", against: question)
        let evaluated = AnswerEvaluator.evaluate("Constitution Act", against: question)

        #expect(match == .partial)
        #expect(!evaluated)
    }

    @Test
    func noneWhenAnswerHasNoOverlap() {
        let question = makeQuestion()

        let match = AnswerEvaluator.matchType("Bill of Rights", against: question)
        let evaluated = AnswerEvaluator.evaluate("Bill of Rights", against: question)

        #expect(match == .none)
        #expect(!evaluated)
    }

    @Test
    func noneWhenAnswerIsEmpty() {
        let question = makeQuestion()

        #expect(AnswerEvaluator.matchType("", against: question) == .none)
    }

    @Test
    func completeCardinalityTwoWhenBothVariantsNamed() {
        let question = makeQuestion(
            accepted: ["life", "liberty", "pursuit of happiness"],
            cardinality: 2
        )

        #expect(AnswerEvaluator.matchType("life and liberty", against: question) == .complete)
    }

    @Test
    func partialCardinalityTwoWhenOnlyOneNamed() {
        let question = makeQuestion(
            accepted: ["life", "liberty", "pursuit of happiness"],
            cardinality: 2
        )

        #expect(AnswerEvaluator.matchType("life", against: question) == .partial)
    }

    @Test
    func presentationCorrectWhenAnswerMatchesVariant() {
        let question = makeQuestion()

        let presentation = AnswerEvaluator.presentation(for: "the Constitution", against: question)

        #expect(presentation.verdict == .correct)
        #expect(presentation.yourAnswer == "the Constitution")
        #expect(presentation.officialText == "the Constitution")
    }

    @Test
    func presentationPartialWhenAnswerOverlapsVariant() {
        let question = makeQuestion(
            accepted: ["life", "liberty", "pursuit of happiness"],
            cardinality: 2
        )

        let presentation = AnswerEvaluator.presentation(for: "life", against: question)

        #expect(presentation.verdict == .partial)
        #expect(presentation.yourAnswer == "life")
    }

    @Test
    func presentationIncorrectWhenAnswerDoesNotMatch() {
        let question = makeQuestion()

        let presentation = AnswerEvaluator.presentation(for: "freedom of speech", against: question)

        #expect(presentation.verdict == .incorrect)
        #expect(presentation.yourAnswer == "freedom of speech")
        #expect(presentation.officialText == "the Constitution")
    }

    @Test
    func presentationUnansweredWhenNoUserAnswer() {
        let question = makeQuestion()

        let presentation = AnswerEvaluator.presentation(for: nil, against: question)

        #expect(presentation.verdict == .unanswered)
        #expect(presentation.yourAnswer == nil)
        #expect(presentation.officialText == nil)
    }

    @Test
    func presentationUnansweredWhenEmptyUserAnswer() {
        let question = makeQuestion()

        let presentation = AnswerEvaluator.presentation(for: "", against: question)

        #expect(presentation.verdict == .unanswered)
    }

    @Test
    func presentationJoinsMultipleAcceptedVariants() {
        let question = makeQuestion(
            accepted: ["life", "liberty"],
            cardinality: 1
        )

        let presentation = AnswerEvaluator.presentation(for: "life", against: question)

        #expect(presentation.verdict == .correct)
        #expect(presentation.officialText == "life · liberty")
    }
}
