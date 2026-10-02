//
//  LeitnerSchedulerTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

struct LeitnerSchedulerTests {

    private let day: TimeInterval = 60 * 60 * 24
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    // --- Interval table -------------------------------------------------

    @Test func intervalsFollowTheBoxTable() {
        #expect(LeitnerScheduler.interval(forBox: 1) == 0.0)
        #expect(LeitnerScheduler.interval(forBox: 2) == day)
        #expect(LeitnerScheduler.interval(forBox: 3) == 3 * day)
        #expect(LeitnerScheduler.interval(forBox: 4) == 7 * day)
        #expect(LeitnerScheduler.interval(forBox: 5) == 14 * day)
    }

    @Test func outOfRangeBoxesFallBackToImmediate() {
        #expect(LeitnerScheduler.interval(forBox: 0) == 0.0)
        #expect(LeitnerScheduler.interval(forBox: 6) == 0.0)
    }

    // --- Box transitions ------------------------------------------------

    @Test func againResetsToBoxOne() {
        #expect(LeitnerScheduler.nextBox(after: .again, currentBox: 5) == 1)
        #expect(LeitnerScheduler.nextBox(after: .again, currentBox: 1) == 1)
    }

    @Test func hardDropsOneBoxButNotBelowOne() {
        #expect(LeitnerScheduler.nextBox(after: .hard, currentBox: 4) == 3)
        #expect(LeitnerScheduler.nextBox(after: .hard, currentBox: 2) == 1)
        #expect(LeitnerScheduler.nextBox(after: .hard, currentBox: 1) == 1)
    }

    @Test func masteredAdvancesOneBoxButNotAboveMax() {
        #expect(LeitnerScheduler.nextBox(after: .gotIt, currentBox: 1) == 2)
        #expect(LeitnerScheduler.nextBox(after: .gotIt, currentBox: 4) == 5)
        #expect(LeitnerScheduler.nextBox(after: .gotIt, currentBox: 5) == 5)
    }

    // --- Outcome / due dates -------------------------------------------

    @Test func againDueDateIsImmediate() {
        let outcome = LeitnerScheduler.outcome(after: .again, currentBox: 3, from: base)
        #expect(outcome.box == 1)
        #expect(outcome.interval == 0.0)
        #expect(outcome.dueDate == base)
    }

    @Test func masteredDueDateAdvancesByTheResultingBoxInterval() {
        let outcome = LeitnerScheduler.outcome(after: .gotIt, currentBox: 2, from: base)
        // box 2 -> 3 -> 3-day interval
        #expect(outcome.box == 3)
        #expect(outcome.interval == 3 * day)
        #expect(outcome.dueDate == base + 3 * day)
    }

    @Test func hardDueDateDropsByOneBoxInterval() {
        let outcome = LeitnerScheduler.outcome(after: .hard, currentBox: 4, from: base)
        // box 4 -> 3 -> 3-day interval
        #expect(outcome.box == 3)
        #expect(outcome.dueDate == base + 3 * day)
    }

    @Test func cardAtMasteredBoxStaysDueInTwoWeeks() {
        let outcome = LeitnerScheduler.outcome(after: .gotIt, currentBox: 5, from: base)
        #expect(outcome.box == 5)
        #expect(outcome.dueDate == base + 14 * day)
    }

    // --- isDue ----------------------------------------------------------

    @Test func isDueReflectsPastAndFutureDates() {
        #expect(LeitnerScheduler.isDue(dueDate: base - 1, now: base))
        #expect(!LeitnerScheduler.isDue(dueDate: base + 1, now: base))
        #expect(LeitnerScheduler.isDue(dueDate: base, now: base))
    }
}
