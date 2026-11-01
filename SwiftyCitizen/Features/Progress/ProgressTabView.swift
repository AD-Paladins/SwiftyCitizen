import SwiftUI
import SwiftData

struct ProgressTabView: View {
    let configuration: OnboardingConfiguration
    @Binding var selectedTab: AppTab

    init(configuration: OnboardingConfiguration, selectedTab: Binding<AppTab>) {
        self.configuration = configuration
        _selectedTab = selectedTab
    }

    @Environment(ThemeManager.self) private var themeManager
    @Environment(PendingNavigation.self) private var pendingNavigation
    @Query private var sessions: [StudySession]
    private var palette: AppPalette { themeManager.palette }

    /// Drives the hero's secondary actions. The mistakes screen doesn't exist yet, so this routes
    /// to a placeholder until the real window is built (see task tracker).
    @State private var mistakesRoute: HeroRoute? = nil

    private enum HeroRoute: Hashable {
        case mistakes
    }

    // MARK: - Data layer (unchanged)

    private var snapshots: [StudyAttemptSnapshot] {
        sessions.flatMap(\.attempts).compactMap(\.snapshot)
    }

    /// The version's question bank, loaded once and reused everywhere: the topic index, the
    /// scheduler buckets, and the weak-spot analytics. A single load site keeps the file read +
    /// JSON decode from happening once per derived value.
    private var loadedBank: [QuestionContent] {
        guard let version = bankVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    /// stableID -> topic, derived from the single loaded bank. The domain stays pure; the view
    /// only presents what `accuracyByDomain` returns.
    private var topicIndex: [String: String] {
        Dictionary(uniqueKeysWithValues: loadedBank.map { ($0.stableID, $0.topic) })
    }

    /// stableID -> question, so weak-spot rows can show the question text instead of the raw ID.
    private var questionIndex: [String: QuestionContent] {
        Dictionary(uniqueKeysWithValues: bankQuestions.map { ($0.stableID, $0) })
    }

    // MARK: - Version-scoped helpers

    private var testConfiguration: TestConfiguration? { configuration.testConfiguration }

    private var bankVersion: USCISTestVersion? { configuration.selectedTestVersion }

    /// The version's question bank, loaded once and reused for scheduler + weak-spot analytics.
    private var bankQuestions: [QuestionContent] {
        loadedBank
    }

    private var bankCount: Int { testConfiguration?.questionBankCount ?? 0 }

    /// Total questions per topic in the active version's bank (drives "X of Y Qs" per topic).
    private var topicTotals: [String: Int] {
        bankQuestions.reduce(into: [:]) { $0[$1.topic, default: 0] += 1 }
    }

    private var versionName: String {
        configuration.selectedTestVersion?.displayName ?? ""
    }

    /// Distinct cards reviewed for the active version (drives "X of M seen").
    private var versionReviewedCount: Int {
        guard let version = bankVersion else { return 0 }
        return Set(snapshots.filter { $0.testVersion == version }.map(\.stableID)).count
    }

    /// Whether there is any attempt data for the active version (drives the version-scoped empty state).
    private var hasVersionData: Bool {
        guard let version = bankVersion else { return false }
        return snapshots.contains { $0.testVersion == version }
    }

    // MARK: - Domain analytics (ProgressAnalytics)

    private var buckets: ProgressAnalytics.Buckets {
        guard let config = testConfiguration else {
            return ProgressAnalytics.Buckets(graduated: 0, inReview: 0, needsCare: 0)
        }
        // Pass the version bank so `inReview` runs the scheduler-based due-card count.
        return ProgressAnalytics.buckets(attempts: snapshots, for: config, questions: bankQuestions)
    }

    private var accuracyByDomainData: [(topic: String, accuracy: Double?, count: Int)] {
        guard let version = bankVersion else { return [] }
        return ProgressAnalytics.accuracyByDomain(attempts: snapshots, topicIndex: topicIndex, for: version)
    }

    /// Overall accuracy for the active version (correct / total attempts), for the breakdown header.
    private var overallAccuracyValue: Double? {
        guard let version = bankVersion else { return nil }
        return ProgressAnalytics.overallAccuracy(attempts: snapshots, for: version)
    }

    /// Accuracy trend over the last two 14-day windows, for the breakdown header pill.
    private var accuracyTrendValue: ProgressAnalytics.AccuracyTrend {
        guard let version = bankVersion else { return .unknown }
        return ProgressAnalytics.accuracyTrend(attempts: snapshots, for: version)
    }

    /// Attempted topics (determinate accuracy only) for the breakdown rows. Topics with no
    /// determinate accuracy are excluded — they still surface in the carousel as "Needs review".
    private var breakdownRows: [TopicCoverageRow] {
        coverageRows.filter { $0.accuracy != nil }
    }

    private var weakSpotsData: [ProgressAnalytics.WeakSpot] {
        guard let version = bankVersion else { return [] }
        return ProgressAnalytics.weakSpots(attempts: snapshots, questions: bankQuestions, version: version)
    }

    private var streakCount: Int {
        StudyProgressMetrics.streak(attempts: snapshots)
    }

    // MARK: - Honest mock-test summary (last result for the active version)

    /// The most recent completed mock test for the active version, or nil when none exists.
    private var lastMockTest: StudySession? {
        guard let version = bankVersion else { return nil }
        return sessions
            .filter { $0.mode == .mockTest && $0.endedAt != nil && $0.testVersion == version }
            .max { lhs, rhs in
                (lhs.endedAt ?? .distantPast) < (rhs.endedAt ?? .distantPast)
            }
    }

    /// Score + pass/fail for that mock test. The view selects the session; `MockTestResult` owns
    /// only the arithmetic so it stays unit-testable without SwiftData.
    private var lastMockTestResult: MockTestResult? {
        guard let session = lastMockTest, let config = testConfiguration else { return nil }
        let correct = session.attempts.filter { $0.wasCorrect == true }.count
        return MockTestResult(
            asked: session.deckStableIDs.count,
            correct: correct,
            passingScore: config.passingScore
        )
    }

    // MARK: - Body

    var body: some View {
        if !hasVersionData {
            emptyState
        } else {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg.value) {
                        LatestMockTestHero(
                            result: lastMockTestResult,
                            coverage: "\(versionReviewedCount) \(String(localized: "commonOf")) \(bankCount) \(String(localized: "progressMockSeen"))",
                            date: lastMockTest?.endedAt.map { $0.formatted(.dateTime.day().month().year()) },
                            onRetake: { selectedTab = .practice },
                            onMistakes: { mistakesRoute = .mistakes }
                        )

                        MasteryBucketsRow(graduated: buckets.graduated, inReview: buckets.inReview, needsCare: buckets.needsCare)

                        accuracyBreakdownSection

                        WeakSpotsSection(weakSpots: weakSpotsData, questionText: { questionIndex[$0]?.officialQuestion ?? $0 }, onTopicTap: openTopic, onQueue: queueWeakSpots)

                        MomentumSection(streak: streakCount)
                    }
                    .padding(Space.lg.value)
                }
                .scrollContentBackground(.hidden)
                .background(palette.canvas.ignoresSafeArea())
                .navigationTitle("progressTitle")
                .navigationDestination(item: $mistakesRoute) { _ in
                    mistakesComingSoon
                }
            }
        }
    }

    /// Placeholder for the mistakes screen — the real window doesn't exist yet (see task tracker).
    /// The hero's Mistakes button is wired to this so it is functional and testable now.
    private var mistakesComingSoon: some View {
        VStack(spacing: Space.lg.value) {
            Image(systemName: "book.fill")
                .font(CivicText.headlineLG.font)
                .foregroundStyle(palette.dimmed)
            Text("progressMistakesComingSoon")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(Space.lg.value)
    }

   private var accuracyBreakdownSection: some View {
        AccuracyBreakdownSection(
            rows: breakdownRows,
            overallAccuracy: overallAccuracyValue,
            trend: accuracyTrendValue,
            onTopicTap: openTopic
        )
    }

    /// Every topic in the active version's bank (first-appearance order), each paired with its
    /// attempted accuracy/count. Topics with no attempts report `accuracy == nil` / `seen == 0` so
    /// the carousel can render their "Not started" cards — `accuracyByDomain` alone omits them.
    private var coverageRows: [TopicCoverageRow] {
        var order: [String] = []
        var seenTopics = Set<String>()
        for question in bankQuestions {
            if seenTopics.insert(question.topic).inserted {
                order.append(question.topic)
            }
        }
        let attempted = Dictionary(uniqueKeysWithValues: accuracyByDomainData.map { ($0.topic, $0) })
        return order.enumerated().map { index, topic in
            if let row = attempted[topic] {
                return TopicCoverageRow(
                    topic: topic,
                    accuracy: row.accuracy,
                    seen: row.count,
                    total: topicTotals[topic] ?? bankCount,
                    orderIndex: index
                )
            }
            return TopicCoverageRow(
                topic: topic,
                accuracy: nil,
                seen: 0,
                total: topicTotals[topic] ?? bankCount,
                orderIndex: index
            )
        }
    }

    /// Queues a targeted review on the exact low-accuracy set this tab counts. `TargetedReviewView`
    /// consumes `reviewScope` on appear and opens scoped to `.lowAccuracy`, filtered by `weakStableIDs`.
    private func queueWeakSpots() {
        pendingNavigation.setWeakStableIDs(Set(weakSpotsData.map(\.stableID)))
        pendingNavigation.reviewScope = .lowAccuracy
        selectedTab = .study
    }

    // MARK: - Preserved

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "chart.bar",
            title: "progressEmptyVersionTitle",
            message: "progressEmptyVersionMessage"
        )
    }

    /// Mirrors Home's bookmarked card: record the scope on `PendingNavigation`, then switch to
    /// the Study tab. `StudyView` pushes targeted review and `TargetedReviewView` opens scoped
    /// to this topic.
    private func openTopic(_ topic: String) {
        pendingNavigation.setScopedTopic(topic)
        selectedTab = .study
    }
}

#Preview {
    ProgressTabView(
        configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ),
        selectedTab: .constant(.progress)
    )
    .environment(ThemeManager())
    .environment(PendingNavigation())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
