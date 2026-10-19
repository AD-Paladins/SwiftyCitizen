//
//  SessionWeakTopicsTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct SessionWeakTopicsTests {

    private func question(id: String, topic: String) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What is the supreme law of the land?",
            acceptedAnswerVariants: ["The Constitution"],
            answerCardinality: .exactly(1),
            topic: topic,
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    private func attempt(id: String, assessment: SelfAssessment) -> FlashcardAttemptRecord {
        FlashcardAttemptRecord(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            assessment: assessment,
            answerText: nil
        )
    }

    @Test func emptySessionHasNoWeakTopics() {
        let questions = [question(id: "a", topic: "Government")]
        #expect(SessionWeakTopics.compute(attempts: [], questions: questions).isEmpty)
        #expect(SessionWeakTopics.weakStableIDs(attempts: [], questions: questions).isEmpty)
    }

    @Test func allGotItHasNoWeakTopics() {
        let questions = [question(id: "a", topic: "Government")]
        let attempts = [attempt(id: "a", assessment: .gotIt)]
        #expect(SessionWeakTopics.compute(attempts: attempts, questions: questions).isEmpty)
    }

    @Test func missMarksTopicWeak() {
        let questions = [question(id: "a", topic: "Government")]
        let attempts = [attempt(id: "a", assessment: .again)]
        let weak = SessionWeakTopics.compute(attempts: attempts, questions: questions)
        #expect(weak == [WeakTopic(topic: "Government", weakCards: 1)])
        #expect(SessionWeakTopics.weakStableIDs(attempts: attempts, questions: questions) == ["a"])
    }

    @Test func lowSuccessRateMarksTopicWeak() {
        // .hard only → 0/1 gotIt → at/below the 0.5 threshold.
        let questions = [question(id: "a", topic: "Government")]
        let attempts = [attempt(id: "a", assessment: .hard)]
        let weak = SessionWeakTopics.compute(attempts: attempts, questions: questions)
        #expect(weak == [WeakTopic(topic: "Government", weakCards: 1)])
    }

    @Test func recoveredAboveThresholdStillWeakBecauseOfMiss() {
        // .again then two .gotIt → 2/3 > 0.5, but the miss keeps it weak.
        let questions = [question(id: "a", topic: "Government")]
        let attempts = [
            attempt(id: "a", assessment: .again),
            attempt(id: "a", assessment: .gotIt),
            attempt(id: "a", assessment: .gotIt),
        ]
        let weak = SessionWeakTopics.compute(attempts: attempts, questions: questions)
        #expect(weak == [WeakTopic(topic: "Government", weakCards: 1)])
    }

    @Test func aggregatesWeakCardsPerTopicAndSorts() {
        let questions = [
            question(id: "a", topic: "Government"),
            question(id: "b", topic: "Government"),
            question(id: "c", topic: "History"),
        ]
        let attempts = [
            attempt(id: "a", assessment: .again),   // Government weak
            attempt(id: "b", assessment: .gotIt),   // Government strong
            attempt(id: "c", assessment: .again),   // History weak
        ]
        let weak = SessionWeakTopics.compute(attempts: attempts, questions: questions)
        #expect(weak == [
            WeakTopic(topic: "Government", weakCards: 1),
            WeakTopic(topic: "History", weakCards: 1),
        ])
        #expect(SessionWeakTopics.weakStableIDs(attempts: attempts, questions: questions) == ["a", "c"])
    }

    @Test func thresholdBoundaryIsWeak() {
        // .again + .gotIt → 1/2 = 0.5, exactly at the threshold → weak.
        let questions = [question(id: "a", topic: "Government")]
        let attempts = [
            attempt(id: "a", assessment: .again),
            attempt(id: "a", assessment: .gotIt),
        ]
        #expect(!SessionWeakTopics.compute(attempts: attempts, questions: questions).isEmpty)
    }

    @Test func ignoresAttemptsForQuestionsMissingFromDeck() {
        // An attempt whose stableID isn't in the deck maps to no topic and is skipped.
        let questions = [question(id: "a", topic: "Government")]
        let attempts = [
            attempt(id: "a", assessment: .again),
            attempt(id: "ghost", assessment: .again),
        ]
        let weak = SessionWeakTopics.compute(attempts: attempts, questions: questions)
        #expect(weak == [WeakTopic(topic: "Government", weakCards: 1)])
    }
}
