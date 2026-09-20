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

    private var gotItRate: Double? {
        StudyProgressMetrics.gotItRate(attempts: snapshots)
    }

    private var dueCount: Int {
        guard let testConfiguration = configuration.testConfiguration else { return 0 }
        return StudyProgressMetrics.dueCount(
            attempts: snapshots,
            configuration: testConfiguration
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ConfigurationSummaryView(configuration: configuration)

                    continueStudyingCard

                    todaySection

                    dueNextSection
                }
                .padding(24)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(configuration: configuration)
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .background(palette.canvas.ignoresSafeArea())
        }
    }

    private var continueStudyingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue studying")
                .font(.headline)
            Text("Review your current set and keep your streak going.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            PrimaryActionButton(title: "Start review", systemImage: "arrow.right") {
                selectedTab = .study
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
            if reviewedToday > 0 {
                HStack(spacing: 12) {
                    todayMetric(value: "\(reviewedToday)", label: "Reviewed")
                    todayMetric(value: gotItRateText, label: "Got it")
                }
            } else {
                EmptyStateView(
                    systemImage: "clock",
                    title: "No sessions yet",
                    message: "Start a review session to begin tracking today's progress."
                )
            }
        }
    }

    private var dueNextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Due next")
                .font(.headline)
            if dueCount > 0 {
                dueNextCard
            } else if reviewedToday > 0 {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "All caught up",
                    message: "You have reviewed every question in your test set."
                )
            } else {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "Nothing due yet",
                    message: "Due questions appear here once you have review history."
                )
            }
        }
    }

    private var dueNextCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(dueCount)")
                    .font(.title2.bold())
                    .foregroundStyle(palette.ink)
                Text("question\(dueCount == 1 ? "" : "s") to review")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding()
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = .study
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the Study tab")
    }

    private func todayMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(palette.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
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
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}