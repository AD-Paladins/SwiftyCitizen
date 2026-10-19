import Testing
import Foundation
@testable import SwiftyCitizen

struct StudyProgressMetricsTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    /// Fixed UTC Gregorian calendar so "same day" boundaries are deterministic across machines.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func snapshot(_ stableID: String, at date: Date) -> StudyAttemptSnapshot {
        StudyAttemptSnapshot(
            stableID: stableID,
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt,
            answeredAt: date
        )
    }

    @Test
    func distinctReviewedTodayCountsSameIDOnce() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let attempts = [
            snapshot("a", at: now),
            snapshot("a", at: yesterday), // different day — excluded entirely
            snapshot("a", at: now)        // same ID, same day — deduped
        ]
        #expect(StudyProgressMetrics.distinctReviewedToday(attempts: attempts, now: now, calendar: calendar) == 1)
    }

    @Test
    func distinctReviewedTodayCountsDistinctIDs() {
        let attempts = [
            snapshot("a", at: now),
            snapshot("b", at: now),
            snapshot("c", at: now),
            snapshot("b", at: now) // duplicate — deduped
        ]
        #expect(StudyProgressMetrics.distinctReviewedToday(attempts: attempts, now: now, calendar: calendar) == 3)
    }

    @Test
    func distinctReviewedTodayExcludesOtherDays() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let attempts = [
            snapshot("a", at: yesterday),
            snapshot("b", at: tomorrow),
            snapshot("c", at: now)
        ]
        #expect(StudyProgressMetrics.distinctReviewedToday(attempts: attempts, now: now, calendar: calendar) == 1)
    }

    @Test
    func distinctReviewedTodayEmptyIsZero() {
        #expect(StudyProgressMetrics.distinctReviewedToday(attempts: [], now: now, calendar: calendar) == 0)
    }
}
