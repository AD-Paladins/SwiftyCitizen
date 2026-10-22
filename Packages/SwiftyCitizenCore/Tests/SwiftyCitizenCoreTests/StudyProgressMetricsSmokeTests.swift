import Foundation
import Testing
@testable import SwiftyCitizenCore

final class StudyProgressMetricsSmokeTests {
    @Test func reviewedTodayCountsOnlyToday() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let today = StudyAttemptSnapshot(
            stableID: "q1",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt,
            answeredAt: now
        )
        let yesterday = StudyAttemptSnapshot(
            stableID: "q2",
            testVersion: .twoThousandTwentyFive,
            assessment: .gotIt,
            answeredAt: now.addingTimeInterval(-86_400)
        )
        #expect(StudyProgressMetrics.reviewedToday(attempts: [today, yesterday], now: now) == 1)
    }
}
