//
//  TargetedReviewTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct TargetedReviewTests {

    @Test
    func unansweredScopeDropsAttemptedQuestions() {
        let questions = [makeQuestion(id: "one"), makeQuestion(id: "two")]
        let attempts = [
            StudyAttemptSnapshot(
                stableID: "one",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: Date()
            )
        ]

        let deck = ReviewDeckBuilder.build(
            questions: questions,
            attempts: attempts,
            scope: .unanswered
        )

        #expect(deck.map(\.stableID) == ["two"])
    }

    @Test
    func needsWorkScopeIncludesOnlyWeakLatestAssessments() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt),
            snapshot(id: "b", assessment: .hard),
            snapshot(id: "c", assessment: .again),
        ]

        let deck = ReviewDeckBuilder.build(
            questions: questions,
            attempts: attempts,
            scope: .needsWork
        )

        #expect(Set(deck.map(\.stableID)) == ["b", "c"])
    }

    @Test
    func needsWorkUsesLatestAssessmentOnly() {
        let questions = [makeQuestion(id: "a")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, at: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            snapshot(id: "a", assessment: .hard, at: Date()),
        ]

        let deck = ReviewDeckBuilder.build(
            questions: questions,
            attempts: attempts,
            scope: .needsWork
        )

        #expect(deck.map(\.stableID) == ["a"])
    }

    @Test
    func dueScopeIsUnionOfUnansweredAndNeedsWork() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt),
            snapshot(id: "b", assessment: .again),
        ]

        let due = ReviewDeckBuilder.build(questions: questions, attempts: attempts, scope: .due)
        let unanswered = ReviewDeckBuilder.build(questions: questions, attempts: attempts, scope: .unanswered)
        let needsWork = ReviewDeckBuilder.build(questions: questions, attempts: attempts, scope: .needsWork)

        #expect(Set(due.map(\.stableID)) == Set(unanswered.map(\.stableID)).union(Set(needsWork.map(\.stableID))))
        #expect(due.map(\.stableID) == ["b", "c"])
    }

    @Test
    func deckPreservesBankOrder() {
        let questions = [makeQuestion(id: "z"), makeQuestion(id: "y"), makeQuestion(id: "x")]
        let attempts = [snapshot(id: "y", assessment: .gotIt)]

        let deck = ReviewDeckBuilder.build(questions: questions, attempts: attempts, scope: .unanswered)

        #expect(deck.map(\.stableID) == ["z", "x"])
    }

    @Test
    func scopeCountsMatchDeckSize() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        let attempts = [snapshot(id: "a", assessment: .gotIt)]

        #expect(ReviewDeckBuilder.questionCount(questions: questions, attempts: attempts, scope: .due) == 2)
        #expect(ReviewDeckBuilder.questionCount(questions: questions, attempts: attempts, scope: .unanswered) == 2)
        #expect(ReviewDeckBuilder.questionCount(questions: questions, attempts: attempts, scope: .needsWork) == 0)
    }

    @Test
    func emptyQuestionsProduceEmptyDeck() {
        let deck = ReviewDeckBuilder.build(questions: [], attempts: [], scope: .due)
        #expect(deck.isEmpty)
    }

    @Test
    func sessionPersistsDeckOrderAndIndex() throws {
        let modelContainer = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let session = StudySession(
            mode: .targetedReview,
            testVersion: .twoThousandTwentyFive,
            deckStableIDs: ["a", "b", "c"]
        )
        session.attempts.append(QuestionAttempt(
            questionStableID: "a",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt
        ))
        session.applyProgress(answeredIDs: ["a", "b", "c"], currentIndex: 1)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StudySession>())
        #expect(fetched.first?.deckStableIDs == ["a", "b", "c"])
        #expect(fetched.first?.currentIndex == 1)
        #expect(fetched.first?.answeredCount == 1)
        #expect(fetched.first?.isComplete == false)
    }

    @Test
    func resumedStateRestoresPositionAndAttempts() throws {
        let modelContainer = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let session = StudySession(
            mode: .targetedReview,
            testVersion: .twoThousandTwentyFive,
            deckStableIDs: ["a", "b", "c"]
        )
        session.attempts.append(QuestionAttempt(
            questionStableID: "a",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt
        ))
        session.applyProgress(answeredIDs: ["a", "b", "c"], currentIndex: 1)
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StudySession>()).first!
        let state = StudyDomain.resumeFlashcardState(
            deckStableIDs: fetched.deckStableIDs,
            currentIndex: fetched.currentIndex,
            attempts: fetched.attempts.compactMap { $0.flashcardAttemptRecord },
            deckQuestions: [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        )

        #expect(state?.currentQuestion?.stableID == "b")
        #expect(state?.isRevealed == false)
        #expect(state?.answeredCount == 1)
        #expect(state?.progressText == "2 of 3")
        #expect(state?.attempts.first?.assessment == .gotIt)
    }

    @Test
    func resumedStateCompletesProgressively() throws {
        let modelContainer = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let session = StudySession(
            mode: .targetedReview,
            testVersion: .twoThousandTwentyFive,
            deckStableIDs: ["a", "b"]
        )
        session.attempts.append(QuestionAttempt(
            questionStableID: "a",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt
        ))
        session.applyProgress(answeredIDs: ["a", "b"], currentIndex: 1)
        context.insert(session)

        var state = StudyDomain.resumeFlashcardState(
            deckStableIDs: session.deckStableIDs,
            currentIndex: session.currentIndex,
            attempts: session.attempts.compactMap { $0.flashcardAttemptRecord },
            deckQuestions: [makeQuestion(id: "a"), makeQuestion(id: "b")]
        )!

        state.reveal()
        state.assess(.hard)
        #expect(state.isComplete)
        #expect(state.answeredCount == 2)
    }

    private func snapshot(
        id: String,
        assessment: SelfAssessment,
        at date: Date = Date()
    ) -> StudyAttemptSnapshot {
        StudyAttemptSnapshot(
            stableID: id,
            testVersion: .twoThousandTwentyFive,
            assessment: assessment,
            answeredAt: date
        )
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