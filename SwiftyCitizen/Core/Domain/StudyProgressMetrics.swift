import Foundation

struct StudyAttemptSnapshot: Equatable {
    let stableID: String
    let testVersion: USCISTestVersion
    let assessment: SelfAssessment?
    let answeredAt: Date
}

struct MasteryBreakdown: Equatable {
    let mastered: Int
    let due: Int
    let unseen: Int
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

    static func coveredCount(
        attempts: [StudyAttemptSnapshot],
        configuration: TestConfiguration
    ) -> Int {
        coverage(attempts: attempts, for: configuration.version).count
    }

    static func readinessPercentage(
        attempts: [StudyAttemptSnapshot],
        configuration: TestConfiguration
    ) -> Double? {
       let bank = configuration.questionBankCount
        guard bank > 0 else { return nil }
        return Double(coveredCount(attempts: attempts, configuration: configuration)) / Double(bank)
    }

    static func masteryBreakdown(
        attempts: [StudyAttemptSnapshot],
        configuration: TestConfiguration
    ) -> MasteryBreakdown {
        let versionAttempts = attempts.filter { $0.testVersion == configuration.version }
        let answeredIDs = Set(versionAttempts.map(\.stableID))
        let unseen = max(0, configuration.questionBankCount - answeredIDs.count)

        var mastered = 0
        for stableID in answeredIDs {
            let latest = versionAttempts
                .filter { $0.stableID == stableID }
                .max { $0.answeredAt < $1.answeredAt }
            if latest?.assessment == .gotIt {
                mastered += 1
            }
        }
        let due = answeredIDs.count - mastered
        return MasteryBreakdown(mastered: mastered, due: due, unseen: unseen)
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

    static func streak(
        attempts: [StudyAttemptSnapshot],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let activeDays = Set(attempts.map { calendar.startOfDay(for: $0.answeredAt) })
        guard !activeDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard (activeDays.contains(today) || activeDays.contains(yesterday)) else { return 0 }
        let start = activeDays.contains(today) ? today : yesterday

        var streak = 1
        var day = start
        while let previous = calendar.date(byAdding: .day, value: -1, to: day),
              activeDays.contains(previous) {
            streak += 1
            day = previous
        }
        return streak
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