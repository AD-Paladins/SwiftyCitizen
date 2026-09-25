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
           Section("settings.appearance") {
                 Picker("settings.theme", selection: $themeManager.themeName) {
                     ForEach(AppThemeName.allCases) { theme in
                         Text(theme.displayName).tag(theme)
                     }
                 }
             }

             Section("settings.testConfiguration") {
                 NavigationLink("settings.editTestConfiguration") {
                     TestConfigurationView(configuration: configuration)
                 }
                  LabeledContent("settings.testVersion", value: configuration.selectedTestVersion?.displayName ?? String(localized: "common.notSet"))
                 LabeledContent(
                     "settings.filingDate",
                     value: configuration.filingDate?.formatted(date: .abbreviated, time: .omitted) ?? String(localized: "common.notSet")
                 )
                 LabeledContent(
                     "settings.studyLanguage",
                     value: configuration.studyLanguage?.displayName ?? String(localized: "common.notSet")
                 )
             }

            if configuration.isSixtyFiveTwentyEligible {
                 Section("65/20") {
                     LabeledContent("settings.specialConsideration", value: "settings.specialConsiderationValue")
                 }
             }

             Section("settings.privacy") {
                 Button("settings.resetLocalProgress", role: .destructive) {
                     resetProgress()
                 }
             }
         }
         .navigationTitle("settings.title")
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