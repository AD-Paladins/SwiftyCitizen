import SwiftUI
import SwiftData

struct MockTestSessionView: View {
    let configuration: OnboardingConfiguration
    let version: USCISTestVersion
    let bank: [QuestionContent]

    @Environment(ThemeManager.self) private var themeManager
    @Environment(SessionActivityCoordinator.self) private var sessionCoordinator
    private var palette: AppPalette { themeManager.palette }
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var state: MockTestState
    @State private var answer = ""
    @State private var selectedOptionIndexes: [Int] = []
    @State private var session: StudySession?
    @State private var confirmsExit = false
    @State private var review: MockTestAnswer?
    @State private var showOfficialAnswer = false

    init(configuration: OnboardingConfiguration, version: USCISTestVersion) {
        self.configuration = configuration
        self.version = version
        self.bank = (try? QuestionBankLoader().load(version: version)) ?? []
        let testConfiguration = TestConfiguration.all.first { $0.version == version }!
        _state = State(initialValue: MockTestState(
            questions: selectQuestions(from: bank, maximum: testConfiguration.maximumQuestionsAsked, shuffleEnabled: configuration.shuffleQuestions),
            maximumQuestionsAsked: testConfiguration.maximumQuestionsAsked,
            passingScore: testConfiguration.passingScore
        ))
    }

    var body: some View {
        Group {
            if state.questions.isEmpty {
                ScrollView {
                   EmptyStateView(
                         systemImage: "exclamationmark.triangle",
                         title: "mocktestSessionContentUnavailable",
                         message: "\(String(localized: "mocktestSessionContentUnavailableMessagePrefix"))\(version.displayName) \(String(localized: "mocktestSessionContentUnavailableMessageSuffixEmpty"))"
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
                ProgressView(value: progressFraction)
                    .progressViewStyle(.linear)
                    .tint(palette.primary)
                    .accessibilityLabel("studyFlashcardHeaderProgress")

                SessionProgressHeader(
                    progressText: state.progressText,
                    onClose: { confirmsExit = true }
                )

                ScrollView {
                    VStack(spacing: 16) {
                        QuestionCard(question: state.currentQuestion!)

                        if let review = review {
                            VStack(alignment: .leading, spacing: 12) {
                                SessionFeedbackIndicator(answer: review)
                                if review.needsOfficialAnswerReveal, let question = state.currentQuestion {
                                    revealButton(question: question)
                                    if showOfficialAnswer {
                                        AcceptedAnswerCard(question: question)
                                    }
                                }
                                if !review.isCorrect {
                                    skipButton
                                }
                            }
                        } else if currentQuestionMode == .text {
                            TextField("mocktestSessionTypeAnswer", text: $answer, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .padding(20)
                                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
                        } else {
                            let options = currentTileOptions
                            VStack(spacing: 12) {
                                ForEach(options.indices, id: \.self) { index in
                                    SelectionTile(
                                        text: options[index],
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
                             title: state.isComplete ? "mocktestSessionSeeResults" : "mocktestSessionNext",
                             systemImage: state.isComplete ? "flag.checker" : "arrow.forward"
                         ) {
                             advance()
                         }
                     } else {
                         PrimaryActionButton(title: "mocktestSessionRecordAnswer", systemImage: "checkmark.circle.fill") {
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
      .navigationTitle("mocktestSessionTitle")
        .navigationBarTitleDisplayMode(.inline)
        .background(palette.canvas.ignoresSafeArea())
        .onAppear {
            beginSession()
            sessionCoordinator.setActive(true)
        }
        // F4: when the tab-switch guard ends this session, dismiss it here.
        .onChange(of: sessionCoordinator.isActive) { _, active in
            if !active { endMockTest() }
        }
        .onDisappear {
            if let session, session.endedAt == nil {
                endMockTest()
            }
            sessionCoordinator.setActive(false)
        }
        .confirmationDialog(
             "mocktestSessionEndTestConfirm",
             isPresented: $confirmsExit,
             titleVisibility: .visible
         ) {
             Button("mocktestSessionEndTest", role: .destructive) {
                 endMockTest()
             }
             Button("mocktestSessionKeepGoing", role: .cancel) {}
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

    private var currentTileOptions: [String] {
        guard let question = state.currentQuestion else { return [] }
        let accepted = question.acceptedAnswerVariants
        let distractors = QuestionContent.distractorOptions(for: question, from: bank)
        let combined = accepted + distractors
        var rng = SeededShuffle(seed: QuestionContent.shuffleSeed(for: question.stableID))
        return combined.shuffled(using: &rng)
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
        let options = currentTileOptions
        let chosen = selectedOptionIndexes.compactMap { index in
            index >= 0 && index < options.count ? options[index] : nil
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

    private var progressFraction: Double {
        let total = state.maximumQuestionsAsked
        guard total > 0 else { return 0 }
        return Double(min(state.currentIndex + 1, total)) / Double(total)
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

    /// Ends the mock-test session (persisting it if any answers were recorded, otherwise
    /// deleting it), then dismisses the view. Shared by the close button and the tab-switch guard.
    private func endMockTest() {
        if state.answers.isEmpty {
            if let session { modelContext.delete(session) }
        } else {
            session?.endedAt = .now
        }
        try? modelContext.save()
        dismiss()
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

        if themeManager.sessionFeedbackEnabled {
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

    private func skipQuestion() {
        state.skip()
        review = nil
        session?.currentIndex = state.currentIndex
        answer = ""
        selectedOptionIndexes = []
    }

    private func revealButton(question: QuestionContent) -> some View {
        Button {
            withAnimation { showOfficialAnswer.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showOfficialAnswer ? "chevron.down" : "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.ink)
                Text(showOfficialAnswer ? "mocktestSessionHideOfficialAnswer" : "mocktestSessionShowOfficialAnswer")
                     .font(.subheadline.weight(.medium))
                     .foregroundStyle(palette.ink)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.bordered)
        .tint(palette.primary)
    }

    private var skipButton: some View {
        Button {
            withAnimation { skipQuestion() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.ink)
                Text("mocktestSessionSkipQuestion")
                     .font(.subheadline.weight(.medium))
                     .foregroundStyle(palette.ink)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.bordered)
        .tint(palette.warning)
    }

    private func finishTest() {
        session?.endedAt = .now
        try? modelContext.save()
        dismiss()
    }
}
