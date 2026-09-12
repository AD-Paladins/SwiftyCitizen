import SwiftUI
import SwiftData

struct MockTestSessionView: View {
    let configuration: OnboardingConfiguration
    let version: USCISTestVersion

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionFeedbackManager.self) private var sessionFeedbackManager

    @State private var state: MockTestState
    @State private var answer = ""
    @State private var session: StudySession?
    @State private var confirmsExit = false
    @State private var review: MockTestAnswer?

    init(configuration: OnboardingConfiguration, version: USCISTestVersion) {
        self.configuration = configuration
        self.version = version
        let testConfiguration = TestConfiguration.all.first { $0.version == version }!
        let bank = (try? QuestionBankLoader().load(version: version)) ?? []
        _state = State(initialValue: ExamEngine.makeState(
            from: bank,
            configuration: testConfiguration,
            shuffle: configuration.shuffleQuestions ? { $0.shuffled() } : { $0 }
        ))
    }

    var body: some View {
        Group {
            if state.questions.isEmpty {
                ScrollView {
                    EmptyStateView(
                        systemImage: "exclamationmark.triangle",
                        title: "Content unavailable",
                        message: "The question bank for \(version.displayName) is empty. Try updating the app or choosing another test version in Settings."
                    )
                    .padding(24)
                }
            } else if state.isComplete {
                   MockTestResultView(
                        configuration: configuration,
                        state: state,
                        missedQuestions: missedQuestions,
                        userAnswers: missedAnswers,
                        onFinish: { finishTest() }
                    )
            } else {
                SessionProgressHeader(
                    progressText: state.progressText,
                    onClose: { confirmsExit = true }
                )

                ScrollView {
                    VStack(spacing: 16) {
                        QuestionCard(question: state.currentQuestion!)

                        if let review = review {
                            SessionFeedbackIndicator(answer: review)
                        } else {
                            TextField("Type your answer", text: $answer, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .padding(20)
                                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }

                VStack(spacing: 0) {
                    Divider()
                    if review != nil {
                        PrimaryActionButton(
                            title: state.isComplete ? "See results" : "Next",
                            systemImage: state.isComplete ? "flag.checker" : "arrow.forward"
                        ) {
                            advance()
                        }
                    } else {
                        PrimaryActionButton(title: "Record answer", systemImage: "checkmark.circle.fill") {
                            submit()
                        }
                        .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    }
                }
                .padding(20)
                .padding(.bottom, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Mock test")
        .navigationBarTitleDisplayMode(.inline)
        .background(palette.canvas.ignoresSafeArea())
        .onAppear { beginSession() }
        .confirmationDialog(
            "End this test?",
            isPresented: $confirmsExit,
            titleVisibility: .visible
        ) {
            Button("End test", role: .destructive) {
                if state.answers.isEmpty {
                    if let session { modelContext.delete(session) }
                } else {
                    session?.endedAt = .now
                }
                try? modelContext.save()
                dismiss()
            }
            Button("Keep going", role: .cancel) {}
        }
    }

    private var missedQuestions: [QuestionContent] {
        let bank = (try? QuestionBankLoader().load(version: version)) ?? []
        let bankByID = Dictionary(uniqueKeysWithValues: bank.map { ($0.stableID, $0) })
        return state.answers
            .filter { !$0.isCorrect }
            .compactMap { bankByID[$0.questionStableID] }
    }

    private var missedAnswers: [String: String] {
        state.answers
            .filter { !$0.isCorrect }
            .reduce(into: [String: String]()) { acc, answer in
                acc[answer.questionStableID] = answer.response
            }
    }

    private func beginSession() {
        guard session == nil else { return }
        let newSession = StudySession(
            mode: .mockTest,
            testVersion: version,
            deckStableIDs: state.questions.map(\.stableID)
        )
        modelContext.insert(newSession)
        session = newSession
    }

    private func submit() {
        let response = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !response.isEmpty else { return }
        guard let recorded = state.record(response) else { answer = ""; return }
        recordAttempt(for: recorded)
        answer = ""

        if sessionFeedbackManager.isEnabled {
            review = recorded
        } else {
            advance()
        }
    }

    private func recordAttempt(for answerRecorded: MockTestAnswer) {
        let record = QuestionAttempt(
            questionStableID: answerRecorded.questionStableID,
            testVersion: version,
            answerText: answerRecorded.response,
            wasCorrect: answerRecorded.isCorrect,
            answeredAt: answerRecorded.answeredAt
        )
        session?.attempts.append(record)
        if case .complete = state.phase {
            session?.endedAt = .now
        }
        try? modelContext.save()
    }

    private func advance() {
        review = nil
        state.advance()
        session?.currentIndex = state.currentIndex
        answer = ""
    }

    private func finishTest() {
        session?.endedAt = .now
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MockTestSessionView(configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true
        ), version: .twoThousandTwentyFive)
    }
    .environment(ThemeManager())
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}