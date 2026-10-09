import SwiftUI
import SwiftData

enum StudyRoute: Hashable {
    case flashcards
    case targetedReview
}

struct StudyView: View {
    let configuration: OnboardingConfiguration

    @Environment(ThemeManager.self) private var themeManager
    @Environment(PendingNavigation.self) private var pendingNavigation
    private var palette: AppPalette { themeManager.palette }
    @State private var path: [StudyRoute] = []

    @Query private var sessions: [StudySession]
    @Query private var bookmarks: [Bookmark]

    private var bankQuestions: [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private var snapshots: [StudyAttemptSnapshot] {
        sessions.flatMap(\.attempts).compactMap(\.snapshot)
    }

    private var bookmarkedStableIDs: Set<String> {
        guard let raw = configuration.selectedTestVersion?.rawValue else { return [] }
        return Set(bookmarks.filter { $0.testVersionRawValue == raw }.map(\.questionStableID))
    }

    /// Spaced-repetition DUE count surfaced by the Study tab: unseen first, then most-overdue.
    /// Pure + static so it can be unit-tested without rendering the view.
    static func dueCount(questions: [QuestionContent], attempts: [StudyAttemptSnapshot], bookmarkedIDs: Set<String>) -> Int {
        ReviewDeckBuilder.questionCount(
            questions: questions,
            attempts: attempts,
            scope: .due,
            categories: [],
            bookmarkedIDs: bookmarkedIDs
        )
    }

    /// Scheduler-driven due count for the active test version. Mirrors TargetedReviewView's `.due`
    /// scope; this is NOT the coverage-based `StudyProgressMetrics.dueCount` Home shows as "Due next".
    private var dueCount: Int {
        Self.dueCount(questions: bankQuestions, attempts: snapshots, bookmarkedIDs: bookmarkedStableIDs)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if !bankAvailable {
                    contentUnavailable
                } else {
                    studyModes
                }
            }
            .navigationDestination(for: StudyRoute.self) { route in
                switch route {
                case .flashcards:
                    FlashcardSessionView(configuration: configuration)
                case .targetedReview:
                    TargetedReviewView(configuration: configuration)
                }
            }
            .navigationTitle("studyTitle")
        }
        // Home/Progress record the scope (or topic) they want to land on; turn that into a push here.
        // onAppear covers a freshly loaded Study tab; onChange covers a cached one.
        .onAppear {
            if (pendingNavigation.reviewScope != nil || pendingNavigation.scopedTopic != nil), !path.contains(.targetedReview) {
                path.append(.targetedReview)
            }
        }
        .onChange(of: pendingNavigation.reviewScope) { _, scope in
            if scope != nil, !path.contains(.targetedReview) {
                path.append(.targetedReview)
            }
        }
        .onChange(of: pendingNavigation.scopedTopic) { _, topic in
            if topic != nil, !path.contains(.targetedReview) {
                path.append(.targetedReview)
            }
        }
    }

    private var studyModes: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.md.value) {
                header

                if dueCount > 0 {
                    NavigationLink(value: StudyRoute.targetedReview) {
                        Label("\(String(localized: "studyContinueDue")) \(dueCount) \(String(localized: "studyDueLabel"))", systemImage: "book.fill")
                            .font(CivicText.headlineSM.font)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(palette.primary)
                    .padding(.top, Space.xs.value)
                }

                StudyEntryCard(
                    title: "studyFlashcardsEntryTitle",
                    subtitle: "studyFlashcardsEntrySubtitle",
                    systemImage: "rectangle.stack.fill",
                    actionLabel: "studyFlashcardsEntryAction",
                    iconBackground: palette.primary.opacity(0.12),
                    iconForeground: palette.primary,
                    actionTint: palette.primary,
                    value: StudyRoute.flashcards
                )

                StudyEntryCard(
                    title: "studyTargetedReviewEntryTitle",
                    subtitle: "studyTargetedReviewEntrySubtitle",
                    systemImage: "target",
                    actionLabel: "studyTargetedReviewEntryAction",
                    iconBackground: palette.warning.opacity(0.14),
                    iconForeground: palette.warning,
                    actionTint: palette.warning,
                    value: StudyRoute.targetedReview,
                    badge: Text("\(dueCount) \(String(localized: "studyDueLabel"))")
                )
            }
            .padding(Space.lg.value)
        }
        .scrollContentBackground(.hidden)
        .background(palette.canvas.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
             Text("studyTitle")
                 .font(CivicText.headlineMD.font)
                 .foregroundStyle(palette.ink)
             Text("studyHeaderSubtitle")
                 .font(CivicText.bodySM.font)
                 .foregroundStyle(palette.dimmed)
         }
    }

    private var bankAvailable: Bool {
        guard let version = configuration.selectedTestVersion else { return false }
        return (try? QuestionBankLoader().load(version: version)) != nil
    }

    private var contentUnavailable: some View {
        ScrollView {
            EmptyStateView(
                systemImage: "exclamationmark.triangle",
                title: "studyContentUnavailable",
                message: "studyContentUnavailableMessage"
            )
            .padding(24)
        }
        .background(palette.canvas.ignoresSafeArea())
    }
}

#Preview {
    StudyView(configuration: OnboardingConfiguration(
        filingDate: Date(),
        selectedTestVersion: .twoThousandTwentyFive,
        isSixtyFiveTwentyEligible: false,
        studyLanguage: .english,
        disclaimerAccepted: true,
        shuffleQuestions: false
    ))
    .environment(ThemeManager())
    .environment(SessionActivityCoordinator())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
