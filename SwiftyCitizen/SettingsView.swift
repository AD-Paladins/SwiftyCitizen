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
            Section("Appearance") {
                Picker("Theme", selection: $themeManager.themeName) {
                    ForEach(AppThemeName.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }

            Section("Test configuration") {
                NavigationLink("Edit test configuration") {
                    TestConfigurationView(configuration: configuration)
                }
                LabeledContent("Test version", value: configuration.selectedTestVersion?.displayName ?? "Not set")
                LabeledContent(
                    "Filing date",
                    value: configuration.filingDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"
                )
                LabeledContent(
                    "Study language",
                    value: configuration.studyLanguage?.displayName ?? "Not set"
                )
            }

            if configuration.isSixtyFiveTwentyEligible {
                Section("65/20") {
                    LabeledContent("Special consideration", value: "Age 65+, residency 20+ years")
                }
            }

            Section("Privacy") {
                Button("Reset local progress", role: .destructive) {
                    resetProgress()
                }
            }
        }
        .navigationTitle("Settings")
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
            studyLanguage: .spanish,
            disclaimerAccepted: true
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self], inMemory: true)
}