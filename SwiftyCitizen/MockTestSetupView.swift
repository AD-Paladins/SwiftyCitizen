import SwiftUI
import SwiftData

struct MockTestSetupView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        List {
            Section("Rules for this session") {
                ConfigurationSummaryView(configuration: configuration)
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }

            Section("How you answer") {
                LabeledContent("Mode", value: "Manual")
                Text("Type your answer aloud-style. The app compares it against the official answers for that question.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                if let version = configuration.selectedTestVersion {
                    if bankAvailable(version: version) {
                        NavigationLink {
                            MockTestSessionView(configuration: configuration, version: version)
                        } label: {
                            Label("Start mock test", systemImage: "checklist")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowBackground(Color.clear)
                    } else {
                        EmptyStateView(
                            systemImage: "exclamationmark.triangle",
                            title: "Content unavailable",
                            message: "The question bank for \(version.displayName) could not be loaded. Try updating the app or choosing another test version in Settings."
                        )
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .navigationTitle("Mock test")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
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
            studyLanguage: .english,
            disclaimerAccepted: true
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}