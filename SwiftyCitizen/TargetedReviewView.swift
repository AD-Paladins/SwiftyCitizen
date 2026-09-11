import SwiftUI
import SwiftData

struct TargetedReviewView: View {
    let configuration: OnboardingConfiguration

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [StudySession]
    @State private var selectedScope: ReviewScope = .due

    private var bankQuestions: [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private var snapshots: [StudyAttemptSnapshot] {
        sessions.flatMap(\.attempts).compactMap(\.snapshot)
    }

    private var resumeSession: StudySession? {
        sessions.first {
            $0.mode == .targetedReview && !$0.isComplete && $0.answeredCount > 0
        }
    }

    private func count(for scope: ReviewScope) -> Int {
        ReviewDeckBuilder.questionCount(
            questions: bankQuestions,
            attempts: snapshots,
            scope: scope
        )
    }

    private func deck(for scope: ReviewScope) -> [QuestionContent] {
        ReviewDeckBuilder.build(
            questions: bankQuestions,
            attempts: snapshots,
            scope: scope
        )
    }

    var body: some View {
        List {
            if let resumeSession {
                Section("In progress") {
                    resumeRow(session: resumeSession)
                }
            }

            Section("Review scope") {
                ForEach(ReviewScope.allCases) { scope in
                    scopeRow(scope)
                }
            }
        }
        .navigationTitle("Targeted review")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if count(for: selectedScope) > 0 {
                NavigationLink {
                    FlashcardSessionView(
                        configuration: configuration,
                        mode: .targetedReview,
                        questions: deck(for: selectedScope)
                    )
                } label: {
                    Label("Start review (\(count(for: selectedScope)))", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppColor.amber)
                .padding(20)
            }
        }
    }

    private func resumeRow(session: StudySession) -> some View {
        NavigationLink {
            FlashcardSessionView(
                configuration: configuration,
                mode: .targetedReview,
                questions: bankQuestions,
                resumeSession: session
            )
        } label: {
            HStack {
                Label("Resume session", systemImage: "play.circle.fill")
                Spacer()
                Text("\(min(session.currentIndex, session.deckStableIDs.count)) of \(session.deckStableIDs.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func scopeRow(_ scope: ReviewScope) -> some View {
        Button {
            selectedScope = scope
        } label: {
            HStack {
                Label(scope.displayName, systemImage: scope.systemImage)
                Spacer()
                Text("\(count(for: scope))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedScope == scope ? AppColor.surface : Color.clear)
        .accessibilityAddTraits(selectedScope == scope ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        TargetedReviewView(configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true
        ))
    }
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}