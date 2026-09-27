import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @Query private var savedConfigurations: [SavedOnboardingConfiguration]

    let configuration: OnboardingConfiguration

    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.sm.value) {
                ConfigPreferencesSection(configuration: configuration)
                StudySetSummarySection(configuration: configuration)
                AppearanceSection()
                SettingsResetCard(onReset: { showResetConfirmation = true })
            }
            .padding(Space.lg.value)
        }
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
        .navigationTitle("settingsTitle")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            String(localized: "settingsResetDialogTitle"),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settingsResetDialogConfirm"), role: .destructive) {
                resetSpacedRepetition(modelContext)
            }
            Button(String(localized: "settingsResetDialogCancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "settingsResetDialogMessage"))
        }
    }
}

struct SettingsResetCard: View {
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    let onReset: () -> Void

    var body: some View {
        Button(action: onReset) {
            HStack(alignment: .center, spacing: Space.md.value) {
                Image(systemName: "restart.alt")
                    .foregroundStyle(palette.danger)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                VStack(alignment: .leading, spacing: Space.xs.value) {
                    Text("settingsResetLocalProgress")
                        .font(CivicText.headlineSM.font)
                        .foregroundStyle(palette.danger)
                    Text("settingsResetDialogMessage")
                        .font(CivicText.bodySM.font)
                        .foregroundStyle(palette.dimmed)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        SettingsView(configuration: OnboardingConfiguration(
            filingDate: Date(timeIntervalSince1970: 1_700_000_000),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, QuestionAttempt.self], inMemory: true)
}
