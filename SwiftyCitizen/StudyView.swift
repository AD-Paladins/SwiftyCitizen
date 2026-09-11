import SwiftUI
import SwiftData

struct StudyView: View {
    let configuration: OnboardingConfiguration

    var body: some View {
        NavigationStack {
            if !bankAvailable {
                contentUnavailable
            } else {
                List {
                    Section("Study modes") {
                        NavigationLink {
                            FlashcardSessionView(configuration: configuration)
                        } label: {
                            Label("Flashcards", systemImage: "rectangle.stack")
                        }

                        NavigationLink {
                            TargetedReviewView(configuration: configuration)
                        } label: {
                            Label("Targeted review", systemImage: "target")
                        }
                    }
                }
                .navigationTitle("Study")
            }
        }
    }

    private var bankAvailable: Bool {
        guard let version = configuration.selectedTestVersion else { return false }
        return (try? QuestionBankLoader().load(version: version)) != nil
    }

    private var contentUnavailable: some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Content unavailable",
            message: "The question bank for your selected test version could not be loaded. Try updating the app or choosing another test version in Settings."
        )
        .navigationTitle("Study")
        .padding(24)
    }
}

#Preview {
    StudyView(configuration: OnboardingConfiguration(
        filingDate: Date(),
        selectedTestVersion: .twoThousandTwentyFive,
        isSixtyFiveTwentyEligible: false,
        studyLanguage: .english,
        disclaimerAccepted: true
    ))
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}