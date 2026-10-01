//
//  FlashcardLeitnerTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct FlashcardLeitnerTests {

    private func makeQuestion(id: String) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            officialQuestion: "What is the supreme law of the land?",
            acceptedAnswerVariants: ["The Constitution"],
            answerCardinality: .exactly(1),
            topic: "Government",
            sourceURL: URL(string: "https://www.uscis.gov/citizenship")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }

    @Test func newCardsStartInBoxOne() {
        var state = FlashcardState(questions: [makeQuestion(id: "a"), makeQuestion(id: "b")])
        #expect(state.currentBox == 1)
        #expect(state.boxes["a"] == 1)
        #expect(state.boxes["b"] == 1)
    }

    @Test func masteredStampsTheBoxOnTheAttempt() {
        var state = FlashcardState(questions: [makeQuestion(id: "a"), makeQuestion(id: "b")])
        state.reveal()
        let attempt = state.assess(.gotIt)
        #expect(attempt?.boxLevel == 2)
        #expect(state.boxes["a"] == 2)
    }

    @Test func masteredClimbsBoxesAcrossReviews() {
        // A card only advances one box per review; revisiting it (seek) climbs the boxes.
        var state = FlashcardState(questions: [makeQuestion(id: "a"), makeQuestion(id: "b")])
        for _ in 0..<4 {
            state.seek(to: 0)
            state.reveal()
            state.assess(.gotIt)
        }
        state.seek(to: 0)
        #expect(state.currentBox == LeitnerScheduler.maxBox)
        #expect(state.boxes["a"] == LeitnerScheduler.maxBox)
    }

    @Test func hardDropsTheBoxOneStep() {
        var state = FlashcardState(questions: [makeQuestion(id: "a"), makeQuestion(id: "b")])
        state.reveal(); state.assess(.gotIt)   // a -> 2, advances to b
        state.seek(to: 0)                       // back to a (box 2)
        state.reveal()
        let soft = state.assess(.hard)          // a -> 1
        #expect(soft?.boxLevel == 1)
        #expect(state.boxes["a"] == 1)
    }

    @Test func againResetsToBoxOneAndRecordsNoAttempt() {
        var state = FlashcardState(questions: [makeQuestion(id: "a"), makeQuestion(id: "b")])
        state.reveal(); state.assess(.gotIt)   // a -> 2, advances to b
        state.seek(to: 0)                       // back to a (box 2)
        state.reveal()
        let again = state.assess(.again)
        #expect(again == nil)
        #expect(state.boxes["a"] == 1)          // reset on miss
        #expect(state.attempts.count == 1)      // no new attempt recorded
    }

    @Test func boxIsTrackedPerCard() {
        var state = FlashcardState(questions: [makeQuestion(id: "a"), makeQuestion(id: "b")])
        state.reveal(); state.assess(.gotIt)   // a -> 2, advances to b
        #expect(state.boxes["a"] == 2)
        #expect(state.currentBox == 1)         // b still in box 1
    }
}
