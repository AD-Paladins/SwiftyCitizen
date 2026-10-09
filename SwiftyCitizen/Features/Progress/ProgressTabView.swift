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

    private var snapshots: [StudyAttemptSnapshot] {
        sessions.flatMap(\.attempts).compactMap(\.snapshot)
    }

    /// stableID -> topic, resolved once from the bundled bank. The domain stays pure; the view
    /// only presents what `coverageByTopic` returns.
    private var topicIndex: [String: String] {
        guard let version = configuration.selectedTestVersion else { return [:] }
        let questions = (try? QuestionBankLoader().load(version: version)) ?? []
        return Dictionary(uniqueKeysWithValues: questions.map { ($0.stableID, $0.topic) })
    }

    private var topicCoverage: [TopicCoverage] {
        guard let version = configuration.selectedTestVersion else { return [] }
        return StudyProgressMetrics.coverageByTopic(
            attempts: snapshots,
            for: version,
            topicIndex: topicIndex
        )
    }

    private var reviewedCount: Int {
        Set(snapshots.map(\.stableID)).count
    }

    private var sessionsThisWeek: Int {
        let weekStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .weekOfYear], from: Date())
        ) ?? Date()
        return sessions.filter { $0.startedAt >= weekStart }.count
    }

    var body: some View {
        if snapshots.isEmpty {
            emptyState
        } else {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.xl.value) {
                        readinessHero

                        coverageMap

                        momentumStrip
                    }
                    .padding(Space.lg.value)
                }
                .scrollContentBackground(.hidden)
                .background(palette.canvas.ignoresSafeArea())
                .navigationTitle("progressTitle")
            }
        }
    }

    /// Look-back readiness: mirrors Home's `readinessHeroCard` using the same metrics.
    private var readinessHero: some View {
        if let testConfiguration = configuration.testConfiguration,
           let percentage = StudyProgressMetrics.readinessPercentage(
               attempts: snapshots,
               configuration: testConfiguration
           ) {
            heroContent(percentage: percentage, total: testConfiguration.questionBankCount)
        } else {
            heroContent(percentage: 0, total: 0)
        }
    }

    private func heroContent(percentage: Double, total: Int) -> some View {
        let covered = Int((percentage * Double(total)).rounded())
        return VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("homeReadinessLabel")
                .font(CivicText.labelLG.font.weight(.semibold))
                .foregroundStyle(palette.onPrimary)
            HStack(alignment: .firstTextBaseline, spacing: Space.sm.value) {
                Text("\(Int((percentage * 100).rounded()))%")
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.onPrimary)
                Text("\(covered) \(String(localized: "commonOf")) \(total) \(String(localized: "unitQuestionsCoveredPlural"))")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.onPrimary.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .background(palette.primary, in: RoundedRectangle(cornerRadius: Space.xl.value))
    }

    private var coverageMap: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            ForEach(topicCoverage, id: \.topic) { coverage in
                topicCard(coverage)
            }
        }
    }

    private var momentumStrip: some View {
        HStack(spacing: Space.md.value) {
            SummaryMetricView(
                value: "\(StudyProgressMetrics.streak(attempts: snapshots))",
                label: "progressStreak"
            )
            SummaryMetricView(value: "\(reviewedCount)", label: "progressReviewed")
            SummaryMetricView(value: "\(sessionsThisWeek)", label: "progressSessions")
        }
    }

    private func topicCard(_ coverage: TopicCoverage) -> some View {
        let attempted = coverage.mastered + coverage.due
        let mastery = attempted > 0 ? Double(coverage.mastered) / Double(attempted) : 0
        return VStack(alignment: .leading, spacing: Space.lg.value) {
            HStack {
                Text(coverage.topic)
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
                Spacer()
                Text("\(Int((mastery * 100).rounded()))%")
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.dimmed)
            }
            ProgressView(value: mastery)
                .tint(palette.primary)
            HStack(spacing: Space.md.value) {
                SummaryMetricView(
                    value: "\(coverage.mastered)",
                    label: "progressMastered",
                    tint: palette.success
                )
                SummaryMetricView(
                    value: "\(coverage.due)",
                    label: "progressDue",
                    tint: palette.warning
                )
                SummaryMetricView(
                    value: "\(coverage.unseen)",
                    label: "progressUnseen",
                    tint: palette.dimmed
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture { openTopic(coverage.topic) }
        .accessibilityElement(children: .combine)
        .accessibilityHint("progressTopicReviewHint")
    }

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
