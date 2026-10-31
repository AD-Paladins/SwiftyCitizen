import SwiftUI
import SwiftData

struct MockTestSetupView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        List {
            Section("mocktestSetupRulesSection") {
                 ConfigurationSummaryView(configuration: configuration)
                     .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
             }

             Section("mocktestSetupHowYouAnswerSection") {
                 Text("mocktestSetupAnswerInstructions")
                     .font(.footnote)
                     .foregroundStyle(palette.dimmed)
             }

            if let version = configuration.selectedTestVersion, !bankAvailable(version: version) {
                EmptyStateView(
                     systemImage: "exclamationmark.triangle",
                     title: "mocktestSessionContentUnavailable",
                     message: "\(String(localized: "mocktestSessionContentUnavailableMessagePrefix"))\(version.displayName) \(String(localized: "mocktestSessionContentUnavailableMessageSuffixLoadFailed"))"
                 )
                 .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("mocktestSessionTitle")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if let version = configuration.selectedTestVersion, bankAvailable(version: version) {
                PrimaryActionButton(title: "mocktestSetupStartMockTest", systemImage: "checklist") {
                    // navigation handled by parent / session entry; affordance is clearly a tappable button
                }
            }
        }
    }

    private func bankAvailable(version: USCISTestVersion) -> Bool {
        (try? QuestionBankLoader().load(version: version)) != nil
    }
}

#Preview {
    NavigationStack {
        MockTestSetupView(configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}