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
        // Home records the scope it wants to land on; turn that into a push here.
        // onAppear covers a freshly loaded Study tab; onChange covers a cached one.
        .onAppear {
            if pendingNavigation.reviewScope != nil, !path.contains(.targetedReview) {
                path.append(.targetedReview)
            }
        }
        .onChange(of: pendingNavigation.reviewScope) { _, scope in
            if scope != nil, !path.contains(.targetedReview) {
                path.append(.targetedReview)
            }
        }
    }

    private var studyModes: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.md.value) {
                header

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
                    value: StudyRoute.targetedReview
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
