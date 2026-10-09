import Foundation

/// Pure analytics for the Progress tab "Diagnostic Mirror".
///
/// Operates on `[StudyAttemptSnapshot]`, `TestConfiguration`, and plain inputs. No SwiftUI, no
/// SwiftData, no bank loading — this mirrors the existing `StudyProgressMetrics` pattern so every
/// function stays unit-testable in isolation. All time-dependent functions are deterministic via
/// `now` / `calendar` parameters.
///
/// The "Predicted Pass Rate" is explicitly a study-aid heuristic (never an official passing score)
/// — see `passRate`.
enum ProgressAnalytics {

    /// Three-head mastery row for the Diagnostic Mirror: Graduated / In Review / Needs Care.
    struct Buckets: Equatable {
        let graduated: Int
        let inReview: Int
        let needsCare: Int
    }

    /// A single point on the weekly accuracy trajectory chart.
    struct WeekPoint: Equatable {
        let weekStart: Date
        let accuracy: Double?
        let attempts: Int
    }

    /// One weak card to drill, mapped to its topic.
    struct WeakSpot: Equatable {
        let stableID: String
        let topic: String
        let accuracy: Double?
        let lastAssessment: SelfAssessment?
    }

    /// Cards whose latest assessment is `.gotIt` **and** `boxLevel >= 4` — multi-interval mastery,
    /// i.e. ready for oral-exam pace (the design's definition of "graduated").
    static func graduatedCount(
        attempts: [StudyAttemptSnapshot],
        for version: USCISTestVersion
    ) -> Int {
        let versionAttempts = attempts.filter { $0.testVersion == version }
        var graduated = Set<String>()
        for stableID in Set(versionAttempts.map(\.stableID)) {
            guard let latest = latestAttempt(versionAttempts, for: stableID) else { continue }
            if latest.assessment == .gotIt, (latest.boxLevel ?? 0) >= 4 {
                graduated.insert(stableID)
            }
        }
        return graduated.count
    }

    /// Predicted pass rate (`0...1`) — a documented heuristic over coverage + overall accuracy.
    ///
    /// `passRate = 0.6 * coverageMastered + 0.4 * overallAccuracy`, where `coverageMastered` is the
    /// fraction of the bank that has reached graduated mastery and `overallAccuracy` is the fraction
    /// of correct attempts across the version. Bounded to `0...1`. Labeled "predicted" — never an
    /// official passing score. Returns nil only when the bank count is 0.
    static func passRate(
        attempts: [StudyAttemptSnapshot],
        for configuration: TestConfiguration,
        now: Date = .now
    ) -> Double? {
        let bank = configuration.questionBankCount
        guard bank > 0 else { return nil }

        let versionAttempts = attempts.filter { $0.testVersion == configuration.version }
        let graduated = graduatedCount(attempts: versionAttempts, for: configuration.version)
        let coverageMastered = Double(graduated) / Double(bank)

        let correct = versionAttempts.filter { StudyProgressMetrics.isCorrect($0) }.count
        let overallAccuracy = versionAttempts.isEmpty ? 0 : Double(correct) / Double(versionAttempts.count)

        return clamp(0.6 * coverageMastered + 0.4 * overallAccuracy)
    }

    /// Change in predicted pass rate between the previous ISO week and the current one (`now`'s
    /// week). Returns nil when attempts do not span both weeks (can't form a delta).
    static func passRateWeeklyDelta(
        attempts: [StudyAttemptSnapshot],
        for configuration: TestConfiguration,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double? {
        let iso = isoCalendar()
        let currentStart = weekStart(for: now)
        let priorStart = iso.date(byAdding: .day, value: -7, to: currentStart)!
        let currentEnd = iso.date(byAdding: .day, value: 7, to: currentStart)!

        let thisWeekAttempts = attempts.filter { $0.answeredAt >= currentStart && $0.answeredAt < currentEnd }
        let priorWeekAttempts = attempts.filter { $0.answeredAt >= priorStart && $0.answeredAt < currentStart }
        guard !thisWeekAttempts.isEmpty, !priorWeekAttempts.isEmpty else { return nil }

        let thisWeek = passRate(attempts: thisWeekAttempts, for: configuration, now: now)
        let priorWeek = passRate(attempts: priorWeekAttempts, for: configuration, now: now)
        guard let thisWeek, let priorWeek else { return nil }
        return clamp(thisWeek - priorWeek)
    }

    /// Mastery buckets for the three-head row.
    ///
    /// - `graduated`: distinct cards whose latest assessment is `.gotIt` and `boxLevel >= 4`.
    /// - `inReview`: scheduler-due distinct cards that are NOT graduated (`due − graduated`, min 0).
    /// - `needsCare`: unseen cards (`boxLevel == nil`) plus attempted cards whose latest state is
    ///   `.again` or low accuracy.
    ///
    /// The scheduler needs the question bank to compute due cards, so `questions` is optional and
    /// defaults to `[]`. Without it, `inReview` cannot run the scheduler and defaults to 0; pass the
    /// version's bank in to get the scheduler-based count.
    static func buckets(
        attempts: [StudyAttemptSnapshot],
        for configuration: TestConfiguration,
        questions: [QuestionContent] = []
    ) -> Buckets {
        let versionAttempts = attempts.filter { $0.testVersion == configuration.version }
        let graduated = graduatedCount(attempts: versionAttempts, for: configuration.version)

        let dueCount = questions.isEmpty
            ? 0
            : Set(SpacedRepetitionScheduler.dueCards(
                questions: questions,
                attempts: versionAttempts,
                version: configuration.version
            ).map(\.stableID)).count
        let inReview = max(0, dueCount - graduated)

        return Buckets(
            graduated: graduated,
            inReview: inReview,
            needsCare: needsCareCount(versionAttempts: versionAttempts)
        )
    }

    /// Whether coverage meets the version's passing fraction. True only when the bank is non-empty
    /// and `readinessPercentage` (covered / bank) is at or above `TestConfiguration.passingPercentage`.
    static func standardMet(
        attempts: [StudyAttemptSnapshot],
        for configuration: TestConfiguration
    ) -> Bool {
        guard configuration.questionBankCount > 0,
              let readiness = StudyProgressMetrics.readinessPercentage(attempts: attempts, configuration: configuration),
              let passing = configuration.passingPercentage else {
            return false
        }
        return readiness >= passing
    }

    /// Per-topic accuracy for a single version, in first-appearance order.
    ///
    /// Every topic present in `topicIndex` is emitted (matching `coverageByTopic`); topics with no
    /// attempts report `accuracy == nil` and `count == 0`. Accuracy is correct / total per topic.
    static func accuracyByDomain(
        attempts: [StudyAttemptSnapshot],
        topicIndex: [String: String],
        for version: USCISTestVersion
    ) -> [(topic: String, accuracy: Double?, count: Int)] {
        let versionAttempts = attempts.filter { $0.testVersion == version }

        // Unique topics in first-appearance order (a topic can map from several stableIDs).
        var order: [String] = []
        var seen = Set<String>()
        for topic in topicIndex.values where seen.insert(topic).inserted {
            order.append(topic)
        }

        return order.map { topic in
            let attemptsInTopic = versionAttempts.filter { topicIndex[$0.stableID] == topic }
            let correct = attemptsInTopic.filter { StudyProgressMetrics.isCorrect($0) }.count
            let accuracy = attemptsInTopic.isEmpty ? nil : Double(correct) / Double(attemptsInTopic.count)
            return (topic, accuracy, attemptsInTopic.count)
        }
    }

    /// The lowest-accuracy attempted cards for a version, mapped to their topic.
    ///
    /// Per-card accuracy is correct / last-N (default 5). Cards with no determinate correctness
    /// signal (unanswered) are excluded; the rest sort ascending by accuracy and take up to `limit`.
    static func weakSpots(
        attempts: [StudyAttemptSnapshot],
        questions: [QuestionContent],
        version: USCISTestVersion,
        limit: Int = 8
    ) -> [WeakSpot] {
        let versionAttempts = attempts.filter { $0.testVersion == version }
        let topicByID = Dictionary(questions.map { ($0.stableID, $0.topic) }, uniquingKeysWith: { first, _ in first })

        var spots: [WeakSpot] = []
        for (stableID, cardAttempts) in Dictionary(grouping: versionAttempts, by: \.stableID) {
            guard let accuracy = perCardAccuracy(cardAttempts, lastN: 5) else { continue }
            let latest = cardAttempts.max { $0.answeredAt < $1.answeredAt }
            spots.append(
                WeakSpot(
                    stableID: stableID,
                    topic: topicByID[stableID] ?? "",
                    accuracy: accuracy,
                    lastAssessment: latest?.assessment
                )
            )
        }

        spots.sort { left, right in
            if let a = left.accuracy, let b = right.accuracy {
                return a != b ? a < b : left.stableID < right.stableID
            }
            return left.stableID < right.stableID
        }
        return Array(spots.prefix(limit))
    }

    /// Weekly accuracy over the last `weeks` ISO weeks (oldest first). Accuracy is correct / total
    /// per week and nil when the week has no attempts.
    static func accuracyByWeek(
        attempts: [StudyAttemptSnapshot],
        weeks: Int = 4,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [WeekPoint] {
        let iso = isoCalendar()
        let isoStart = weekStart(for: now)

        var points: [WeekPoint] = []
        for offset in (0..<weeks).reversed() {
            let weekStart = iso.date(byAdding: .day, value: -7 * offset, to: isoStart)!
            let weekEnd = iso.date(byAdding: .day, value: 7, to: weekStart)!
            let inWeek = attempts.filter { $0.answeredAt >= weekStart && $0.answeredAt < weekEnd }
            let correct = inWeek.filter { StudyProgressMetrics.isCorrect($0) }.count
            let accuracy = inWeek.isEmpty ? nil : Double(correct) / Double(inWeek.count)
            points.append(WeekPoint(weekStart: weekStart, accuracy: accuracy, attempts: inWeek.count))
        }
        return points
    }

    /// Fraction of distinct attempted cards that are mastered (latest `.gotIt`) **and** whose latest
    /// attempt is more than `horizonDays` before `now`. nil when there are no attempted cards.
    static func retentionStability(
        attempts: [StudyAttemptSnapshot],
        horizonDays: Int = 5,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double? {
        let cutoff = calendar.date(byAdding: .day, value: -horizonDays, to: now)!
        let versionAttempts = attempts
        var attemptedIDs = Set<String>()
        var masteredOld = 0

        for stableID in Set(versionAttempts.map(\.stableID)) {
            guard let latest = latestAttempt(versionAttempts, for: stableID) else { continue }
            attemptedIDs.insert(stableID)
            if latest.assessment == .gotIt, latest.answeredAt < cutoff {
                masteredOld += 1
            }
        }
        guard !attemptedIDs.isEmpty else { return nil }
        return Double(masteredOld) / Double(attemptedIDs.count)
    }

    /// Short (<=2 sentence) conditional heuristic over retention, weekly trend, and pass rate.
    static func recommendation(
        attempts: [StudyAttemptSnapshot],
        for configuration: TestConfiguration
    ) -> String {
        let pass = passRate(attempts: attempts, for: configuration)
        let retention = retentionStability(attempts: attempts)
        let trend = passRateWeeklyDelta(attempts: attempts, for: configuration)

        if pass == nil {
            return "Keep answering questions to build a predicted pass rate — not enough history yet."
        }

        var sentences: [String] = []
        if let retention {
            sentences.append(
                retention >= 0.5
                    ? "Retention is steady, so your learned cards are sticking."
                    : "Retention is thin, so review older cards before they fade."
            )
        }
        if let trend {
            sentences.append(
                trend > 0
                    ? "Your predicted pass rate is climbing week over week."
                    : trend < 0
                        ? "Your predicted pass rate dipped last week — focus on the cards due today."
                        : "Your predicted pass rate is flat — a targeted drill will move it."
            )
        }
        if sentences.isEmpty {
            return "Predicted pass rate is in — keep practicing to push it higher."
        }
        return sentences.joined(separator: " ")
    }

    // MARK: - Helpers

    /// Latest attempt for a card (max `answeredAt`), or nil when the card has none.
    private static func latestAttempt(
        _ attempts: [StudyAttemptSnapshot],
        for stableID: String
    ) -> StudyAttemptSnapshot? {
        attempts.filter { $0.stableID == stableID }.max { $0.answeredAt < $1.answeredAt }
    }

    /// Correct / last-N accuracy for a card, or nil when the card has no determinate correctness
    /// signal (every considered attempt is unanswered). Used to rank weak spots and flag needs-care.
    private static func perCardAccuracy(_ attempts: [StudyAttemptSnapshot], lastN: Int) -> Double? {
        let ordered = attempts.sorted { $0.answeredAt > $1.answeredAt }.prefix(lastN)
        guard !ordered.isEmpty else { return nil }
        guard ordered.contains(where: { $0.wasCorrect != nil || $0.assessment != nil }) else { return nil }
        let correct = ordered.filter { StudyProgressMetrics.isCorrect($0) }.count
        return Double(correct) / Double(ordered.count)
    }

    /// Distinct cards that are unseen (`boxLevel == nil`) or whose latest state is `.again` / low
    /// accuracy (below `lowAccuracyThreshold`, not mastered).
    private static func needsCareCount(versionAttempts: [StudyAttemptSnapshot]) -> Int {
        var needsCare = Set<String>()
        for stableID in Set(versionAttempts.map(\.stableID)) {
            guard let latest = latestAttempt(versionAttempts, for: stableID) else { continue }

            if latest.boxLevel == nil {
                needsCare.insert(stableID)          // unseen — never graded into a box
                continue
            }
            if latest.assessment == .again {
                needsCare.insert(stableID)          // re-failed on the last attempt
                continue
            }
            if latest.assessment == .gotIt {
                continue                            // mastered-ish — not needs-care
            }

            // Latest is `.hard` or a wrong mock-test result: flag when the card's accuracy is low.
            let cardAccuracy = perCardAccuracy(
                versionAttempts.filter { $0.stableID == stableID },
                lastN: 5
            )
            if let cardAccuracy, cardAccuracy <= lowAccuracyThreshold {
                needsCare.insert(stableID)
            }
        }
        return needsCare.count
    }

    /// ISO-8601 week start (Monday) for `date`. Per the design spec, weeks are ISO regardless of the
    /// passed calendar's locale; the `calendar` parameter is retained for signature compatibility.
    private static func isoCalendar() -> Calendar {
        Calendar(identifier: .iso8601)
    }

    private static func weekStart(for date: Date) -> Date {
        let iso = isoCalendar()
        let startOfDay = iso.startOfDay(for: date)
        // `.weekday`: Sunday = 1 ... Saturday = 7 (Monday = 2), independent of locale.
        let weekday = iso.dateComponents([.weekday], from: startOfDay).weekday ?? 2
        let daysSinceMonday = (weekday - 2 + 7) % 7
        return iso.date(byAdding: .day, value: -daysSinceMonday, to: startOfDay)!
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    // ponytail: magic low-accuracy threshold; the design leaves "low accuracy" undefined. Revisit
    // if the UI accuracy bands (High / Needs review / Mastered) become a shared domain constant.
    private static let lowAccuracyThreshold = 0.5
}
