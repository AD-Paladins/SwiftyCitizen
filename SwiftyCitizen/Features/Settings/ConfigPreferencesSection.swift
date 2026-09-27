import SwiftUI

struct ConfigPreferencesSection: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    private var summaryValue: String {
        let version = configuration.selectedTestVersion?.displayName ?? String(localized: "commonNotSet")
        let filing = configuration.filingDate?.formatted(date: .abbreviated, time: .omitted) ?? String(localized: "commonNotSet")
        let language = configuration.studyLanguage?.displayName ?? String(localized: "commonNotSet")
        return "\(version) · \(filing) · \(language)"
    }

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: Space.lg.value) {
                NavigationLink(destination: {
                    TestConfigurationView(configuration: configuration)
                }) {
                    HStack(spacing: Space.md.value) {
                        SettingsKeyValueRow(label: "settingsTestConfiguration", value: LocalizedStringKey(summaryValue))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.dimmed)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConfigPreferencesSection(
            configuration: OnboardingConfiguration(
                filingDate: Date(timeIntervalSince1970: 1_700_000_000),
                selectedTestVersion: .twoThousandTwentyFive,
                isSixtyFiveTwentyEligible: false,
                studyLanguage: .english,
                disclaimerAccepted: true,
                shuffleQuestions: false
            )
        )
    }
    .environment(ThemeManager())
}
