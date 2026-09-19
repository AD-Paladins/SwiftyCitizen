import Foundation

struct StudyAttemptSnapshot: Equatable {
    let stableID: String
    let testVersion: USCISTestVersion
    let assessment: SelfAssessment?
    let answeredAt: Date
}

enum StudyProgressMetrics {
    static func reviewedToday(
        attempts: [StudyAttemptSnapshot],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        attempts.filter { calendar.isDate($0.answeredAt, inSameDayAs: now) }.count
    }

    static func coverage(
        attempts: [StudyAttemptSnapshot],
        for version: USCISTestVersion
    ) -> Set<String> {
        Set(attempts.filter { $0.testVersion == version }.map(\.stableID))
    }

    static func dueCount(
        attempts: [StudyAttemptSnapshot],
        configuration: TestConfiguration
    ) -> Int {
        let covered = coverage(attempts: attempts, for: configuration.version).count
        return max(0, configuration.questionBankCount - covered)
    }

    static func gotItRate(
        attempts: [StudyAttemptSnapshot],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double? {
        let today = attempts.filter { calendar.isDate($0.answeredAt, inSameDayAs: now) }
        let selfAssessed = today.filter { $0.assessment != nil }
        guard selfAssessed.count > 0 else { return nil }
        let gotIt = selfAssessed.filter { $0.assessment == .gotIt }.count
        return Double(gotIt) / Double(selfAssessed.count)
    }
}

extension QuestionAttempt {
    var snapshot: StudyAttemptSnapshot? {
        guard let version = USCISTestVersion(rawValue: testVersionRawValue) else { return nil }
        return StudyAttemptSnapshot(
            stableID: questionStableID,
            testVersion: version,
            assessment: assessment,
            answeredAt: answeredAt
        )
    }
}