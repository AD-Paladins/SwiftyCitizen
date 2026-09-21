//
//  QuestionContentTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/19/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct QuestionContentTests {

    // MARK: answerInputMode

    @Test
    func singleVariantUsesTextMode() {
        let question = sampleQuestion(
            id: "one",
            variants: ["The Constitution"],
            topic: "Government"
        )
        #expect(question.answerInputMode == .text)
    }

    @Test
    func multipleCleanVariantsUseSelectionMode() {
        let question = sampleQuestion(
            id: "two",
            variants: ["Congress", "The legislature"],
            topic: "Government"
        )
        #expect(question.answerInputMode == .selection)
    }

    @Test
    func multipleVariantsWithWordingFallBackToText() {
        let question = sampleQuestion(
            id: "three",
            variants: ["Answers will vary", "The president"],
            topic: "Government"
        )
        #expect(question.answerInputMode == .text)
    }

    // MARK: distractorOptions

    @Test
    func distractorsComeFromSameTopicOnly() {
        let target = sampleQuestion(id: "target", variants: ["Congress"], topic: "Government")
        let bank = [
            sampleQuestion(id: "gov-a", variants: ["The courts"], topic: "Government"),
            sampleQuestion(id: "other-a", variants: ["Water flows down"], topic: "History"),
        ]
        let distractors = QuestionContent.distractorOptions(for: target, from: bank)
        #expect(distractors == ["The courts"])
    }

    @Test
    func distractorsExcludeOwnVariantsAndVariableWording() {
        let target = sampleQuestion(id: "target", variants: ["Congress"], topic: "Government")
        let bank = [
            sampleQuestion(id: "gov-a", variants: ["Congress", "Answers will vary"], topic: "Government"),
            sampleQuestion(id: "gov-b", variants: ["The courts"], topic: "Government"),
        ]
        let distractors = QuestionContent.distractorOptions(for: target, from: bank)
        #expect(distractors == ["The courts"])
    }

    @Test
    func distractorsAreCappedAtFour() {
        let target = sampleQuestion(id: "target", variants: ["Congress"], topic: "Government")
        let bank = (1...6).map {
            sampleQuestion(id: "gov-\($0)", variants: ["Option \($0)"], topic: "Government")
        }
        let distractors = QuestionContent.distractorOptions(for: target, from: bank)
        #expect(distractors.count == 4)
        #expect(distractors == distractors.sorted())
        #expect(distractors.allSatisfy { $0.hasPrefix("Option ") })
    }

    // MARK: shuffleSeed

    @Test
    func shuffleSeedIsDeterministic() {
        #expect(QuestionContent.shuffleSeed(for: "2025-001") == QuestionContent.shuffleSeed(for: "2025-001"))
        #expect(QuestionContent.shuffleSeed(for: "2025-001") != QuestionContent.shuffleSeed(for: "2025-002"))
    }

    @Test
    func seededShuffleIsStableForSameSeed() {
        let original = ["a", "b", "c", "d", "e"]
        var firstRng = SeededShuffle(seed: QuestionContent.shuffleSeed(for: "seed"))
        let first = original.shuffled(using: &firstRng)
        var secondRng = SeededShuffle(seed: QuestionContent.shuffleSeed(for: "seed"))
        let second = original.shuffled(using: &secondRng)
        #expect(first == second)
        #expect(first.sorted() == original)
    }

    // MARK: QuestionContentValidator

    @Test
    func validBankPassesValidation() {
        let config = matchingConfig(count: 2)
        let questions = [
            sampleQuestion(id: "2025-001", variants: ["Congress"], topic: "Government"),
            sampleQuestion(id: "2025-002", variants: ["The courts"], topic: "Government"),
        ]
        switch QuestionContentValidator.validate(questions, for: config) {
        case .success:
            break
        case .failure:
            #expect(false, "expected a valid bank")
        }
    }

    @Test
    func invalidQuestionCountIsReported() {
        let config = matchingConfig(count: 5)
        let questions = [sampleQuestion(id: "2025-001", variants: ["Congress"], topic: "Government")]
        switch QuestionContentValidator.validate(questions, for: config) {
        case .failure(let failure):
            #expect(failure.errors.contains(.invalidQuestionCount(expected: 5, actual: 1)))
        case .success:
            #expect(false, "expected validation failure")
        }
    }

    @Test
    func emptyQuestionTextAndAnswersAreReported() {
        let config = matchingConfig(count: 1)
        let questions = [
            QuestionContent(
                stableID: "2025-001",
                testVersion: .twoThousandTwentyFive,
                officialQuestion: "",
                acceptedAnswerVariants: [""],
                answerCardinality: .exactly(1),
                topic: "",
                sourceURL: URL(string: "https://www.uscis.gov")!,
                sourceRevision: "2025-09-10",
                verificationDate: Date(timeIntervalSince1970: 0),
                isJurisdictionDependent: false,
                isSixtyFiveTwentyQuestion: false
            )
        ]
        switch QuestionContentValidator.validate(questions, for: config) {
        case .failure(let failure):
            #expect(failure.errors.contains(.emptyQuestionText(id: "2025-001")))
            #expect(failure.errors.contains(.emptyTopic(id: "2025-001")))
            #expect(failure.errors.contains(.emptyAcceptedAnswers(id: "2025-001")))
        case .success:
            #expect(false, "expected validation failure")
        }
    }

    @Test
    func duplicateIdIsReported() {
        let config = matchingConfig(count: 2)
        let questions = [
            sampleQuestion(id: "dup", variants: ["Congress"], topic: "Government"),
            sampleQuestion(id: "dup", variants: ["The courts"], topic: "Government"),
        ]
        switch QuestionContentValidator.validate(questions, for: config) {
        case .failure(let failure):
            #expect(failure.errors.contains(.duplicateID(id: "dup")))
        case .success:
            #expect(false, "expected validation failure")
        }
    }

    @Test
    func wrongVersionQuestionIsReported() {
        let config = matchingConfig(count: 1)
        let questions = [
            QuestionContent(
                stableID: "2008-001",
                testVersion: .twoThousandEight,
                officialQuestion: "Question?",
                acceptedAnswerVariants: ["Answer"],
                answerCardinality: .exactly(1),
                topic: "Government",
                sourceURL: URL(string: "https://www.uscis.gov")!,
                sourceRevision: "2025-09-10",
                verificationDate: Date(timeIntervalSince1970: 0),
                isJurisdictionDependent: false,
                isSixtyFiveTwentyQuestion: false
            )
        ]
        switch QuestionContentValidator.validate(questions, for: config) {
        case .failure(let failure):
            #expect(failure.errors.contains(.questionAssignedToWrongBank(
                id: "2008-001",
                expected: .twoThousandTwentyFive,
                actual: .twoThousandEight
            )))
        case .success:
            #expect(false, "expected validation failure")
        }
    }

    private func matchingConfig(count: Int) -> TestConfiguration {
        TestConfiguration(
            version: .twoThousandTwentyFive,
            questionBankCount: count,
            maximumQuestionsAsked: 20,
            passingScore: 12,
            applicability: .filingOnOrAfterOctober20th2025
        )
    }

    // MARK: helpers

    private func sampleQuestion(
        id: String,
        variants: [String],
        topic: String
    ) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What is \(topic)?",
            acceptedAnswerVariants: variants,
            answerCardinality: .exactly(variants.count),
            topic: topic,
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }
}
