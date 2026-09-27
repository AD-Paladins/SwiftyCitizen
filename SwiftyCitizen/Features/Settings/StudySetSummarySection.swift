import SwiftUI

struct StudySetSummarySection: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    private var testConfiguration: TestConfiguration? { configuration.testConfiguration }
    private var maximumQuestionsAsked: Int? { testConfiguration?.maximumQuestionsAsked }
    private var passingScore: Int? { testConfiguration?.passingScore }
    private var passingPercentage: Double? { testConfiguration?.passingPercentage }

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: Space.lg.value) {
                SettingsSectionHeader(title: "settingsStudySetHeader")

                if let maximumQuestionsAsked, let passingScore, let passingPercentage {
                    SettingsKeyValueRow(
                        label: "settingsQuestionsAsked",
                        value: "\(String(localized: "configQuestionsAskedPrefix"))\(maximumQuestionsAsked)"
                    )
                    SettingsKeyValueRow(
                        label: "settingsPassingScore",
                        value: "\(passingScore) \(String(localized: "configPassingScoreValueSuffix"))"
                    )
                    SettingsKeyValueRow(
                        label: "settingsPassingPercentage",
                        value: percentageLabel(passingPercentage)
                    )
                } else {
                    Text("settingsStudySetIncomplete")
                        .font(CivicText.bodyMD.font)
                        .foregroundStyle(palette.dimmed)
                }

                Text("settingsGavelDisclaimer")
                    .font(CivicText.bodyMD.font)
                    .foregroundStyle(palette.dimmed)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func percentageLabel(_ percentage: Double) -> String {
        let percent = Int(percentage.rounded())
        return "\(percent)%"
    }
}

#Preview {
    NavigationStack {
        StudySetSummarySection(
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

#Preview {
    NavigationStack {
        StudySetSummarySection(
            configuration: OnboardingConfiguration(
                filingDate: Date(timeIntervalSince1970: 1_600_000_000),
                selectedTestVersion: .twoThousandEight,
                isSixtyFiveTwentyEligible: false,
                studyLanguage: .spanish,
                disclaimerAccepted: true,
                shuffleQuestions: false
            )
        )
    }
    .environment(ThemeManager())
}
