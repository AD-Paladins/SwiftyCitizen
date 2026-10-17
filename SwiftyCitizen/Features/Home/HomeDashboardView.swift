import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    let configuration: OnboardingConfiguration
    @Binding var selectedTab: AppTab

    @Environment(ThemeManager.self) private var themeManager
    @Environment(PendingNavigation.self) private var pendingNavigation
    private var palette: AppPalette { themeManager.palette }
    @Query private var attempts: [QuestionAttempt]
    @Query private var bookmarks: [Bookmark]

    private var snapshots: [StudyAttemptSnapshot] {
        attempts.compactMap(\.snapshot)
    }

    private var reviewedToday: Int {
        StudyProgressMetrics.reviewedToday(attempts: snapshots)
    }

    private var gotItRate: Double? {
        StudyProgressMetrics.gotItRate(attempts: snapshots)
    }

    private var streak: Int {
        StudyProgressMetrics.streak(attempts: snapshots)
    }

    /// The active version's question bank, fed to the scheduler-based due count so Home's "Due
    /// next" matches the Study tab's due number (single app-wide "due" definition).
    private var bankQuestions: [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private var dueCount: Int {
        guard let testConfiguration = configuration.testConfiguration else { return 0 }
        return StudyProgressMetrics.dueCount(
            attempts: snapshots,
            configuration: testConfiguration,
            questions: bankQuestions
        )
    }

    /// Number of bookmarked questions for the active test version. Bookmarks are scoped
    /// by version here; the pure domain layer never touches SwiftData.
    private var bookmarkedCount: Int {
        guard let raw = configuration.selectedTestVersion?.rawValue else { return 0 }
        return bookmarks.filter { $0.testVersionRawValue == raw }.count
    }

    private var coveredCount: Int {
        guard let testConfiguration = configuration.testConfiguration else { return 0 }
        return StudyProgressMetrics.coveredCount(
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

                    streakCard

                    ConfigurationSummaryView(configuration: configuration)

                    continueStudyingCard

                  todaySection

                       dueNextSection

                        bookmarkedSection
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

    private var bookmarkedSection: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Text("homeBookmarkedCardTitle")
                .font(CivicText.headlineSM.font)
            if bookmarkedCount > 0 {
                bookmarkedCard
            } else if reviewedToday > 0 {
                EmptyStateView(
                    systemImage: "bookmark",
                    title: "homeBookmarkedEmptyCaughtupTitle",
                    message: "homeBookmarkedEmptyCaughtupMessage"
                )
            } else {
                EmptyStateView(
                    systemImage: "bookmark.slash",
                    title: "homeBookmarkedEmptyTitle",
                    message: "homeBookmarkedEmptyMessage"
                )
            }
        }
    }

    private var bookmarkedCard: some View {
        HStack(spacing: Space.md.value) {
            VStack(alignment: .leading, spacing: Space.sm.value) {
                Text("\(bookmarkedCount)")
                    .font(CivicText.metricDisplay.font)
                    .foregroundStyle(palette.ink)
                Text("homeBookmarkedCardHint")
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
        .onTapGesture { openBookmarked() }
        .accessibilityElement(children: .combine)
        .accessibilityHint("homeBookmarkedCardHint")
    }

    /// Switches to the Study tab and records that targeted review should open on the
    /// Bookmarked scope. `StudyView` performs the navigation; `TargetedReviewView`
    /// consumes and clears the pending scope when it appears.
    private func openBookmarked() {
        pendingNavigation.setBookmarked()
        selectedTab = .study
    }

    private var gotItRateText: String {
        guard let rate = gotItRate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }
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
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
