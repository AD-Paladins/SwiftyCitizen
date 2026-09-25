import SwiftUI
import SwiftData

struct PracticeView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        NavigationStack {
            List {
               Section("practice.title") {
                     NavigationLink {
                         MockTestSetupView(configuration: configuration)
                     } label: {
                         Label("practice.mockTest", systemImage: "checklist")
                     }

                     NavigationLink {
                         StudyEntryPointView(
                             title: "practice.oralPracticeTitle",
                             message: "practice.oralPracticeMessage",
                             systemImage: "mic"
                         )
                     } label: {
                         Label("practice.oralPracticeTitle", systemImage: "mic")
                     }
                 }
             }
             .navigationTitle("practice.title")
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