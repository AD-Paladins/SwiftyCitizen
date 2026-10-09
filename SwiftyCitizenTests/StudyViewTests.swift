//
//  StudyViewTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 10/8/26.
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct StudyViewTests {

    /// The Study tab's due count is the scheduler `.due` output: unseen cards first, then the
    /// most-overdue. It must equal a direct `ReviewDeckBuilder.questionCount(.due)` call and match
    /// the expected number for these attempts.
    @Test func dueCountMatchesSchedulerDueOutput() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        // a=.gotIt left the card in box 2 (not yet due); b and c are unseen → due.
        let attempts = [
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: Date(),
                boxLevel: 2
            )
        ]

        let viewDue = StudyView.dueCount(questions: questions, attempts: attempts, bookmarkedIDs: [])
        let builderDue = ReviewDeckBuilder.questionCount(
            questions: questions,
            attempts: attempts,
            scope: .due,
            categories: [],
            bookmarkedIDs: []
        )

        #expect(viewDue == 2)
        #expect(viewDue == builderDue)
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
