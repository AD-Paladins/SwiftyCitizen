import SwiftUI
import SwiftData

struct MockTestResultView: View {
    let configuration: OnboardingConfiguration
    let state: MockTestState
    let missedQuestions: [QuestionContent]
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                outcomeBadge

                VStack(spacing: 8) {
                    Text("\(state.correctCount) of \(state.maximumQuestionsAsked) correct")
                        .font(.title.bold())
                        .foregroundStyle(AppColor.ink)
                    Text("Passing score: \(state.passingScore)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !missedQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review missed questions")
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                        Text("\(missedQuestions.count) question(s) were answered incorrectly.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            FlashcardSessionView(
                                configuration: configuration,
                                mode: .targetedReview,
                                questions: missedQuestions
                            )
                        } label: {
                            Label("Review in targeted review", systemImage: "target")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(AppColor.amber)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("This simulation follows the official civics test rules but the app is a study aid, not an immigration authority. An officer's evaluation always decides the real interview.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                PrimaryActionButton(title: "Done", systemImage: "checkmark") {
                    onFinish()
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var outcomeBadge: some View {
        switch state.phase {
        case .complete(let outcome) where outcome == .passed:
            Label("Passed", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(AppColor.amber)
        case .complete(let outcome) where outcome == .failed:
            Label("Not passed", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.20))
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
                disclaimerAccepted: true
            ),
            state: .init(
                questions: [],
                maximumQuestionsAsked: 10,
                passingScore: 6
            ),
            missedQuestions: [],
            onFinish: {}
        )
    }
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}