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

    /// Mock-test attempts for the active version (`wasCorrect` is only ever set by a mock test).
    private var mockAttemptsForVersion: [StudyAttemptSnapshot] {
        guard let version = bankVersion else { return [] }
        return snapshots.filter { $0.testVersion == version && $0.wasCorrect != nil }
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

    private var overallMockAccuracy: Double? {
        let versionAttempts = mockAttemptsForVersion
        guard !versionAttempts.isEmpty else { return nil }
        let correct = versionAttempts.filter { StudyProgressMetrics.isCorrect($0) }.count
        return Double(correct) / Double(versionAttempts.count)
    }

    // MARK: - Body

    var body: some View {
        if !hasVersionData {
            emptyState
        } else {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg.value) {
                        readinessHero

                        masteryBuckets

                        topicCoverageSection

                        if hasMockTestData {
                            accuracyBreakdownSection
                        }

                        weakSpotsSection

                        momentumSection
                    }
                    .padding(Space.lg.value)
                }
                .scrollContentBackground(.hidden)
                .background(palette.canvas.ignoresSafeArea())
                .navigationTitle("progressTitle")
            }
        }
    }

    private var hasMockTestData: Bool {
        !mockAttemptsForVersion.isEmpty
    }

    // MARK: - 1. Hero / honest readiness

    private var readinessHero: some View {
        let coverage = "\(versionReviewedCount) \(String(localized: "commonOf")) \(bankCount) \(String(localized: "progressTopicSeenOf"))"

        return VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("progressHeroLabel")
                .font(CivicText.labelLG.font.weight(.semibold))
                .foregroundStyle(palette.onPrimary)

            if let result = lastMockTestResult {
                Text("\(result.correct) \(String(localized: "commonOf")) \(result.asked)")
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.onPrimary)

                HStack(spacing: Space.sm.value) {
                    passIcon(result.passed)
                    Text(passLabel(result.passed))
                        .font(CivicText.labelMD.font.weight(.semibold))
                        .foregroundStyle(palette.onPrimary.opacity(0.9))
                }
                if let endedAt = lastMockTest?.endedAt {
                    Text(endedAt.formatted(.dateTime.day().month().year()))
                        .font(CivicText.labelMD.font)
                        .foregroundStyle(palette.onPrimary.opacity(0.8))
                }
            } else {
                Text("progressHeroNoMock")
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.onPrimary.opacity(0.9))
            }

            Text(coverage)
                .font(CivicText.labelMD.font)
                .foregroundStyle(palette.onPrimary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .background(palette.primary, in: RoundedRectangle(cornerRadius: Space.xl.value))
    }

    private func passIcon(_ passed: Bool) -> some View {
        Image(systemName: passed ? "checkmark.seal.fill" : "xmark.octagon.circle")
            .font(CivicText.labelMD.font.weight(.semibold))
            .foregroundStyle(palette.onPrimary)
            .accessibilityHidden(true)
    }

    private func passLabel(_ passed: Bool) -> LocalizedStringKey {
        passed ? "progressHeroPassed" : "progressHeroFailed"
    }

    // MARK: - 2. Mastery buckets row

    private var masteryBuckets: some View {
        HStack(spacing: Space.sm.value) {
            bucketCell(
                count: buckets.graduated,
                label: "progressBucketGraduated",
                meaning: "progressBucketGraduatedMeaning",
                tint: palette.success
            )
            bucketCell(
                count: buckets.inReview,
                label: "progressBucketInReview",
                meaning: "progressBucketInReviewMeaning",
                tint: palette.warning
            )
            bucketCell(
                count: buckets.needsCare,
                label: "progressBucketNeedsCare",
                meaning: "progressBucketNeedsCareMeaning",
                tint: palette.danger
            )
        }
    }

    private func bucketCell(count: Int, label: LocalizedStringKey, meaning: LocalizedStringKey, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            Text("\(count)")
                .font(CivicText.headlineLG.font)
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(CivicText.labelSM.font.weight(.semibold))
                .foregroundStyle(palette.ink)
            Text(meaning)
                .font(CivicText.bodySM.font)
                .foregroundStyle(palette.dimmed)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.md.value)
        .cardStyle()
    }

    // MARK: - 3. Topic coverage

    private var topicCoverageSection: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            sectionHeader(
                title: "progressTopicCoverageTitle",
                subtitle: "\(versionReviewedCount) \(String(localized: "commonOf")) \(bankCount) \(String(localized: "progressTopicSeenOf"))"
            )
            ForEach(accuracyByDomainData, id: \.topic) { row in
                topicCard(row)
            }
        }
    }

    private func topicCard(_ row: (topic: String, accuracy: Double?, count: Int)) -> some View {
        return VStack(alignment: .leading, spacing: Space.lg.value) {
            HStack(spacing: Space.sm.value) {
                topicBadge(row.topic)
                VStack(alignment: .leading, spacing: Space.xs.value) {
                    Text(row.topic)
                        .font(CivicText.headlineSM.font)
                        .foregroundStyle(palette.ink)
                    let topicTotal = topicTotals[row.topic] ?? bankCount
                    Text("\(row.count) \(String(localized: "progressTopicQsOf")) \(topicTotal)")
                        .font(CivicText.labelMD.font)
                        .foregroundStyle(palette.dimmed)
                        .monospacedDigit()
                }
                Spacer()
                Text(accuracyText(row.accuracy))
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture { openTopic(row.topic) }
        .accessibilityElement(children: .combine)
        .accessibilityHint("progressTopicReviewHint")
    }

    private func topicBadge(_ topic: String) -> some View {
        let initial = topic.first.map { String($0.uppercased()) } ?? "?"
        return Text(initial)
            .font(CivicText.labelSM.font.weight(.semibold))
            .foregroundStyle(palette.onPrimary)
            .frame(width: 28, height: 28)
            .background(palette.primary, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 4. Accuracy breakdown (mock-test only)

    private var accuracyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("progressAccuracyBreakdownTitle")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)

            SummaryMetricView(
                value: accuracyText(overallMockAccuracy),
                label: "progressAccuracyOverall",
                tint: palette.primary
            )

            VStack(spacing: Space.sm.value) {
                ForEach(accuracyByDomainData, id: \.topic) { row in
                    accuracyRow(row)
                }
            }
        }
    }

    private func accuracyRow(_ row: (topic: String, accuracy: Double?, count: Int)) -> some View {
        return HStack(spacing: Space.sm.value) {
            topicBadge(row.topic)
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text(row.topic)
                    .font(CivicText.bodyMD.font)
                    .foregroundStyle(palette.ink)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Space.xs.value) {
                Text(accuracyText(row.accuracy))
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .monospacedDigit()
                if let status = accuracyStatus(row.accuracy) {
                    Text(status)
                        .font(CivicText.labelSM.font)
                        .foregroundStyle(palette.dimmed)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.md.value)
        .cardStyle()
    }

    private func accuracyStatus(_ accuracy: Double?) -> LocalizedStringKey? {
        guard let accuracy else { return nil }
        if accuracy >= 0.95 { return "progressAccuracyMastered" }
        if accuracy >= 0.75 { return "progressAccuracyHighConfidence" }
        return "progressAccuracyNeedsReview"
    }

    // MARK: - 5. Critical weak spots

    private var weakSpotsSection: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            sectionHeader(
                title: "progressWeakSpotsHeader",
                subtitle: "\(weakSpotsData.count) \(String(localized: "progressWeakItems"))"
            )

            if weakSpotsData.isEmpty {
                Text("progressWeakSpotsNone")
                    .font(CivicText.bodyMD.font)
                    .foregroundStyle(palette.dimmed)
            } else {
                VStack(spacing: 0) {
                    ForEach(weakSpotsData, id: \.stableID) { spot in
                        weakSpotRow(spot)
                    }
                }
                .cardStyle()
            }

            if !weakSpotsData.isEmpty {
                queueButton(count: weakSpotsData.count)
            }
        }
    }

    private func weakSpotRow(_ spot: ProgressAnalytics.WeakSpot) -> some View {
        let question = questionIndex[spot.stableID]?.officialQuestion ?? spot.stableID
        return HStack(spacing: Space.sm.value) {
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text(question)
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(spot.topic)
                    .font(CivicText.labelSM.font)
                    .foregroundStyle(palette.dimmed)
            }
            Spacer()
            Text(accuracyText(spot.accuracy))
                .font(CivicText.labelMD.font.weight(.semibold))
                .foregroundStyle(palette.ink)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.sm.value)
        .background(palette.canvas.opacity(0.4))
        .contentShape(Rectangle())
        .onTapGesture { openTopic(spot.topic) }
    }

    private func queueButton(count: Int) -> some View {
        return Button(action: queueWeakSpots) {
            Text("\(count) \(String(localized: "progressQueueWeakItems"))")
                .font(CivicText.labelMD.font.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(ControlSize.regular)
        .tint(palette.primary)
        .foregroundStyle(palette.primary)
    }

    // MARK: - 6. Study momentum (streak only)

    private var momentumSection: some View {
        HStack(spacing: Space.md.value) {
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text("progressMomentumStreak")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
                Text("\(streakCount)")
                    .font(CivicText.headlineLG.font)
                    .foregroundStyle(palette.ink)
                    .monospacedDigit()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }

    // MARK: - Shared helpers

    private func sectionHeader(title: LocalizedStringKey, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            Text(title)
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
            if let subtitle {
                Text(subtitle)
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
                    .monospacedDigit()
            }
        }
    }

    private func accuracyText(_ accuracy: Double?) -> String {
        guard let accuracy else { return "—" }
        return "\(Int((accuracy * 100).rounded()))%"
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
