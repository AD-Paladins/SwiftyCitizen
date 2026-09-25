//
//  StudyLogicTests.swift
//  SwiftyCitizenTests
//
//  Created by andres paladines on 9/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import SwiftyCitizen

struct StudyLogicTests {

    @Test
    func flashcardStateProgressesThroughDeck() {
        var state = FlashcardState(questions: [makeQuestion(id: "one"), makeQuestion(id: "two")])

        #expect(state.currentQuestion?.stableID == "one")
        #expect(state.progressText == "1 of 2")
        #expect(state.isComplete == false)

        state.reveal()
        #expect(state.isRevealed)

        let first = state.assess(.gotIt)
        #expect(first?.stableID == "one")
        #expect(state.currentQuestion?.stableID == "two")
        #expect(state.isRevealed == false)
        #expect(state.answeredCount == 1)

        state.assess(.gotIt)
        #expect(state.isComplete)
        #expect(state.currentQuestion == nil)
        #expect(state.answeredCount == 2)
    }

    @Test
    func flashcardStateIgnoresAssessmentsOnEmptyOrCompleteDeck() {
        var empty = FlashcardState(questions: [])
        #expect(empty.assess(.hard) == nil)
        #expect(empty.isComplete)
        empty.reveal()
        #expect(empty.isRevealed == false)

        var single = FlashcardState(questions: [makeQuestion(id: "only")])
        #expect(single.assess(.hard)?.stableID == "only")
        #expect(single.isComplete)
        #expect(single.assess(.gotIt) == nil)
        single.reveal()
        #expect(single.isRevealed == false)
    }

    @Test
    func flashcardStateCapturesTypedAnswerOnAssess() {
        var state = FlashcardState(questions: [makeQuestion(id: "one")])

        state.recordAnswer("  The Constitution  ")
        state.reveal()
        #expect(state.currentAnswer == "The Constitution")

        let attempt = state.assess(.gotIt)
        #expect(attempt?.answerText == "The Constitution")
        #expect(state.currentAnswer == nil)
        #expect(state.isComplete)
    }

    @Test
    func flashcardStateTreatsBlankAnswerAsNone() {
        var state = FlashcardState(questions: [makeQuestion(id: "one")])
        state.recordAnswer("   \n ")
        #expect(state.currentAnswer == nil)

        let attempt = state.assess(.again)
        #expect(attempt?.answerText == nil)
    }

    @Test
    func flashcardStateAgainRePresentsWithoutAdvancing() {
        var state = FlashcardState(questions: [makeQuestion(id: "one"), makeQuestion(id: "two")])

        state.recordAnswer("The Constitution")
        state.reveal()
        #expect(state.isRevealed)

        let again = state.assess(.again)
        #expect(again == nil)
        #expect(state.currentQuestion?.stableID == "one")
        #expect(state.isRevealed == false)
        #expect(state.answeredCount == 0)

        state.recordAnswer("The Constitution")
        state.reveal()
        let gotIt = state.assess(.gotIt)
        #expect(gotIt?.stableID == "one")
        #expect(gotIt?.answerText == "The Constitution")
        #expect(state.currentQuestion?.stableID == "two")
        #expect(state.answeredCount == 1)
    }

    @Test
    func flashcardStateRecordsOnlyFinalConfirmation() {
        var state = FlashcardState(questions: [makeQuestion(id: "one")])

        state.recordAnswer("a")
        state.reveal()
        state.assess(.again)
        state.recordAnswer("b")
        state.reveal()
        state.assess(.hard)

        #expect(state.attempts.count == 1)
        #expect(state.attempts.first?.assessment == .hard)
        #expect(state.attempts.first?.answerText == "b")
    }

    @Test
    func studySessionRoundTripsThroughSwiftData() throws {
        let modelContainer = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let session = StudySession(mode: .flashcards, testVersion: .twoThousandTwentyFive)
        session.attempts.append(QuestionAttempt(
            questionStableID: "2025-001",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt
        ))
        session.attempts.append(QuestionAttempt(
            questionStableID: "2025-002",
            testVersion: .twoThousandTwentyFive,
            assessment: .again
        ))
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StudySession>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.mode == .flashcards)
        #expect(fetched.first?.testVersion == .twoThousandTwentyFive)
        #expect(fetched.first?.isComplete == false)
        #expect(fetched.first?.attempts.count == 2)

        let byID = Dictionary(
            uniqueKeysWithValues: (fetched.first?.attempts ?? []).map { ($0.questionStableID, $0) }
        )
        #expect(byID["2025-001"]?.assessment == .gotIt)
        #expect(byID["2025-002"]?.assessment == .again)
    }

    @Test
    func flashcardAnswerTextRoundTripsThroughSwiftData() throws {
        let modelContainer = try ModelContainer(
            for: StudySession.self, QuestionAttempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(modelContainer)

        let session = StudySession(mode: .flashcards, testVersion: .twoThousandTwentyFive)
        session.attempts.append(QuestionAttempt(
            questionStableID: "2025-001",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt,
            answerText: "The Constitution"
        ))
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StudySession>())
        let byID = Dictionary(
            uniqueKeysWithValues: (fetched.first?.attempts ?? []).map { ($0.questionStableID, $0) }
        )
        #expect(byID["2025-001"]?.answerText == "The Constitution")
        #expect(byID["2025-001"]?.flashcardAttemptRecord?.answerText == "The Constitution")
    }

    @Test
    func completedSessionIsMarked() {
        var session = StudySession(mode: .flashcards, testVersion: .twoThousandEight)
        session.endedAt = .now
        #expect(session.isComplete)
    }

    @Test
    func questionAttemptSnapshotPreservesAssessment() {
        let attempt = QuestionAttempt(
            questionStableID: "2008-001",
            testVersion: .twoThousandEight,
            assessment: .hard
        )

        let snapshot = attempt.snapshot
        #expect(snapshot?.stableID == "2008-001")
        #expect(snapshot?.testVersion == .twoThousandEight)
        #expect(snapshot?.assessment == .hard)
    }

    @Test
    func reviewedTodayCountsOnlyTodaysAttempts() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let attempts = [
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: today
            ),
            StudyAttemptSnapshot(
                stableID: "b",
                testVersion: .twoThousandTwentyFive,
                assessment: .again,
                answeredAt: yesterday
            ),
        ]

        let count = StudyProgressMetrics.reviewedToday(
            attempts: attempts,
            now: today,
            calendar: .current
        )
        #expect(count == 1)
    }

    @Test
    func gotItRateIsNilWithoutTodayActivity() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let rate = StudyProgressMetrics.gotItRate(
            attempts: [
                StudyAttemptSnapshot(
                    stableID: "a",
                    testVersion: .twoThousandTwentyFive,
                    assessment: .gotIt,
                    answeredAt: yesterday
                )
            ],
            now: Date(),
            calendar: .current
        )
        #expect(rate == nil)
    }

    @Test
    func gotItRateReflectsTodaysAssessments() {
        let now = Date()

        let rate = StudyProgressMetrics.gotItRate(
            attempts: [
                attempt(id: "a", assessment: .gotIt, at: now),
                attempt(id: "b", assessment: .gotIt, at: now),
                attempt(id: "c", assessment: .hard, at: now),
            ],
            now: now,
            calendar: .current
        )
        #expect(rate == 2.0 / 3.0)
    }

    @Test
    func coverageIsPerVersion() {
        let today = Date()
        let eight = StudyAttemptSnapshot(
            stableID: "2008-001",
            testVersion: .twoThousandEight,
            assessment: .gotIt,
            answeredAt: today
        )
        let twentyFive = StudyAttemptSnapshot(
            stableID: "2025-001",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt,
            answeredAt: today
        )

        let eightCoverage = StudyProgressMetrics.coverage(attempts: [eight, twentyFive], for: .twoThousandEight)
        let twentyFiveCoverage = StudyProgressMetrics.coverage(attempts: [eight, twentyFive], for: .twoThousandTwentyFive)

        #expect(eightCoverage == ["2008-001"])
        #expect(twentyFiveCoverage == ["2025-001"])
    }

    @Test
    func dueCountComputesRemainingQuestions() {
        let snapshots = [
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: Date()
            ),
            StudyAttemptSnapshot(
                stableID: "b",
                testVersion: .twoThousandTwentyFive,
                assessment: .hard,
                answeredAt: Date()
            ),
        ]

        let due = StudyProgressMetrics.dueCount(
            attempts: snapshots,
            configuration: .twoThousandTwentyFive
        )
        #expect(due == 126)
    }

    @Test
    func dueCountCountsUniqueQuestionsOnly() {
        let snapshots = [
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .again,
                answeredAt: Date()
            ),
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: Date()
            ),
        ]

        let due = StudyProgressMetrics.dueCount(
            attempts: snapshots,
            configuration: .twoThousandTwentyFive
        )
        #expect(due == 127)
    }

    @Test
    func readinessIsCoverageRatio() {
        let snapshots = [
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: Date()
            ),
            StudyAttemptSnapshot(
                stableID: "b",
                testVersion: .twoThousandTwentyFive,
                assessment: .hard,
                answeredAt: Date()
            ),
            StudyAttemptSnapshot(
                stableID: "c",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: Date()
            ),
        ]

        let readiness = StudyProgressMetrics.readinessPercentage(
            attempts: snapshots,
            configuration: .twoThousandTwentyFive
        )
        #expect(readiness != nil)
        #expect(abs(readiness!) - (3.0 / 128.0) < 1e-9)
    }

    @Test
    func masteryBreakdownUsesLatestAssessment() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        let snapshots = [
            // Latest is hard -> not mastered (due).
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: older
            ),
            StudyAttemptSnapshot(
                stableID: "a",
                testVersion: .twoThousandTwentyFive,
                assessment: .hard,
                answeredAt: newer
            ),
            // Latest is gotIt -> mastered.
            StudyAttemptSnapshot(
                stableID: "b",
                testVersion: .twoThousandTwentyFive,
                assessment: .hard,
                answeredAt: older
            ),
            StudyAttemptSnapshot(
                stableID: "b",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: newer
            ),
            // Mastered.
            StudyAttemptSnapshot(
                stableID: "c",
                testVersion: .twoThousandTwentyFive,
                assessment: .gotIt,
                answeredAt: older
            ),
        ]

        let breakdown = StudyProgressMetrics.masteryBreakdown(
            attempts: snapshots,
            configuration: .twoThousandTwentyFive
        )
        #expect(breakdown == MasteryBreakdown(mastered: 2, due: 1, unseen: 125))
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        return calendar
    }

    @Test
    func streakIsZeroWithoutActivity() {
        let streak = StudyProgressMetrics.streak(attempts: [])
        #expect(streak == 0)
    }

    @Test
    func streakCountsConsecutiveDaysIncludingToday() {
        let calendar = utcCalendar()
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 2_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let snapshots = [
            attempt(id: "a", assessment: .gotIt, at: today),
            attempt(id: "b", assessment: .hard, at: yesterday),
        ]

        let streak = StudyProgressMetrics.streak(attempts: snapshots, now: today, calendar: calendar)
        #expect(streak == 2)
    }

    @Test
    func streakContinuesWhenTodayNotYetStudied() {
        let reference = Date(timeIntervalSince1970: 2_000_000)
        let calendar = utcCalendar()
        let today = calendar.startOfDay(for: reference)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dayBefore = calendar.date(byAdding: .day, value: -2, to: today)!

        let snapshots = [
            attempt(id: "a", assessment: .gotIt, at: yesterday),
            attempt(id: "b", assessment: .gotIt, at: dayBefore),
        ]

        // Today not studied yet, but yesterday's run is still alive.
        let streak = StudyProgressMetrics.streak(attempts: snapshots, now: today, calendar: calendar)
        #expect(streak == 2)
    }

    @Test
    func streakBreaksOnGapFromToday() {
        let calendar = utcCalendar()
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 2_000_000))
        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)!

        let snapshots = [
            attempt(id: "a", assessment: .gotIt, at: dayBeforeYesterday),
        ]

        // Gap yesterday -> streak reset.
        let streak = StudyProgressMetrics.streak(attempts: snapshots, now: today, calendar: calendar)
        #expect(streak == 0)
    }

    @Test
    func selfAssessmentCasesHaveExpectedPresentation() {
        #expect(SelfAssessment.allCases.map(\.displayName) == ["Again", "Hard", "Got it"])
        #expect(SelfAssessment.allCases.map(\.systemImage) == [
            "arrow.counterclockwise",
            "graduationcap",
            "checkmark",
        ])
        #expect(StudyMode.allCases.map(\.displayName) == ["Flashcards", "Targeted review", "Mock test"])
    }

    private func attempt(
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