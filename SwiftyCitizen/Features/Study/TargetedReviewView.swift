import SwiftUI
import SwiftData

struct TargetedReviewView: View {
    let configuration: OnboardingConfiguration

    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PendingNavigation.self) private var pendingNavigation
    private var palette: AppPalette { themeManager.palette }
    @Query private var sessions: [StudySession]
    @Query private var bookmarks: [Bookmark]
    @State private var selectedScope: ReviewScope = .due
    @State private var byCategory = false
    @State private var selectedCategories: Set<String> = []

    /// Direct review entry (session summary): open straight at the low-accuracy set of `weakCards`.
    /// Default (`[]`) keeps the existing PendingNavigation deep-link behavior untouched.
    init(configuration: OnboardingConfiguration, weakCards: Set<String> = []) {
        self.configuration = configuration
        self._weakCards = State(initialValue: weakCards)
    }

    private var bankQuestions: [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private var snapshots: [StudyAttemptSnapshot] {
        sessions.flatMap(\.attempts).compactMap(\.snapshot)
    }

    /// Stable IDs of bookmarked questions for the active test version. The view owns
    /// version scoping (SwiftData query); the pure builder only filters by membership.
    private var bookmarkedStableIDs: Set<String> {
        guard let raw = configuration.selectedTestVersion?.rawValue else { return [] }
        return Set(bookmarks.filter { $0.testVersionRawValue == raw }.map(\.questionStableID))
    }

    /// Categories the deck is filtered by. A scoped topic (from Progress's coverage map) wins
    /// over the manual category selection; otherwise it follows the on-screen toggle.
    private var activeCategories: Set<String> {
        if let scopedTopic = pendingNavigation.scopedTopic { return [scopedTopic] }
        return byCategory ? selectedCategories : []
    }

    /// Exact weak-card stable IDs passed in for a direct review entry (the session summary),
    /// overriding the pending-navigation scope when non-empty; otherwise the Progress-requested set.
    @State private var weakCards: Set<String> = []

    /// The low-accuracy stable IDs to review: an explicit entry set wins, else the pending scope.
    private var pendingWeakStableIDs: Set<String> {
        weakCards.isEmpty ? (pendingNavigation.weakStableIDs ?? []) : weakCards
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
            categories: activeCategories,
            bookmarkedIDs: bookmarkedStableIDs,
            weakStableIDs: pendingWeakStableIDs
        )
    }

    private func deck(for scope: ReviewScope) -> [QuestionContent] {
        ReviewDeckBuilder.build(
            questions: bankQuestions,
            attempts: snapshots,
            scope: scope,
            categories: activeCategories,
            bookmarkedIDs: bookmarkedStableIDs,
            weakStableIDs: pendingWeakStableIDs
        )
    }

    private var categorySummary: CategorySummary {
        ReviewDeckBuilder.categorySummary(
            questions: bankQuestions,
            attempts: snapshots,
            scope: selectedScope,
            bookmarkedIDs: bookmarkedStableIDs,
            weakStableIDs: pendingWeakStableIDs
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
                 Section("studyTargetedInProgressSection") {
                     resumeRow(session: resumeSession)
                 }
             }

             Section("studyTargetedByCategorySection") {
                 Toggle("studyTargetedShowCategories", isOn: $byCategory)
                if byCategory {
                    ForEach(categorySummary.topics, id: \.self) { topic in
                        Button {
                            toggleCategory(topic)
                        } label: {
                            HStack {
                            Label(
                                     "\(topic) \(String(localized: "studyTargetedCountOpen"))\(categorySummary.counts[topic] ?? 0)\(String(localized: "studyTargetedCountClose"))",
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
                 Text("studyTargetedReviewScopeHeader")
             } footer: {
                 if count(for: selectedScope) == 0 {
                     Text("studyTargetedNoQuestionsInScope")
                 }
             }
        }
        .navigationTitle("studyTargetedTitle")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
        // Home/Progress may request a specific scope (Bookmarked) or topic; open it and clear.
        .onAppear {
            // A direct review entry (session summary) opens straight at the low-accuracy set; the
            // Progress deep link still selects its scope via pendingNavigation.
            if !weakCards.isEmpty {
                selectedScope = .lowAccuracy
            } else if let scope = pendingNavigation.reviewScope {
                selectedScope = scope
            }
            if let scopedTopic = pendingNavigation.scopedTopic {
                byCategory = true
                selectedCategories = [scopedTopic]
                selectedScope = .due
            }
            pendingNavigation.clear()
        }
        .safeAreaInset(edge: .bottom) {
            if count(for: selectedScope) > 0 {
                NavigationLink {
                    FlashcardSessionView(
                        configuration: configuration,
                        mode: .targetedReview,
                        questions: deck(for: selectedScope)
                    )
                } label: {
                    Label("\(String(localized: "studyTargetedStartReviewPrefix"))\(count(for: selectedScope))\(String(localized: "studyTargetedStartReviewSuffix"))", systemImage: "arrow.right")
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
                Label("studyTargetedResumeSession", systemImage: "play.circle.fill")
                 Spacer()
                 Text("\(min(session.currentIndex, session.deckStableIDs.count)) \(String(localized: "commonOf")) \(session.deckStableIDs.count)")
                     .font(.subheadline.monospacedDigit())
                     .foregroundStyle(palette.dimmed)
            }
        }
    }

    private func scopeRow(_ scope: ReviewScope) -> some View {
        let isSelected = selectedScope == scope
        return HStack(spacing: 12) {
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
        .onTapGesture { selectedScope = scope }
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
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
