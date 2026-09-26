import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    let configuration: OnboardingConfiguration
    @Binding var selectedTab: AppTab

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @Query private var attempts: [QuestionAttempt]

    private var snapshots: [StudyAttemptSnapshot] {
        attempts.compactMap(\.snapshot)
    }

    private var reviewedToday: Int {
        StudyProgressMetrics.reviewedToday(attempts: snapshots)
    }

    private var dailyTarget: Int { 10 }

    private var gotItRate: Double? {
        StudyProgressMetrics.gotItRate(attempts: snapshots)
    }

    private var streak: Int {
        StudyProgressMetrics.streak(attempts: snapshots)
    }

    private var dueCount: Int {
        guard let testConfiguration = configuration.testConfiguration else { return 0 }
        return StudyProgressMetrics.dueCount(
            attempts: snapshots,
            configuration: testConfiguration
        )
    }

    private var readinessPercentage: Double? {
        guard let testConfiguration = configuration.testConfiguration else { return nil }
        return StudyProgressMetrics.readinessPercentage(
            attempts: snapshots,
            configuration: testConfiguration
        )
    }

    private var coveredCount: Int {
        guard let testConfiguration = configuration.testConfiguration else { return 0 }
        return StudyProgressMetrics.coveredCount(
            attempts: snapshots,
            configuration: testConfiguration
        )
    }

    private var mastery: MasteryBreakdown {
        guard let testConfiguration = configuration.testConfiguration else {
            return MasteryBreakdown(mastered: 0, due: 0, unseen: 0)
        }
        return StudyProgressMetrics.masteryBreakdown(
            attempts: snapshots,
            configuration: testConfiguration
        )
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return String(localized: "homeGreetingMorning")
        case 12..<19:
            return String(localized: "homeGreetingAfternoon")
        default:
            return String(localized: "homeGreetingEvening")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl.value) {
                    Text(greeting)
                        .font(CivicText.headlineLG.font)
                        .foregroundStyle(palette.ink)

                    readinessHeroCard

                    streakCard

                    ConfigurationSummaryView(configuration: configuration)

                    continueStudyingCard

                    dailyMilestoneCard

                  todaySection

                     masterySection

                      dueNextSection

                      tipBanner
                }
                .padding(Space.lg.value)
            }
            .navigationTitle("homeTitle")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(configuration: configuration)
                    } label: {
                        Label("settingsTitle", systemImage: "gearshape")
                    }
                    .accessibilityLabel("settingsTitle")
                }
            }
            .background(palette.canvas.ignoresSafeArea())
        }
    }

    private var continueStudyingCard: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("homeContinueTitle")
                .font(CivicText.headlineMD.font)
            Text("homeContinueSubtitle")
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.dimmed)
            PrimaryActionButton(title: "homeContinueCta", systemImage: "arrow.right") {
                selectedTab = .study
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }

    private var dailyMilestoneCard: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            HStack {
                Text("homeMilestoneTitle")
                    .font(CivicText.headlineSM.font)
                Spacer()
                Text("\(reviewedToday) \(String(localized: "commonOf")) \(dailyTarget)")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
            }
            ProgressView(value: Double(min(reviewedToday, dailyTarget)))
                .tint(palette.primary)
            PrimaryActionButton(title: "homeMilestoneCta", systemImage: "arrow.right") {
                selectedTab = .study
            }
        }
        .padding(Space.lg.value)
        .cardStyle()
    }

    private var readinessHeroCard: some View {
        VStack(alignment: .leading, spacing: Space.lg.value) {
            Text("homeReadinessLabel")
                .font(CivicText.labelLG.font.weight(.semibold))
                .foregroundStyle(palette.onPrimary)
            HStack(alignment: .firstTextBaseline, spacing: Space.sm.value) {
                Text(readinessText)
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.onPrimary)
                Text(readinessSubtitle)
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.onPrimary.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .background(palette.primary, in: RoundedRectangle(cornerRadius: Space.xl.value))
    }

    private var streakCard: some View {
        HStack(spacing: Space.md.value) {
            Image(systemName: "fire")
                .font(CivicText.headlineLG.font)
                .foregroundStyle(palette.warning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.sm.value) {
                Text("\(streak)")
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.ink)
                Text("homeStreakLabel")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
            }
            Spacer()
        }
        .padding(Space.lg.value)
        .cardStyle()
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("homeTodayTitle")
                .font(CivicText.headlineSM.font)
            if reviewedToday > 0 {
                HStack(spacing: Space.md.value) {
                    SummaryMetricView(value: "\(reviewedToday)", label: "homeMetricReviewed")
                    SummaryMetricView(value: gotItRateText, label: "homeMetricGotit")
                }
            } else {
                EmptyStateView(
                    systemImage: "clock",
                    title: "homeTodayEmptyTitle",
                    message: "homeTodayEmptyMessage"
                )
            }
        }
    }

    private var masterySection: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("homeMasteryTitle")
                .font(CivicText.headlineSM.font)
            HStack(spacing: Space.md.value) {
                SummaryMetricView(
                    value: "\(mastery.mastered)",
                    label: "homeMasteryMastered",
                    tint: palette.success
                )
                SummaryMetricView(
                    value: "\(mastery.due)",
                    label: "homeMasteryDue",
                    tint: palette.warning
                )
                SummaryMetricView(
                    value: "\(mastery.unseen)",
                    label: "homeMasteryUnseen",
                    tint: palette.dimmed
                )
            }
        }
        .padding(Space.lg.value)
        .cardStyle()
    }

    private var dueNextSection: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("homeDuenextTitle")
                .font(CivicText.headlineSM.font)
            if dueCount > 0 {
                dueNextCard
            } else if reviewedToday > 0 {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "homeDuenextEmptyCaughtupTitle",
                    message: "homeDuenextEmptyCaughtupMessage"
                )
            } else {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "homeDuenextEmptyNoneTitle",
                    message: "homeDuenextEmptyNoneMessage"
                )
            }
        }
    }

    private var dueNextCard: some View {
        HStack(spacing: Space.md.value) {
            VStack(alignment: .leading, spacing: Space.sm.value) {
                Text("\(dueCount)")
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.ink)
                Text(dueCountLabel)
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.dimmed)
                .accessibilityHidden(true)
        }
        .padding(Space.lg.value)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = .study
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("homeDuenextCardHint")
    }

    private var dueCountLabel: String {
        let unit = dueCount == 1 ? String(localized: "unitQuestionSingular") : String(localized: "unitQuestionPlural")
        return "\(dueCount) \(unit) to review"
    }

    private var gotItRateText: String {
        guard let rate = gotItRate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private var readinessText: String {
        guard let pct = readinessPercentage else { return "—" }
        return "\(Int((pct * 100).rounded()))%"
    }

    private var readinessSubtitle: String {
        guard let testConfiguration = configuration.testConfiguration,
              let pct = readinessPercentage else {
            return String(localized: "homeReadinessFallback")
        }
        let total = testConfiguration.questionBankCount
        let covered = Int((pct * Double(total)).rounded())
        let unit = total == 1 ? String(localized: "unitQuestionsCoveredSingular") : String(localized: "unitQuestionsCoveredPlural")
        return "\(covered) \(String(localized: "commonOf")) \(total) \(unit)"
    }

    private var tipBanner: some View {
        HStack(alignment: .top, spacing: Space.md.value) {
            Image(systemName: "lightbulb.fill")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.warning)
                .accessibilityHidden(true)
            Text(currentTip)
                .font(CivicText.bodySM.font)
                .foregroundStyle(palette.dimmed)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.md.value)
        .cardStyle()
    }

    private var currentTip: String {
        let tips = StudyTips.all
        return tips[Calendar.current.component(.dayOfYear, from: Date()) % tips.count]
    }
}

enum StudyTips {
    // Sample copy for the content team to replace; tracked in docs/plan/design-redesign-plan.md:177.
    static let all = [
        "Tip: Take your time to read each question carefully before choosing an answer.",
        "Tip: If you are unsure, eliminate the answers you know are wrong first.",
        "Tip: Reviewing questions you got wrong helps them stick.",
        "Tip: Short, daily practice beats long weekly sessions.",
        "Tip: Say your answer out loud to practice for the in-person interview.",
    ]
}

#Preview {
    HomeDashboardView(
        configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ),
        selectedTab: .constant(.home)
    )
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}
