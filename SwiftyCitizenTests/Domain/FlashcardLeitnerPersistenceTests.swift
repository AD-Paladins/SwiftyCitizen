//
//  FlashcardLeitnerPersistenceTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct FlashcardLeitnerPersistenceTests {

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

    @Test func boxLevelRoundTripsThroughSwiftData() throws {
        let container = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let attempt = QuestionAttempt(
            questionStableID: "2025-001",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt,
            answerText: "The Constitution",
            boxLevel: 4
        )
        context.insert(attempt)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<QuestionAttempt>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.boxLevel == 4)
        // The projection carries the persisted box back into the domain record.
        #expect(fetched.first?.flashcardAttemptRecord?.boxLevel == 4)
    }

    @Test func defaultBoxLevelIsOne() {
        let attempt = QuestionAttempt(
            questionStableID: "2025-001",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt
        )
        #expect(attempt.boxLevel == 1)
    }

    @Test func resumeReconstructsBoxesFromStoredBoxLevel() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b")]
        let attempts = [
            FlashcardAttemptRecord(stableID: "a", testVersion: .twoThousandTwentyFive, assessment: .gotIt, answerText: nil, boxLevel: 3),
            FlashcardAttemptRecord(stableID: "b", testVersion: .twoThousandTwentyFive, assessment: .gotIt, answerText: nil, boxLevel: 2),
        ]
        let resumed = resumeFlashcardState(
            deckStableIDs: ["a", "b"],
            currentIndex: 0,
            attempts: attempts,
            deckQuestions: questions
        )
        #expect(resumed != nil)
        #expect(resumed?.boxes["a"] == 3)
        #expect(resumed?.boxes["b"] == 2)
    }

    @Test func resumeUsesTheLatestBoxLevelPerCard() {
        let questions = [makeQuestion(id: "a")]
        // Same card reviewed twice; the later attempt's box must win.
        let attempts = [
            FlashcardAttemptRecord(stableID: "a", testVersion: .twoThousandTwentyFive, assessment: .gotIt, answerText: nil, boxLevel: 2),
            FlashcardAttemptRecord(stableID: "a", testVersion: .twoThousandTwentyFive, assessment: .hard, answerText: nil, boxLevel: 1),
        ]
        let resumed = resumeFlashcardState(
            deckStableIDs: ["a"],
            currentIndex: 0,
            attempts: attempts,
            deckQuestions: questions
        )
        #expect(resumed?.boxes["a"] == 1)
    }
}
