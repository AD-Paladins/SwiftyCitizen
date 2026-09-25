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
                     Text("\(state.correctCount) \(String(localized: "common.of")) \(state.maximumQuestionsAsked) \(String(localized: "mocktest.result.correctAdjective"))")
                         .font(.title.bold())
                         .foregroundStyle(palette.ink)
                     Text("\(String(localized: "mocktest.result.passingScoreLabel"))\(state.passingScore)")
                         .font(.subheadline)
                         .foregroundStyle(palette.dimmed)
                 }

                if !missedQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                     Text("mocktest.result.reviewMissed")
                         .font(.headline)
                         .foregroundStyle(palette.ink)
                     let unit = missedQuestions.count == 1 ? String(localized: "mocktest.result.incorrectSingular") : String(localized: "mocktest.result.incorrectPlural")
                     Text("\(missedQuestions.count) \(unit)")
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
                             Label("mocktest.result.reviewInTargeted", systemImage: "target")
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
                     Text("mocktest.result.skippedDuringTest")
                         .font(.headline)
                         .foregroundStyle(palette.ink)
                     let unit = skippedQuestions.count == 1 ? String(localized: "mocktest.result.deferredSingular") : String(localized: "mocktest.result.deferredPlural")
                     Text("\(String(localized: "mocktest.result.deferredPrefix"))\(skippedQuestions.count) \(unit)")
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
                             Label("mocktest.result.reviewSkipped", systemImage: "target")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(palette.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

              Text("mocktest.result.disclaimer")
                     .font(.footnote)
                     .foregroundStyle(palette.dimmed)
                     .multilineTextAlignment(.center)

                 PrimaryActionButton(title: "mocktest.result.done", systemImage: "checkmark") {
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
             Label("mocktest.result.passed", systemImage: "checkmark.seal.fill")
                 .font(.headline)
                 .foregroundStyle(palette.success)
         case .complete(let outcome) where outcome == .failed:
             Label("mocktest.result.notPassed", systemImage: "xmark.circle.fill")
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