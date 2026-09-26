import SwiftUI
import SwiftData

struct PracticeView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        NavigationStack {
            List {
               Section("practiceTitle") {
                     NavigationLink {
                         MockTestSetupView(configuration: configuration)
                     } label: {
                         Label("practiceMockTest", systemImage: "checklist")
                     }

                     NavigationLink {
                         StudyEntryPointView(
                             title: "practiceOralPracticeTitle",
                             message: "practiceOralPracticeMessage",
                             systemImage: "mic"
                         )
                     } label: {
                         Label("practiceOralPracticeTitle", systemImage: "mic")
                     }
                 }
             }
             .navigationTitle("practiceTitle")
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