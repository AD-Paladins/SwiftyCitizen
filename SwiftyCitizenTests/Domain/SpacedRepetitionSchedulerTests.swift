//
//  SpacedRepetitionSchedulerTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct SpacedRepetitionSchedulerTests {

    private let day: TimeInterval = 60 * 60 * 24
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // --- box2 / 2 days ago → due -------------------------------------------------

    @Test
    func boxTwoCardAnsweredTwoDaysAgoIsDue() {
        // One gotIt → box 2 (1-day interval); answered 2 days ago → interval elapsed.
        let questions = [makeQuestion(id: "a")]
        let attempts = [snapshot(id: "a", assessment: .gotIt, at: now - 2 * day)]

        let deck = SpacedRepetitionScheduler.dueCards(
            questions: questions,
            attempts: attempts,
            version: .twoThousandTwentyFive,
            now: now
        )

        #expect(deck.map(\.stableID) == ["a"])
    }

    // --- box3 / 1 day ago → NOT due --------------------------------------------

    @Test
    func boxThreeCardAnsweredOneDayAgoIsNotYetDue() {
        // Two gotIt reach box 3 (3-day interval); latest was 1 day ago → not elapsed.
        let questions = [makeQuestion(id: "a")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, at: now - 4 * day),
            snapshot(id: "a", assessment: .gotIt, at: now - 1 * day),
        ]

        let deck = SpacedRepetitionScheduler.dueCards(
            questions: questions,
            attempts: attempts,
            version: .twoThousandTwentyFive,
            now: now
        )

        #expect(deck.isEmpty)
    }

    // --- ordering: unseen first -------------------------------------------------

    @Test
    func unseenCardsSurfaceBeforeDueCards() {
        let questions = [makeQuestion(id: "new"), makeQuestion(id: "due")]
        let attempts = [snapshot(id: "due", assessment: .again, at: now)] // box 1 → due now

        let deck = SpacedRepetitionScheduler.dueCards(
            questions: questions,
            attempts: attempts,
            version: .twoThousandTwentyFive,
            now: now
        )

        #expect(deck.map(\.stableID) == ["new", "due"])
    }

    // --- ordering: most-overdue first ------------------------------------------

    @Test
    func mostOverdueCardSurfacesFirst() {
        // a: box 2, answered 5 days ago → dueDate = now - 4d. b: box 2, answered 2 days ago → dueDate = now - 1d.
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, at: now - 5 * day),
            snapshot(id: "b", assessment: .gotIt, at: now - 2 * day),
        ]

        let deck = SpacedRepetitionScheduler.dueCards(
            questions: questions,
            attempts: attempts,
            version: .twoThousandTwentyFive,
            now: now
        )

        #expect(deck.map(\.stableID) == ["a", "b"])
    }

    // --- version scoping --------------------------------------------------------

    @Test
    func dueCardsAreScopedToTheVersion() {
        let questions = [makeQuestion(id: "a")]
        let attempts = [
            snapshot(id: "a", assessment: .again, at: now - 2 * day, version: .twoThousandEight)
        ]

        // No attempts for the requested version → unseen.
        let deck = SpacedRepetitionScheduler.dueCards(
            questions: questions,
            attempts: attempts,
            version: .twoThousandTwentyFive,
            now: now
        )

        #expect(deck.map(\.stableID) == ["a"])
    }

    // --- helpers ----------------------------------------------------------------

    private func snapshot(
        id: String,
        assessment: SelfAssessment,
        at date: Date,
        version: USCISTestVersion = .twoThousandTwentyFive
    ) -> StudyAttemptSnapshot {
        StudyAttemptSnapshot(
            stableID: id,
            testVersion: version,
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
