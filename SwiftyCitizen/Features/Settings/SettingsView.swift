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
        List {
            ConfigPreferencesSection(configuration: configuration)

            StudySetSummarySection(configuration: configuration)

            AppearanceSection()

            Section("settingsDataSection") {
                Button("settingsResetLocalProgress", role: .destructive) {
                    showResetConfirmation = true
                }
            }
        }
        .navigationTitle("settingsTitle")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
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
