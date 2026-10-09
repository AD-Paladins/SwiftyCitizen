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

    /// stableID -> topic, resolved once from the bundled bank. The domain stays pure; the view
    /// only presents what `accuracyByDomain` returns.
    private var topicIndex: [String: String] {
        guard let version = configuration.selectedTestVersion else { return [:] }
        let questions = (try? QuestionBankLoader().load(version: version)) ?? []
        return Dictionary(uniqueKeysWithValues: questions.map { ($0.stableID, $0.topic) })
    }

    // MARK: - Version-scoped helpers

    private var testConfiguration: TestConfiguration? { configuration.testConfiguration }

    private var bankVersion: USCISTestVersion? { configuration.selectedTestVersion }

    /// The version's question bank, loaded once and reused for scheduler + weak-spot analytics.
    private var bankQuestions: [QuestionContent] {
        guard let version = bankVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private var bankCount: Int { testConfiguration?.questionBankCount ?? 0 }

    /// Total questions per topic in the active version's bank (drives "X of Y Qs" per topic).
    private var topicTotals: [String: Int] {
        bankQuestions.reduce(into: [:]) { $0[$1.topic, default: 0] += 1 }
    }

    private var versionName: String {
        configuration.selectedTestVersion?.displayName ?? ""
    }

    /// Distinct cards reviewed for the active version (drives "X of Y seen").
    private var versionReviewedCount: Int {
        guard let version = bankVersion else { return 0 }
        return Set(snapshots.filter { $0.testVersion == version }.map(\.stableID)).count
    }

    // MARK: - Domain analytics (ProgressAnalytics)

    private var buckets: ProgressAnalytics.Buckets {
        guard let config = testConfiguration else {
            return ProgressAnalytics.Buckets(graduated: 0, inReview: 0, needsCare: 0)
        }
        // Pass the version bank so `inReview` runs the scheduler-based due-card count.
        return ProgressAnalytics.buckets(attempts: snapshots, for: config, questions: bankQuestions)
    }

    private var predictedPassRate: Double? {
        guard let config = testConfiguration else { return nil }
        return ProgressAnalytics.passRate(attempts: snapshots, for: config)
    }

    private var weeklyTrend: Double? {
        guard let config = testConfiguration else { return nil }
        return ProgressAnalytics.passRateWeeklyDelta(attempts: snapshots, for: config)
    }

    private var standardMetToday: Bool {
        guard let config = testConfiguration else { return false }
        return ProgressAnalytics.standardMet(attempts: snapshots, for: config)
    }

    private var accuracyByDomainData: [(topic: String, accuracy: Double?, count: Int)] {
        guard let version = bankVersion else { return [] }
        return ProgressAnalytics.accuracyByDomain(attempts: snapshots, topicIndex: topicIndex, for: version)
    }

    private var overallAccuracy: Double? {
        guard let version = bankVersion else { return nil }
        let versionAttempts = snapshots.filter { $0.testVersion == version }
        guard !versionAttempts.isEmpty else { return nil }
        let correct = versionAttempts.filter { StudyProgressMetrics.isCorrect($0) }.count
        return Double(correct) / Double(versionAttempts.count)
    }

    private var weakSpotsData: [ProgressAnalytics.WeakSpot] {
        guard let version = bankVersion else { return [] }
        return ProgressAnalytics.weakSpots(attempts: snapshots, questions: bankQuestions, version: version)
    }

    private var trajectoryPoints: [ProgressAnalytics.WeekPoint] {
        ProgressAnalytics.accuracyByWeek(attempts: snapshots)
    }

    private var retentionRate: Double? {
        ProgressAnalytics.retentionStability(attempts: snapshots)
    }

    private var streakCount: Int {
        StudyProgressMetrics.streak(attempts: snapshots)
    }

    private var recommendationText: String {
        guard let config = testConfiguration else { return "" }
        return ProgressAnalytics.recommendation(attempts: snapshots, for: config)
    }

    // MARK: - Body

    var body: some View {
        if snapshots.isEmpty {
            emptyState
        } else {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.lg.value) {
                        readinessHero

                        masteryBuckets

                        if standardMetToday {
                            standardMetLine
                        }

                        topicCoverageSection

                        accuracyBreakdownSection

                        weakSpotsSection

                        momentumSection

                        retentionCard

                        if !recommendationText.isEmpty {
                            recommendationCard(recommendationText)
                        }

                        drillCTA
                    }
                    .padding(Space.lg.value)
                }
                .scrollContentBackground(.hidden)
                .background(palette.canvas.ignoresSafeArea())
                .navigationTitle("progressTitle")
            }
        }
    }

    // MARK: - 1. Hero / readiness banner

    private var readinessHero: some View {
        let percentage = predictedPassRate ?? 0
        let covered = Int((percentage * Double(bankCount)).rounded())
        let passingRequired = testConfiguration?.passingScore ?? 0
        let passingTotal = testConfiguration?.maximumQuestionsAsked ?? 0

        return VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("progressReadinessLabel")
                .font(CivicText.labelLG.font.weight(.semibold))
                .foregroundStyle(palette.onPrimary)

            HStack(alignment: .firstTextBaseline, spacing: Space.sm.value) {
                Text("\(Int((percentage * 100).rounded()))%")
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.onPrimary)
                Text("\(covered) \(String(localized: "commonOf")) \(bankCount) \(String(localized: "unitQuestionsCoveredPlural"))")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.onPrimary.opacity(0.85))
            }

            if let delta = weeklyTrend {
                HStack(spacing: Space.sm.value) {
                    let up = delta > 0
                    Image(systemName: up ? "arrow.up.forward" : "arrow.down.forward")
                        .font(CivicText.labelMD.font.weight(.semibold))
                        .foregroundStyle(palette.onPrimary)
                    Text("\(Int((abs(delta) * 100).rounded()))% \(String(localized: up ? "progressWeeklyTrendUp" : "progressWeeklyTrendDown"))")
                        .font(CivicText.labelMD.font)
                        .foregroundStyle(palette.onPrimary.opacity(0.9))
                }
            }

            VStack(alignment: .leading, spacing: Space.sm.value) {
                if standardMetToday {
                    HStack(spacing: Space.sm.value) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(CivicText.labelMD.font.weight(.semibold))
                            .foregroundStyle(palette.onPrimary)
                        Text("progressInterviewReady")
                            .font(CivicText.labelMD.font.weight(.semibold))
                            .foregroundStyle(palette.onPrimary)
                    }
                }
                if passingTotal > 0 {
                    HStack(spacing: Space.sm.value) {
                        Text("\(String(localized: "progressPassingReq")):")
                            .font(CivicText.labelMD.font)
                            .foregroundStyle(palette.onPrimary.opacity(0.9))
                        Text("\(passingRequired) \(String(localized: "commonOf")) \(passingTotal)")
                            .font(CivicText.labelMD.font.weight(.semibold))
                            .foregroundStyle(palette.onPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .background(palette.primary, in: RoundedRectangle(cornerRadius: Space.xl.value))
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

    // MARK: - 3. Standard met line

    private var standardMetLine: some View {
        HStack(spacing: Space.sm.value) {
            Image(systemName: "checkmark.shield.fill")
                .font(CivicText.labelMD.font)
                .foregroundStyle(palette.success)
            Text("\(String(localized: "progressStandardMet")) \(versionName)")
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 4. Topic coverage

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

    // MARK: - 5. Accuracy breakdown

    private var accuracyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("progressAccuracyBreakdownTitle")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)

            SummaryMetricView(
                value: accuracyText(overallAccuracy),
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

    // MARK: - 6. Critical weak spots

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
        return HStack(spacing: Space.sm.value) {
            Text(spot.stableID)
                .font(CivicText.labelMD.font.weight(.semibold))
                .foregroundStyle(palette.ink)
                .monospacedDigit()
            Spacer()
            Text(spot.topic)
                .font(CivicText.labelMD.font)
                .foregroundStyle(palette.dimmed)
                .multilineTextAlignment(.leading)
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
        return Button(action: queueNeedsWork) {
            Text("\(count) \(String(localized: "progressQueueWeakItems"))")
                .font(CivicText.labelMD.font.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(ControlSize.regular)
        .tint(palette.primary)
        .foregroundStyle(palette.primary)
    }

    // MARK: - 7. Study momentum

    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("progressMomentumTitle")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)

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
                VStack(alignment: .leading, spacing: Space.xs.value) {
                    Text("progressAccuracyOverall")
                        .font(CivicText.labelMD.font)
                        .foregroundStyle(palette.dimmed)
                    Text(accuracyText(overallAccuracy))
                        .font(CivicText.headlineLG.font)
                        .foregroundStyle(palette.ink)
                        .monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: Space.md.value) {
                Text("progressTrajectoryTitle")
                    .font(CivicText.labelLG.font.weight(.semibold))
                    .foregroundStyle(palette.ink)
                trajectoryBars
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }

    private var trajectoryBars: some View {
        HStack(alignment: .bottom, spacing: Space.md.value) {
            ForEach(trajectoryPoints, id: \.weekStart) { point in
                VStack(spacing: Space.xs.value) {
                    accuracyBar(point.accuracy)
                    Text(weekLabel(point.weekStart))
                        .font(CivicText.labelSM.font)
                        .foregroundStyle(palette.dimmed)
                        .monospacedDigit()
                }
            }
        }
    }

    private func accuracyBar(_ accuracy: Double?) -> some View {
        let height = accuracy.map { max(8, $0 * 64) } ?? 8
        return Rectangle()
            .fill((accuracy ?? 0) >= 0 ? palette.primary.opacity(0.85) : palette.surface)
            .frame(width: 28, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func weekLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month().day())
    }

    // MARK: - 8. Retention stability (+ gated oral speed)

    private var retentionCard: some View {
        // GATED: the design also shows "Avg Oral Speed" and "recall under speed". The codebase has
        // no per-answer timing field (only `answeredAt`), so these cannot be computed. Omit until a
        // timing field is added to QuestionAttempt. See progress-diagnostic-mirror-design.md §1/#14.
        return VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("progressRetentionLabel")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
            SummaryMetricView(
                value: accuracyText(retentionRate),
                label: "progressRetentionMeaning",
                tint: palette.success
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }

    // MARK: - 9. Recommendation

    private func recommendationCard(_ text: String) -> some View {
        return VStack(alignment: .leading, spacing: Space.sm.value) {
            HStack(spacing: Space.sm.value) {
                Image(systemName: "lightbulb.fill")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.warning)
                Text("progressRecommendationTitle")
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
            }
            Text(text)
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }

    // MARK: - 10. Diagnostic drill CTA

    private var drillCTA: some View {
        VStack(spacing: Space.sm.value) {
            Button(action: queueNeedsWork) {
                Label("progressDrillCTA", systemImage: "target")
                    .font(CivicText.headlineSM.font)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(palette.primary)

            Text("progressDrillNeedsCareLabel")
                .font(CivicText.labelSM.font)
                .foregroundStyle(palette.dimmed)
        }
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

    /// Queues a targeted review on the Needs-Care deck. `TargetedReviewView` consumes `reviewScope`
    /// on appear and opens scoped to `.needsWork`.
    private func queueNeedsWork() {
        pendingNavigation.reviewScope = .needsWork
        selectedTab = .study
    }

    // MARK: - Preserved

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "chart.bar",
            title: "progressNoProgressTitle",
            message: "progressNoProgressMessage"
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
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ),
        selectedTab: .constant(.progress)
    )
    .environment(ThemeManager())
    .environment(PendingNavigation())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
