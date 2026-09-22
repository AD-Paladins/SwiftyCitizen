import SwiftUI
import SwiftData

struct TargetedReviewView: View {
    let configuration: OnboardingConfiguration

    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @Query private var sessions: [StudySession]
    @State private var selectedScope: ReviewScope = .due
    @State private var byCategory = false
    @State private var selectedCategories: Set<String> = []

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
            scope: scope,
            categories: byCategory ? selectedCategories : []
        )
    }

    private func deck(for scope: ReviewScope) -> [QuestionContent] {
        ReviewDeckBuilder.build(
            questions: bankQuestions,
            attempts: snapshots,
            scope: scope,
            categories: byCategory ? selectedCategories : []
        )
    }

    private var categorySummary: CategorySummary {
        ReviewDeckBuilder.categorySummary(
            questions: bankQuestions,
            attempts: snapshots,
            scope: selectedScope
        )
    }

    private func toggleCategory(_ topic: String) {
        if selectedCategories.contains(topic) {
            selectedCategories.remove(topic)
        } else {
            selectedCategories.insert(topic)
        }
    }

    var body: some View {
        List {
            if let resumeSession {
                Section("In progress") {
                    resumeRow(session: resumeSession)
                }
            }

            Section("By category") {
                Toggle("Show categories", isOn: $byCategory)
                if byCategory {
                    ForEach(categorySummary.topics, id: \.self) { topic in
                        Button {
                            toggleCategory(topic)
                        } label: {
                            HStack {
                                Label(
                                    "\(topic) (\(categorySummary.counts[topic] ?? 0))",
                                    systemImage: selectedCategories.contains(topic) ? "checkmark.circle.fill" : "circle"
                                )
                                Spacer()
                            }
                            .foregroundStyle(selectedCategories.contains(topic) ? palette.primary : palette.dimmed)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedCategories.contains(topic) ? .isSelected : [])
                    }
                }
            }

            Section {
                ForEach(ReviewScope.allCases) { scope in
                    scopeRow(scope)
                }
            } header: {
                Text("Review scope")
            } footer: {
                if count(for: selectedScope) == 0 {
                    Text("No questions in this scope yet. As you study, questions move into this review list.")
                }
            }
        }
        .navigationTitle("Targeted review")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
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
                .tint(palette.primary)
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
                    .foregroundStyle(palette.dimmed)
            }
        }
    }

    private func scopeRow(_ scope: ReviewScope) -> some View {
        let isSelected = selectedScope == scope
        return Button {
            selectedScope = scope
        } label: {
            HStack {
                Label(scope.displayName, systemImage: scope.systemImage)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.primary)
                        .accessibilityHidden(true)
                }
                Text("\(count(for: scope))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(palette.dimmed)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? palette.surface : Color.clear)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        TargetedReviewView(configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true,
            shuffleQuestions: false
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}