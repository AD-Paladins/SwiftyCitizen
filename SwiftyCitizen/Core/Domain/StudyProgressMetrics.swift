import Foundation

struct StudyAttemptSnapshot: Equatable {
    let stableID: String
    let testVersion: USCISTestVersion
    let assessment: SelfAssessment?
    let wasCorrect: Bool?
    let answeredAt: Date
    /// Leitner box this result left the card in (1...`LeitnerScheduler.maxBox`). nil when the
    /// card has no self-assessment history (unanswered). Kept optional so callers that build a
    /// snapshot without box context still compile.
    let boxLevel: Int?

    /// Backward-compatible initializer for study attempts (correctness lives in `assessment`).
    init(
        stableID: String,
        testVersion: USCISTestVersion,
        assessment: SelfAssessment?,
        answeredAt: Date,
        boxLevel: Int? = nil
    ) {
        self.stableID = stableID
        self.testVersion = testVersion
        self.assessment = assessment
        self.wasCorrect = nil
        self.answeredAt = answeredAt
        self.boxLevel = boxLevel
    }

    /// Full initializer carrying the mock-test correctness flag.
    init(
        stableID: String,
        testVersion: USCISTestVersion,
        assessment: SelfAssessment?,
        wasCorrect: Bool?,
        answeredAt: Date,
        boxLevel: Int? = nil
    ) {
        self.stableID = stableID
        self.testVersion = testVersion
        self.assessment = assessment
        self.wasCorrect = wasCorrect
        self.answeredAt = answeredAt
        self.boxLevel = boxLevel
    }
}

struct MasteryBreakdown: Equatable {
    let mastered: Int
    let due: Int
    let unseen: Int
}

/// Per-topic coverage for a single test version. `accuracy` is nil when the topic has no
/// attempts; otherwise it is the fraction of correct attempts over all attempts on the topic.
struct TopicCoverage: Equatable {
    let topic: String
    let mastered: Int
    let due: Int
    let unseen: Int
    let accuracy: Double?
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

    /// Whether an attempt counts as correct. Study attempts resolve through self-assessment;
    /// mock-test attempts through the persisted answer flag. An attempt is correct when either
    /// holds.
    static func isCorrect(_ attempt: StudyAttemptSnapshot) -> Bool {
        attempt.assessment == .gotIt || attempt.wasCorrect == true
    }

    /// Per-topic coverage + accuracy for a single test version.
    ///
    /// `topicIndex` maps every stableID of the *version* to its topic and is resolved once by
    /// the content layer; keeping it as an injected parameter keeps this function pure,
    /// SwiftData-free, and unit-testable (no bank loading in the domain layer). Topics are
    /// emitted in first-appearance order so callers get deterministic output.
    static func coverageByTopic(
        attempts: [StudyAttemptSnapshot],
        for version: USCISTestVersion,
        topicIndex: [String: String]
    ) -> [TopicCoverage] {
        // Total question count per topic comes from the content-layer index. Iterating in
        // first-appearance order keeps the output ordering deterministic below.
        var totalByTopic: [String: Int] = [:]
        for topic in topicIndex.values {
            totalByTopic[topic, default: 0] += 1
        }

        let versionAttempts = attempts.filter { $0.testVersion == version }
        let mapped = versionAttempts.compactMap { attempt -> (StudyAttemptSnapshot, String)? in
            guard let topic = topicIndex[attempt.stableID] else { return nil }
            return (attempt, topic)
        }
        let grouped = Dictionary(grouping: mapped, by: { $0.1 })

        return totalByTopic.keys.map { topic in
            let attemptsInTopic = grouped[topic] ?? []
            let attemptedIDs = Set(attemptsInTopic.map(\.0.stableID))
            let unseen = max(0, (totalByTopic[topic] ?? 0) - attemptedIDs.count)

            let correctAttempts = attemptsInTopic.filter { isCorrect($0.0) }.count
            let accuracy = attemptsInTopic.isEmpty ? nil : Double(correctAttempts) / Double(attemptsInTopic.count)

            var mastered = 0
            for stableID in attemptedIDs {
                let latest = attemptsInTopic
                    .filter { $0.0.stableID == stableID }
                    .max { $0.0.answeredAt < $1.0.answeredAt }
                if let latest, isCorrect(latest.0) { mastered += 1 }
            }
            let due = attemptedIDs.count - mastered

            return TopicCoverage(
                topic: topic,
                mastered: mastered,
                due: due,
                unseen: unseen,
                accuracy: accuracy
            )
        }
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
            wasCorrect: wasCorrect,
            answeredAt: answeredAt,
            boxLevel: boxLevel
        )
    }
}