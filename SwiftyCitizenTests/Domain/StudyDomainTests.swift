//
//  StudyDomainTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/19/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct StudyDomainTests {

    @Test
    func resumeReturnsNilForEmptyDeck() {
        let state = StudyDomain.resumeFlashcardState(
            deckStableIDs: [],
            currentIndex: 0,
            attempts: [],
            deckQuestions: []
        )
        #expect(state == nil)
    }

    @Test
    func resumeSkipsQuestionsMissingFromDeck() {
        let state = StudyDomain.resumeFlashcardState(
            deckStableIDs: ["a", "c"],
            currentIndex: 0,
            attempts: [],
            deckQuestions: [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        )
        #expect(state?.questions.map(\.stableID) == ["a", "c"])
    }

    @Test
    func resumeRestoresAttemptsAndSeeksToIndex() {
        let state = StudyDomain.resumeFlashcardState(
            deckStableIDs: ["a", "b", "c"],
            currentIndex: 1,
            attempts: [
                FlashcardAttemptRecord(
                    stableID: "a",
                    testVersion: .twoThousandTwentyFive,
                    assessment: .gotIt
                )
            ],
            deckQuestions: [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        )

        #expect(state?.currentQuestion?.stableID == "b")
        #expect(state?.answeredCount == 1)
        #expect(state?.attempts.first?.assessment == .gotIt)
    }

    @Test
    func resumeClampsIndexBeyondDeck() {
        let state = StudyDomain.resumeFlashcardState(
            deckStableIDs: ["a", "b"],
            currentIndex: 99,
            attempts: [],
            deckQuestions: [makeQuestion(id: "a"), makeQuestion(id: "b")]
        )
        #expect(state?.isComplete == true)
    }

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
}
