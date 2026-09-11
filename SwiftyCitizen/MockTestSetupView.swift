import SwiftUI
import SwiftData

struct MockTestSetupView: View {
    let configuration: OnboardingConfiguration

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
                    NavigationLink {
                        MockTestSessionView(configuration: configuration, version: version)
                    } label: {
                        Label("Start mock test", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Mock test")
        .navigationBarTitleDisplayMode(.inline)
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
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}