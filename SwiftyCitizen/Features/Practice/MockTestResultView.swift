import SwiftUI
import SwiftData

struct MockTestResultView: View {
    let configuration: OnboardingConfiguration
    let state: MockTestState
    let missedQuestions: [QuestionContent]
    let userAnswers: [String: String]
    let onFinish: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                outcomeBadge

                VStack(spacing: 8) {
                    Text("\(state.correctCount) of \(state.maximumQuestionsAsked) correct")
                        .font(.title.bold())
                        .foregroundStyle(palette.ink)
                    Text("Passing score: \(state.passingScore)")
                        .font(.subheadline)
                        .foregroundStyle(palette.dimmed)
                }

                if !missedQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review missed questions")
                            .font(.headline)
                            .foregroundStyle(palette.ink)
                        Text("\(missedQuestions.count) question(s) were answered incorrectly.")
                            .font(.footnote)
                            .foregroundStyle(palette.dimmed)

                        NavigationLink {
                            FlashcardSessionView(
                                configuration: configuration,
                                mode: .targetedReview,
                                questions: missedQuestions,
                                userAnswers: userAnswers
                            )
                        } label: {
                            Label("Review in targeted review", systemImage: "target")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(palette.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !skippedQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skipped during the test")
                            .font(.headline)
                            .foregroundStyle(palette.ink)
                        Text("You deferred \(skippedQuestions.count) question(s). Review them here.")
                            .font(.footnote)
                            .foregroundStyle(palette.dimmed)

                        NavigationLink {
                            FlashcardSessionView(
                                configuration: configuration,
                                mode: .targetedReview,
                                questions: skippedQuestions,
                                userAnswers: userAnswers
                            )
                        } label: {
                            Label("Review skipped questions", systemImage: "target")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(palette.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("This simulation follows the official civics test rules but the app is a study aid, not an immigration authority. An officer's evaluation always decides the real interview.")
                    .font(.footnote)
                    .foregroundStyle(palette.dimmed)
                    .multilineTextAlignment(.center)

                PrimaryActionButton(title: "Done", systemImage: "checkmark") {
                    onFinish()
                }
            }
            .padding(20)
        }
        .background(palette.canvas.ignoresSafeArea())
    }

    private var skippedQuestions: [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
        let bank = (try? QuestionBankLoader().load(version: version)) ?? []
        let bankByID = Dictionary(uniqueKeysWithValues: bank.map { ($0.stableID, $0) })
        return state.skippedIDs.compactMap { bankByID[$0] }
    }

    @ViewBuilder
    private var outcomeBadge: some View {
        switch state.phase {
        case .complete(let outcome) where outcome == .passed:
            Label("Passed", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(palette.success)
        case .complete(let outcome) where outcome == .failed:
            Label("Not passed", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(palette.danger)
        default:
            Text("—")
        }
    }
}

#Preview {
    NavigationStack {
        MockTestResultView(
            configuration: OnboardingConfiguration(
                filingDate: Date(),
                selectedTestVersion: .twoThousandTwentyFive,
                isSixtyFiveTwentyEligible: false,
                studyLanguage: .english,
                disclaimerAccepted: true,
                shuffleQuestions: false
            ),
            state: .init(
                questions: [],
                maximumQuestionsAsked: 10,
                passingScore: 6
            ),
            missedQuestions: [],
             userAnswers: [:],
             onFinish: {}
        )
    }
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}