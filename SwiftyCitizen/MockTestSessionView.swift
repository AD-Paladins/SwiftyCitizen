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
    @State private var selectedOptionIndexes: [Int] = []
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
                        } else if currentQuestionMode == .text {
                            TextField("Type your answer", text: $answer, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .padding(20)
                                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                        } else {
                            let variants = state.currentQuestion!.acceptedAnswerVariants
                            VStack(spacing: 12) {
                                ForEach(variants.indices, id: \.self) { index in
                                    SelectionTile(
                                        text: variants[index],
                                        isSelected: selectedOptionIndexes.contains(index)
                                    ) { tileToggled(index) }
                                }
                            }
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
                        .disabled(!isSubmitEnabled)
                        .opacity(isSubmitEnabled ? 1 : 0.5)
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

    private var currentQuestionMode: QuestionContent.AnswerInputMode {
        state.currentQuestion?.answerInputMode ?? .text
    }

    private var requiredAnswerCount: Int {
        if case .exactly(let value) = state.currentQuestion?.answerCardinality {
            return value
        }
        return 1
    }

    private var answerText: String {
        if currentQuestionMode == .text {
            return answer
        }
        let variants = state.currentQuestion!.acceptedAnswerVariants
        let chosen = selectedOptionIndexes.compactMap { index in
            index >= 0 && index < variants.count ? variants[index] : nil
        }
        return chosen.joined(separator: " ")
    }

    private var isSubmitEnabled: Bool {
        guard state.currentQuestion != nil else { return false }
        if currentQuestionMode == .text {
            return !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return selectedOptionIndexes.count == requiredAnswerCount
    }

    private func tileToggled(_ index: Int) {
        guard state.currentQuestion != nil else { return }
        let required = requiredAnswerCount
        if required == 1 {
            selectedOptionIndexes = [index]
            return
        }
        if selectedOptionIndexes.contains(index) {
            selectedOptionIndexes.removeAll { $0 == index }
        } else if selectedOptionIndexes.count < required {
            selectedOptionIndexes.append(index)
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
        let response = answerText
        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let recorded = state.record(response) else {
            selectedOptionIndexes = []
            answer = ""
            return
        }
        recordAttempt(for: recorded)
        selectedOptionIndexes = []
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
        selectedOptionIndexes = []
    }

    private func finishTest() {
        session?.endedAt = .now
        try? modelContext.save()
        dismiss()
    }
}
