import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @Query private var savedConfigurations: [SavedOnboardingConfiguration]

    let configuration: OnboardingConfiguration

    var body: some View {
        @Bindable var themeManager = themeManager

        List {
           Section("settingsAppearance") {
                 Picker("settingsTheme", selection: $themeManager.themeName) {
                     ForEach(AppThemeName.allCases) { theme in
                         Text(theme.displayName).tag(theme)
                     }
                 }
             }

             Section("settingsTestConfiguration") {
                 NavigationLink("settingsEditTestConfiguration") {
                     TestConfigurationView(configuration: configuration)
                 }
                  LabeledContent("settingsTestVersion", value: configuration.selectedTestVersion?.displayName ?? String(localized: "commonNotSet"))
                 LabeledContent(
                     "settingsFilingDate",
                     value: configuration.filingDate?.formatted(date: .abbreviated, time: .omitted) ?? String(localized: "commonNotSet")
                 )
                 LabeledContent(
                     "settingsStudyLanguage",
                     value: configuration.studyLanguage?.displayName ?? String(localized: "commonNotSet")
                 )
             }

            if configuration.isSixtyFiveTwentyEligible {
                 Section("65/20") {
                     LabeledContent("settingsSpecialConsideration", value: "settingsSpecialConsiderationValue")
                 }
             }

             Section("settingsPrivacy") {
                 Button("settingsResetLocalProgress", role: .destructive) {
                     resetProgress()
                 }
             }
         }
         .navigationTitle("settingsTitle")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
    }

    private func resetProgress() {
        for savedConfiguration in savedConfigurations {
            modelContext.delete(savedConfiguration)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView(configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self], inMemory: true)
}