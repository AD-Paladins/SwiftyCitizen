import SwiftUI
import SwiftData

struct PracticeView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        NavigationStack {
            List {
                Section("Practice") {
                    NavigationLink {
                        MockTestSetupView(configuration: configuration)
                    } label: {
                        Label("Mock test", systemImage: "checklist")
                    }

                    NavigationLink {
                        StudyEntryPointView(
                            title: "Oral practice",
                            message: "Practice answering aloud without exam pressure. Planned for a later phase.",
                            systemImage: "mic"
                        )
                    } label: {
                        Label("Oral practice", systemImage: "mic")
                    }
                }
            }
            .navigationTitle("Practice")
            .scrollContentBackground(.hidden)
            .background(palette.canvas.ignoresSafeArea())
        }
    }
}

#Preview {
    PracticeView(configuration: OnboardingConfiguration(
        filingDate: Date(),
        selectedTestVersion: .twoThousandTwentyFive,
        isSixtyFiveTwentyEligible: false,
        studyLanguage: .english,
        disclaimerAccepted: true,
        shuffleQuestions: false
    ))
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}