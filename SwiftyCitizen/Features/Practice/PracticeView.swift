import SwiftUI
import SwiftData

enum PracticeRoute: Hashable {
    case mockTest
    case oralPractice
}

struct PracticeView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @State private var path: [PracticeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.md.value) {
                    header

                    StudyEntryCard(
                        title: "practiceMockTest",
                        subtitle: "practiceMockTestSubtitle",
                        systemImage: "checklist",
                        actionLabel: "practiceMockTestEntryAction",
                        iconBackground: palette.primary.opacity(0.12),
                        iconForeground: palette.primary,
                        actionTint: palette.primary,
                        value: PracticeRoute.mockTest
                    )

                    StudyEntryCard(
                        title: "practiceOralPracticeTitle",
                        subtitle: "practiceOralPracticeMessage",
                        systemImage: "mic",
                        actionLabel: "practiceOralPracticeEntryAction",
                        iconBackground: palette.warning.opacity(0.14),
                        iconForeground: palette.warning,
                        actionTint: palette.warning,
                        value: PracticeRoute.oralPractice
                    )
                }
                .padding(Space.lg.value)
            }
            .scrollContentBackground(.hidden)
            .background(palette.canvas.ignoresSafeArea())
            .navigationTitle("practiceTitle")
            .navigationDestination(for: PracticeRoute.self) { route in
                switch route {
                case .mockTest:
                    MockTestSetupView(configuration: configuration)
                case .oralPractice:
                    StudyEntryPointView(
                        title: "practiceOralPracticeTitle",
                        message: "practiceOralPracticeMessage",
                        systemImage: "mic"
                    )
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            Text("practiceTitle")
                .font(CivicText.headlineMD.font)
                .foregroundStyle(palette.ink)
            Text("practiceHeaderSubtitle")
                .font(CivicText.bodySM.font)
                .foregroundStyle(palette.dimmed)
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
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
