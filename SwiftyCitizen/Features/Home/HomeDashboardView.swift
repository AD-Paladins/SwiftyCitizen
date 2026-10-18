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

    // Default daily review goal. Kept hardcoded for now — surface this as a user-configurable
    // setting once the habit loop has real data to back a sensible default.
    // ponytail: hardcoded 15; make it configurable (e.g. Settings) when the daily-goal feature lands.
    private let dailyGoal = 15

    /// Mocked listening-mode queue size. No listening logic exists yet; this is placeholder metadata.
    private let mockedQueueCount = 18

    private var snapshots: [StudyAttemptSnapshot] {
        attempts.compactMap(\.snapshot)
    }

    private var reviewedToday: Int {
        StudyProgressMetrics.reviewedToday(attempts: snapshots)
    }

    private var streak: Int {
        StudyProgressMetrics.streak(attempts: snapshots)
    }

    /// The active version's question bank, fed to the scheduler-based due count so Home's "due"
    /// matches the Study tab's due number (single app-wide "due" definition).
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

    private var versionRaw: String {
        configuration.selectedTestVersion?.rawValue ?? "—"
    }

    /// Fraction of the daily goal reviewed today, clamped to 1.0 so the ring never overflows.
    private var progressFraction: Double {
        min(1.0, Double(reviewedToday) / Double(dailyGoal))
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

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMyyyy")
        return formatter
    }()

    private let monthDayYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd, yyyy")
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl.value) {
                    header
                    estimatedInterviewSection
                    heroDrillSection
                    quickModesSection
                    archivalTipSection
                    civicsFactSection
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: Space.md.value) {
            VStack(alignment: .leading, spacing: 2) {
                Text("homeLaunchpadLabel")
                    .font(CivicText.labelMD.font)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.dimmed)
                Text(greeting)
                    .font(CivicText.headlineLG.font)
                    .foregroundStyle(palette.ink)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Space.sm.value) {
                trackBadge
                fireStreakPill
            }
        }
    }

    private var trackBadge: some View {
        launchPill(background: palette.secondaryContainer, foreground: palette.onSecondary) {
            Image(systemName: "verified.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(palette.onSecondary)
                .accessibilityHidden(true)
            Text("homeTrackBadgePrefix") + Text(" ") + Text(versionRaw) + Text(" ") + Text("homeTrackBadgeBank")
        }
    }

    private var fireStreakPill: some View {
        launchPill(background: palette.surfaceVariant, foreground: palette.ink) {
            Image(systemName: "fire")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(palette.warning)
                .accessibilityHidden(true)
            Text("\(streak)") + Text(" ") + Text("homeStreakDaySuffix")
        }
    }

    /// Shared rounded pill used by the header badges. Kept as one helper so both pills stay visually
    /// consistent without duplicating the spacing/background boilerplate.
    @ViewBuilder
    private func launchPill<Content: View>(
        background: Color,
        foreground: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: Space.xs.value) {
            content()
        }
        .font(CivicText.labelSM.font)
        .foregroundStyle(foreground)
        .padding(.horizontal, Space.md.value)
        .padding(.vertical, 6)
        .background(background, in: RoundedRectangle(cornerRadius: 16, style: .circular))
    }

    // MARK: - H1: Estimated USCIS Interview

    @ViewBuilder
    private var estimatedInterviewSection: some View {
        if let filingDate = configuration.filingDate,
           let interview = USCISDateEstimates.estimatedInterviewDate(filingDate: filingDate) {
            estimatedInterviewCard(filingDate: filingDate, interview: interview)
        } else {
            unavailableInterviewCard
        }
    }

    private func estimatedInterviewCard(filingDate: Date, interview: Date) -> some View {
        HStack(alignment: .top, spacing: Space.md.value) {
            Image(systemName: "calendar_clock")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primary)
                .frame(width: 44, height: 44)
                .background(palette.primaryContainer.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.sm.value) {
                HStack {
                    Text("homeInterviewTitle")
                        .font(CivicText.headlineSM.font)
                        .foregroundStyle(palette.ink)
                    Spacer()
                    (Text("homeInterviewTargetLabel") + Text(": ") + Text(monthYearFormatter.string(from: interview)))
                        .font(CivicText.labelSM.font.weight(.semibold))
                        .foregroundStyle(palette.primary)
                        .monospacedDigit()
                        .padding(.horizontal, Space.sm.value)
                        .padding(.vertical, 4)
                        .background(palette.primaryContainer.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                Text("homeInterviewFiledLabel") + Text(" ") + Text(monthDayYearFormatter.string(from: filingDate))
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.dimmed)
            }
        }
        .padding(Space.lg.value)
        .cardStyle()
    }

    private var unavailableInterviewCard: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.warning)
                .accessibilityHidden(true)
            Text("homeInterviewUnavailableTitle")
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
            Text("homeInterviewUnavailableMessage")
                .font(CivicText.bodySM.font)
                .foregroundStyle(palette.dimmed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }

    // MARK: - H2: Hero drill card

    private var heroDrillSection: some View {
        VStack(alignment: .leading, spacing: Space.md.value) {
            heroSubHeader

            HStack(alignment: .center, spacing: Space.md.value) {
                VStack(alignment: .leading, spacing: Space.sm.value) {
                    Text("heroDrillTitle")
                        .font(CivicText.headlineLG.font)
                        .foregroundStyle(palette.onPrimary)
                    statLine
                        .font(CivicText.bodyMD.font)
                        .foregroundStyle(palette.onPrimary)
                }
                Spacer()
                RingGauge(fraction: progressFraction, text: "\(reviewedToday) of \(dailyGoal)")
            }

            heroProgressStrip

            startReviewButton
        }
        .padding(Space.xl.value)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [palette.primary, palette.primaryContainer],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay { watermark }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .circular))
        .shadow(color: Color(uiColor: UIColor(red: 34 / 255, green: 38 / 255, blue: 34 / 255, alpha: 0.18)), radius: 16, x: 0, y: 8)
    }

    private var heroSubHeader: some View {
        HStack {
            Text("heroHabitChip")
                .font(CivicText.labelSM.font)
                .foregroundStyle(palette.onPrimary)
                .padding(.horizontal, Space.sm.value)
                .padding(.vertical, 4)
                .background(palette.onPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            Spacer()
            sessionLine
                .font(CivicText.labelSM.font)
                .foregroundStyle(palette.onPrimary)
                .monospacedDigit()
        }
    }

    private var heroProgressStrip: some View {
        HStack(spacing: Space.sm.value) {
            Text("heroDailyProgressLabel")
                .font(CivicText.labelSM.font)
                .foregroundStyle(palette.onPrimary)
            Spacer()
            (Text("\(Int((progressFraction * 100).rounded()))%") + Text(" ") + Text("heroCompleteLabel"))
                .font(CivicText.labelSM.font.weight(.bold))
                .foregroundStyle(palette.onPrimary)
                .monospacedDigit()
        }
        .padding(Space.sm.value)
        .background(palette.onPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private var startReviewButton: some View {
        Button {
            selectedTab = .study
        } label: {
            HStack(spacing: Space.sm.value) {
                Image(systemName: "play_arrow.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                (Text("homeHeroStart") + Text(" (\(dueCount))"))
                    .monospacedDigit()
            }
            .font(CivicText.headlineSM.font)
            .foregroundStyle(palette.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private var watermark: some View {
        Circle()
            .fill(palette.onPrimary.opacity(0.12))
            .frame(width: 160, height: 160)
            .blur(radius: 28)
            .offset(x: 70, y: 70)
            .opacity(0.6)
            .allowsHitTesting(false)
    }

    /// "<dueCount> questions due today • ~<minutes> min estimated". Composed from a `Text` chain so
    /// the localized pieces and the dynamic numbers coexist without xcstrings format placeholders.
    private var statLine: Text {
        let unit = dueCount == 1
            ? String(localized: "unitQuestionSingular")
            : String(localized: "unitQuestionPlural")
        let minutes = max(2, dueCount * 2)
        return Text("\(dueCount)") + Text(" ") + Text(unit) + Text(" ") + Text("heroDueToday")
            + Text(" • ~") + Text("\(minutes)") + Text(" ") + Text("heroMinEstimated")
    }

    private var sessionLine: Text {
        Text("heroSessionPrefix") + Text(" ") + Text("\(reviewedToday)") + Text(" ")
            + Text(String(localized: "commonOf")) + Text(" ") + Text("\(dailyGoal)")
    }

    // MARK: - H3: Quick Modes

    private var quickModesSection: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            VStack(alignment: .leading, spacing: 2) {
                Text("quickModesTitle")
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
                Text("quickModesSubtitle")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Space.md.value) {
                quickModeCard(
                    systemImage: "mic.fill",
                    title: "oralSimTitle",
                    subtitle: "oralSimSubtitle",
                    footer: Text("oralSimFooter")
                        .font(CivicText.labelSM.font.weight(.semibold))
                        .foregroundStyle(palette.secondary),
                    iconBackground: palette.secondaryContainer,
                    iconForeground: palette.onSecondary
                )
                quickModeCard(
                    systemImage: "headphones",
                    title: "listeningTitle",
                    subtitle: "listeningSubtitle",
                    footer: (Text("listeningQueueLabel") + Text(": ") + Text("\(mockedQueueCount)"))
                        .font(CivicText.labelSM.font.weight(.semibold))
                        .foregroundStyle(palette.primary)
                        .monospacedDigit(),
                    iconBackground: palette.primaryContainer,
                    iconForeground: palette.onPrimaryContainer
                )
            }
        }
    }

    @ViewBuilder
    private func quickModeCard(
        systemImage: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        footer: some View,
        iconBackground: Color,
        iconForeground: Color
    ) -> some View {
        NavigationLink {
            HomeComingSoonView(systemImage: systemImage)
        } label: {
            VStack(alignment: .leading, spacing: Space.sm.value) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(iconForeground)
                        .frame(width: 44, height: 44)
                        .background(iconBackground, in: Circle())
                        .accessibilityHidden(true)
                    Spacer()
                }
                Text(title)
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
                Text(subtitle)
                    .font(CivicText.bodySM.font)
                    .foregroundStyle(palette.dimmed)
                Spacer(minLength: 0)
                footer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.md.value)
            .cardStyle()
            .contentShape(Rectangle())
        }
    }

    // MARK: - H4: Archival Memory Tip

    private var archivalTipSection: some View {
        let tip = HomeArchivalTips.tip(for: .now)
        return VStack(alignment: .leading, spacing: Space.sm.value) {
            HStack(spacing: Space.sm.value) {
                Image(systemName: "history_edu")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primary)
                    .frame(width: 32, height: 32)
                    .background(palette.surface, in: Circle())
                    .accessibilityHidden(true)
                Text("archivalTipLabel")
                    .font(CivicText.labelSM.font)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.primary)
            }
            Text(tip)
                .font(CivicText.headlineSM.font)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.md.value)
        .background(
            LinearGradient(
                colors: [palette.secondaryContainer.opacity(0.45), palette.primaryContainer.opacity(0.35)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
    }

    // MARK: - H5: Civics Fact of the Day

    private var civicsFactSection: some View {
        VStack(alignment: .leading, spacing: Space.sm.value) {
            HStack {
                Image(systemName: "local_library")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.secondary)
                    .accessibilityHidden(true)
                Text("civicsFactTitle")
                    .font(CivicText.labelMD.font)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.secondary)
            }

            // Mocked fact content (heading, body, tag). Not localized: these are placeholder strings
            // that will be replaced by real curated civics content.
            Text("July 4 & The 17-Day Draft")
                .font(CivicText.headlineMD.font)
                .foregroundStyle(palette.ink)
            Text("Did you know? Thomas Jefferson drafted the Declaration of Independence in just 17 days in a quiet rented lodging house at 7th & Market in Philadelphia.")
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.dimmed)

            HStack {
                Text("Item 2008-009 • In your active deck")
                    .font(CivicText.labelSM.font)
                    .foregroundStyle(palette.dimmed)
                    .padding(.horizontal, Space.sm.value)
                    .padding(.vertical, 4)
                    .background(palette.surfaceVariant, in: RoundedRectangle(cornerRadius: 8))

                Spacer()

                Button {
                    selectedTab = .study
                } label: {
                    HStack(spacing: Space.xs.value) {
                        Text("civicsReadBrief")
                        Image(systemName: "east")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .font(CivicText.labelMD.font.weight(.semibold))
                    .foregroundStyle(palette.primary)
                }
            }
        }
        .padding(Space.xl.value)
        .cardStyle()
    }
}

/// Static, mocked archival tips. One is picked deterministically by day-of-year so the tip is stable
/// within a day and rotates across the year without any state or network.
enum HomeArchivalTips {
    private static let tips = [
        "Form associations, not just rote memorization.",
        "Attach each fact to an image or story you'll still remember a year from now.",
        "Teach a fact out loud as if you were the officer asking it.",
        "Group related questions together — the test rewards connections.",
        "Return to the ones you keep missing; spacing beats cramming.",
    ]

    static func tip(for date: Date = .now, calendar: Calendar = .current) -> String {
        tips[calendar.component(.dayOfYear, from: date) % tips.count]
    }
}

struct RingGauge: View {
    let fraction: Double
    let text: String

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.onPrimary.opacity(0.2), lineWidth: 6)
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: max(0.0, min(1.0, fraction)))
                .stroke(palette.tertiary, style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(text)
                .font(CivicText.headlineSM.font.weight(.bold))
                .foregroundStyle(palette.onPrimary)
                .monospacedDigit()
        }
        .frame(width: 68, height: 68)
    }
}

#Preview {
    HomeDashboardView(
        configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ),
        selectedTab: .constant(.home)
    )
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
