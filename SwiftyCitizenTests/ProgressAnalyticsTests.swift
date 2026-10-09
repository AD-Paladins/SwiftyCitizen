//
//  ProgressAnalyticsTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct ProgressAnalyticsTests {

    private let day: TimeInterval = 60 * 60 * 24
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: passRate

    @Test
    func passRateIsNilWhenBankIsEmpty() {
        #expect(ProgressAnalytics.passRate(attempts: [], for: config(bank: 0)) == nil)
    }

    @Test
    func passRateRisesWithMoreMasteredCards() {
        let cfg = config(bank: 4)

        // No mastery, no correctness → 0.
        let none = [snapshot(id: "a", assessment: .again, wasCorrect: false, boxLevel: 1, at: now)]
        #expect(ProgressAnalytics.passRate(attempts: none, for: cfg) == 0)

        // One graduated card (coverageMastered = 0.25) + 1 correct of 4 attempts (accuracy = 0.25).
        let some = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now),
            snapshot(id: "b", assessment: .again, wasCorrect: false, boxLevel: 1, at: now),
            snapshot(id: "c", assessment: .again, wasCorrect: false, boxLevel: 1, at: now),
            snapshot(id: "d", assessment: .again, wasCorrect: false, boxLevel: 1, at: now),
        ]
        // 0.6 * 0.25 + 0.4 * 0.25 = 0.25
        #expect(ProgressAnalytics.passRate(attempts: some, for: cfg) == 0.25)

        // Full mastery + full correctness → 1.
        let full = (0..<4).map { i in
            snapshot(id: String(i), assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now)
        }
        #expect(ProgressAnalytics.passRate(attempts: full, for: cfg) == 1)

        #expect(ProgressAnalytics.passRate(attempts: some, for: cfg)! > ProgressAnalytics.passRate(attempts: none, for: cfg)!)
    }

    @Test
    func passRateIsClampedToTheUnitInterval() {
        // Five graduated cards against a bank of two → coverageMastered = 2.5, would exceed 1.
        let cfg = config(bank: 2)
        let over = (0..<5).map { i in
            snapshot(id: String(i), assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now)
        }
        // 0.6 * 2.5 + 0.4 * 1.0 = 1.9 → clamped to 1.
        #expect(ProgressAnalytics.passRate(attempts: over, for: cfg) == 1)
    }

    // MARK: passRateWeeklyDelta

    @Test
    func passRateWeeklyDeltaIsNilWithFewerThanTwoWeeks() {
        let iso = Calendar(identifier: .iso8601)
        let weekStart = isoWeekStart(now, iso)
        // Only the current week has data.
        let oneWeek = [snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: weekStart + day)]

        #expect(ProgressAnalytics.passRateWeeklyDelta(attempts: oneWeek, for: config(), now: now, calendar: iso) == nil)
    }

    @Test
    func passRateWeeklyDeltaIsNotNilWithTwoWeeks() {
        let iso = Calendar(identifier: .iso8601)
        let weekStart = isoWeekStart(now, iso)
        let priorWeekStart = iso.date(byAdding: .day, value: -7, to: weekStart)!
        let twoWeeks = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: weekStart + day),
            snapshot(id: "b", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: priorWeekStart + day),
        ]

        let delta = ProgressAnalytics.passRateWeeklyDelta(attempts: twoWeeks, for: config(), now: now, calendar: iso)
        #expect(delta != nil)
        #expect(delta! >= -1 && delta! <= 1)
    }

    // MARK: buckets

    @Test
    func graduatedRequiresGotItAndBoxAtLeastFour() {
        let questions = [q(id: "a"), q(id: "b")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now - 20 * day), // graduated
            snapshot(id: "b", assessment: .gotIt, wasCorrect: true, boxLevel: 2, at: now - 20 * day), // gotIt but low box
        ]

        let buckets = ProgressAnalytics.buckets(attempts: attempts, for: config(bank: 2), questions: questions)
        #expect(buckets.graduated == 1)
    }

    @Test
    func inReviewIsDueMinusGraduated() {
        let questions = [q(id: "a"), q(id: "b")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now - 20 * day), // graduated + due
            snapshot(id: "b", assessment: .again, wasCorrect: false, boxLevel: 1, at: now - 20 * day),   // due (box 1 interval 0)
        ]

        let buckets = ProgressAnalytics.buckets(attempts: attempts, for: config(bank: 2), questions: questions)
        // due = {a, b} = 2; graduated = 1 → inReview = 1
        #expect(buckets.inReview == 1)
        #expect(buckets.graduated == 1)
    }

    @Test
    func needsCareIncludesUnseenAndLowAccuracy() {
        let questions = [q(id: "a"), q(id: "b"), q(id: "c"), q(id: "d")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now - 30 * day), // graduated — not needs-care
            snapshot(id: "b", assessment: nil, wasCorrect: nil, boxLevel: nil, at: now - day),          // unseen (boxLevel nil)
            snapshot(id: "c", assessment: .again, wasCorrect: false, boxLevel: 1, at: now - day),       // re-failed
            snapshot(id: "d", assessment: .hard, wasCorrect: false, boxLevel: 2, at: now - day),        // low accuracy (0/1)
        ]

        let buckets = ProgressAnalytics.buckets(attempts: attempts, for: config(bank: 4), questions: questions)
        #expect(buckets.graduated == 1)
        #expect(buckets.needsCare == 3)
    }

    // MARK: standardMet

    @Test
    func standardMetTrueWhenCoverageMeetsPassingFraction() {
        let cfg = config(bank: 4, passingScore: 6, maximumQuestionsAsked: 10) // passingPercentage = 0.6
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now),
            snapshot(id: "b", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now),
            snapshot(id: "c", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now),
        ]
        // 3 of 4 covered = 0.75 >= 0.6
        #expect(ProgressAnalytics.standardMet(attempts: attempts, for: cfg) == true)
    }

    @Test
    func standardMetFalseWhenCoverageBelowPassingFraction() {
        let cfg = config(bank: 4, passingScore: 6, maximumQuestionsAsked: 10) // passingPercentage = 0.6
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now),
            snapshot(id: "b", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now),
        ]
        // 2 of 4 covered = 0.5 < 0.6
        #expect(ProgressAnalytics.standardMet(attempts: attempts, for: cfg) == false)
    }

    // MARK: accuracyByDomain + weakSpots

    @Test
    func accuracyByDomainUsesWasCorrectAndGotIt() {
        let topicIndex = ["a": "Government", "b": "Government", "c": "History"]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now),       // correct
            snapshot(id: "a", assessment: .again, wasCorrect: false, boxLevel: 1, at: now - day), // wrong
            snapshot(id: "b", assessment: nil, wasCorrect: false, boxLevel: 1, at: now),          // wrong
            snapshot(id: "c", assessment: nil, wasCorrect: true, boxLevel: 2, at: now),           // correct (mock)
        ]

        let result = ProgressAnalytics.accuracyByDomain(attempts: attempts, topicIndex: topicIndex, for: .twoThousandTwentyFive)

        // First-appearance order: Government before History.
        #expect(result[0].topic == "Government")

        let government = result.first { $0.topic == "Government" }!
        #expect(government.count == 3)
        #expect(isClose(government.accuracy, 1.0 / 3.0))

        let history = result.first { $0.topic == "History" }!
        #expect(history.count == 1)
        #expect(history.accuracy == 1.0)
    }

    @Test
    func weakSpotsAreAscendingCappedAndTopicMapped() {
        let questions = [q(id: "a", topic: "Government"), q(id: "b", topic: "History"), q(id: "c", topic: "Government"), q(id: "d", topic: "History")]
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: now - day),   // 1/2 = 0.5
            snapshot(id: "a", assessment: .again, wasCorrect: false, boxLevel: 1, at: now),
            snapshot(id: "b", assessment: .again, wasCorrect: false, boxLevel: 1, at: now),        // 0/1 = 0.0 (weakest)
            snapshot(id: "c", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now - 2 * day), // 2/2 = 1.0
            snapshot(id: "c", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now),
            snapshot(id: "d", assessment: nil, wasCorrect: nil, boxLevel: nil, at: now),           // unanswered → excluded
        ]

        let capped = ProgressAnalytics.weakSpots(attempts: attempts, questions: questions, version: .twoThousandTwentyFive, limit: 2)
        #expect(capped.map(\.stableID) == ["b", "a"])
        #expect(capped[0].accuracy == 0.0)
        #expect(capped[1].accuracy == 0.5)

        // Topic is mapped from the question bank, not the attempt.
        let all = ProgressAnalytics.weakSpots(attempts: attempts, questions: questions, version: .twoThousandTwentyFive)
        let bSpot = all.first { $0.stableID == "b" }!
        #expect(bSpot.topic == "History")
    }

    // MARK: accuracyByWeek

    @Test
    func accuracyByWeekGroupsByISOWeek() {
        let iso = Calendar(identifier: .iso8601)
        let weekStart = isoWeekStart(now, iso)
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: weekStart + day),          // current week, correct
            snapshot(id: "b", assessment: .again, wasCorrect: false, boxLevel: 1, at: weekStart + 2 * day),     // current week, wrong
            snapshot(id: "c", assessment: .gotIt, wasCorrect: true, boxLevel: 3, at: (weekStart - 7 * day) + day), // prior week, correct
        ]

        let points = ProgressAnalytics.accuracyByWeek(attempts: attempts, weeks: 2, now: now, calendar: iso)
        #expect(points.count == 2)

        // Oldest first: prior week (1 attempt, 100%), then current week (2 attempts, 50%).
        #expect(points[0].weekStart == weekStart - 7 * day)
        #expect(points[0].attempts == 1)
        #expect(points[0].accuracy == 1.0)

        #expect(points[1].weekStart == weekStart)
        #expect(points[1].attempts == 2)
        #expect(points[1].accuracy == 0.5)
    }

    // MARK: retentionStability

    @Test
    func retentionStabilityCountsOnlyMasteredOldCards() {
        let iso = Calendar(identifier: .iso8601)
        // a: mastered + 10d ago (> 5d) → counts. b: mastered but 2d ago → no. c: not mastered → no.
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 5, at: now - 10 * day),
            snapshot(id: "b", assessment: .gotIt, wasCorrect: true, boxLevel: 5, at: now - 2 * day),
            snapshot(id: "c", assessment: .again, wasCorrect: false, boxLevel: 1, at: now - 10 * day),
        ]

        let retention = ProgressAnalytics.retentionStability(attempts: attempts, horizonDays: 5, now: now, calendar: iso)
        // 1 mastered-old / 3 attempted ≈ 0.333
        #expect(isClose(retention, 1.0 / 3.0))
    }

    @Test
    func retentionStabilityIsNilWithoutAttemptedCards() {
        #expect(ProgressAnalytics.retentionStability(attempts: []) == nil)
    }

    // MARK: recommendation

    @Test
    func recommendationIsNullHistoryGetsHonestCopy() {
        let copy = ProgressAnalytics.recommendation(attempts: [], for: config())
        #expect(!copy.isEmpty)
        #expect(copy.count <= 2 * 300) // short: well under two sentences of ASCII
    }

    @Test
    func recommendationIsTwoSentencesWhenSignalsPresent() {
        let attempts = [
            snapshot(id: "a", assessment: .gotIt, wasCorrect: true, boxLevel: 5, at: now - 10 * day),
            snapshot(id: "b", assessment: .gotIt, wasCorrect: true, boxLevel: 4, at: now - day),
        ]
        let copy = ProgressAnalytics.recommendation(attempts: attempts, for: config())
        // Retention sentence + trend sentence.
        #expect(copy.contains("Retention"))
    }

    // MARK: - Helpers

    // ISO-8601 week start (Monday); mirrors ProgressAnalytics.weekStart. Avoids Calendar's
    // `dateInterval(for:for:)` / `range(of:for:)` overload resolution in this SDK.
    private func isoWeekStart(_ date: Date, _ calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.dateComponents([.weekday], from: startOfDay).weekday ?? 2 // Sunday = 1 ... Monday = 2
        let daysSinceMonday = (weekday - 2 + 7) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: startOfDay)!
    }

    private func isClose(_ value: Double?, _ target: Double, accuracy eps: Double = 1e-9) -> Bool {
        guard let value else { return false }
        return abs(value - target) <= eps
    }

    private func config(
        bank: Int = 10,
        passingScore: Int = 6,
        maximumQuestionsAsked: Int = 10,
        version: USCISTestVersion = .twoThousandTwentyFive
    ) -> TestConfiguration {
        TestConfiguration(
            version: version,
            questionBankCount: bank,
            maximumQuestionsAsked: maximumQuestionsAsked,
            passingScore: passingScore,
            applicability: .filingBeforeOctober20th2025
        )
    }

    private func snapshot(
        id: String,
        assessment: SelfAssessment? = nil,
        wasCorrect: Bool? = nil,
        boxLevel: Int? = nil,
        at date: Date,
        version: USCISTestVersion = .twoThousandTwentyFive
    ) -> StudyAttemptSnapshot {
        StudyAttemptSnapshot(
            stableID: id,
            testVersion: version,
            assessment: assessment,
            wasCorrect: wasCorrect,
            answeredAt: date,
            boxLevel: boxLevel
        )
    }

    private func q(
        id: String,
        topic: String = "Government",
        version: USCISTestVersion = .twoThousandTwentyFive
    ) -> QuestionContent {
        QuestionContent(
            stableID: id,
            testVersion: version,
            officialQuestion: "What is the question?",
            acceptedAnswerVariants: ["An answer"],
            answerCardinality: .exactly(1),
            topic: topic,
            sourceURL: URL(string: "https://www.uscis.gov")!,
            sourceRevision: "2025-09-10",
            verificationDate: Date(timeIntervalSince1970: 0),
            isJurisdictionDependent: false,
            isSixtyFiveTwentyQuestion: false
        )
    }
}
