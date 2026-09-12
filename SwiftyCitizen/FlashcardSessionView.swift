import SwiftUI
import SwiftData

struct SessionProgressHeader: View {
    let progressText: String
    let onClose: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Close session")

            Spacer()

            Text(progressText)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityLabel("Progress \(progressText)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct QuestionCard: View {
    let question: QuestionContent

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question \(question.stableID)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(question.officialQuestion)
                .font(.title3.bold())
                .foregroundStyle(palette.ink)

            if question.topic.isEmpty == false {
                Text(question.topic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

struct AnswerCard: View {
    let question: QuestionContent
    let notice: String?
    let userAnswer: String?

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Official answer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(question.acceptedAnswerVariants.enumerated()), id: \.offset) { variant in
                HStack(alignment: .top, spacing: 8) {
                    if question.acceptedAnswerVariants.count > 1 {
                        Image(systemName: "checkmark")
                            .font(.footnote.bold())
                            .foregroundStyle(palette.primary)
                            .accessibilityHidden(true)
                    }
                    Text(variant.element)
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let userAnswer, !userAnswer.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your answer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(userAnswer)
                        .font(.footnote)
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let notice, !notice.isEmpty {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(palette.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if question.isJurisdictionDependent {
                notice(
                    systemImage: "location",
                    text: "Answer depends on where you live. Local officials accept any correct answer for your state."
                )
            }

            if case .exactly(let count) = question.answerCardinality, count > 1 {
                notice(
                    systemImage: "number",
                    text: "Provide \(count) of the answers shown."
                )
            }

            SourceBadge(question: question)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func notice(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SourceBadge: View {
    let question: QuestionContent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Source")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            if let host = question.sourceURL?.host {
                Text(host)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Source \(question.sourceURL?.host ?? "unknown")")
    }
}

struct SelfAssessmentControl: View {
    let onSelect: (SelfAssessment) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(spacing: 12) {
            Text("How well did you know it?")
                .font(.headline)
                .foregroundStyle(palette.ink)

            if dynamicTypeSize >= .accessibility3 {
                VStack(spacing: 10) {
                    assessmentButtons
                }
            } else {
                HStack(spacing: 10) {
                    assessmentButtons
                }
            }
        }
        .padding(20)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var assessmentButtons: some View {
        ForEach(SelfAssessment.allCases, id: \.self) { assessment in
            Button {
                onSelect(assessment)
            } label: {
                Label(assessment.displayName, systemImage: assessment.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(palette.tint(for: assessment))
            .accessibilityLabel("I answered \(assessment.displayName)")
        }
    }
}

struct FlashcardSessionView: View {
    let configuration: OnboardingConfiguration
    let mode: StudyMode
    let initialQuestions: [QuestionContent]
    let resumeSession: StudySession?
    let userAnswers: [String: String]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    @State private var state: FlashcardState
    @State private var session: StudySession?
    @State private var confirmsExit = false

    init(
        configuration: OnboardingConfiguration,
        mode: StudyMode = .flashcards,
        questions: [QuestionContent]? = nil,
        resumeSession: StudySession? = nil,
        userAnswers: [String: String] = [:]
    ) {
        self.configuration = configuration
        self.mode = mode
        self.resumeSession = resumeSession
        self.userAnswers = userAnswers

        if let resumeSession,
           let resumed = resumeSession.resumeState(deckQuestions: questions ?? []) {
            self.initialQuestions = resumed.questions
            _state = State(initialValue: resumed)
        } else {
            let questions = questions ?? Self.loadedQuestions(for: configuration)
            self.initialQuestions = questions
            _state = State(initialValue: FlashcardState(questions: questions))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if initialQuestions.isEmpty {
                ScrollView {
                    EmptyStateView(
                        systemImage: "rectangle.stack",
                        title: "Nothing to review",
                        message: "There are no questions in this review set. Try a different scope or test version."
                    )
                    .padding(24)
                }
            } else if state.isComplete {
                SessionSummaryView(
                    answeredCount: state.answeredCount,
                    assessments: state.attempts.map(\.assessment),
                    onFinish: finishSession
                )
            } else {
                SessionProgressHeader(
                    progressText: state.progressText,
                    onClose: { confirmsExit = true }
                )

                ScrollView {
                    VStack(spacing: 16) {
                        if let question = state.currentQuestion {
                            QuestionCard(question: question)

           if state.isRevealed {
                 AnswerCard(
                     question: question,
                     notice: nil,
                     userAnswer: userAnswers[question.stableID]
                 )
             }
                        }
                    }
                    .padding(20)
                }

                controls
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(mode.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(palette.canvas.ignoresSafeArea())
        .onAppear(perform: beginOrResumeSession)
        .confirmationDialog(
            "End this session?",
            isPresented: $confirmsExit,
            titleVisibility: .visible
        ) {
            Button("End session", role: .destructive) {
                endSession()
                dismiss()
            }
            Button("Keep studying", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 0) {
            Divider()
            if state.isRevealed {
                SelfAssessmentControl { assessment in
                    record(assessment)
                }
            } else {
                PrimaryActionButton(title: "Reveal answer", systemImage: "eye") {
                    state.reveal()
                }
            }
        }
        .padding(20)
        .padding(.bottom, 8)
    }

    private static func loadedQuestions(for configuration: OnboardingConfiguration) -> [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
        return (try? QuestionBankLoader().load(version: version)) ?? []
    }

    private func beginOrResumeSession() {
        if let existing = resumeSession,
           existing.mode == mode,
           existing.isComplete == false,
           session == nil {
            session = existing
            return
        }
        guard session == nil,
              let version = configuration.selectedTestVersion else { return }
        let newSession = StudySession(
            mode: mode,
            testVersion: version,
            deckStableIDs: initialQuestions.map(\.stableID)
        )
        modelContext.insert(newSession)
        session = newSession
    }

    private func record(_ assessment: SelfAssessment) {
        guard let attempt = state.assess(assessment) else { return }

        let record = QuestionAttempt(
            questionStableID: attempt.stableID,
            testVersion: attempt.testVersion,
            assessment: attempt.assessment
        )
        session?.attempts.append(record)
        session?.applyProgress(
            answeredIDs: state.questions.map(\.stableID),
            currentIndex: state.currentIndex
        )

        if state.isComplete {
            session?.endedAt = .now
        }
        try? modelContext.save()
    }

    private func endSession() {
        if state.answeredCount > 0 {
            session?.endedAt = .now
        } else if let session {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }

    private func finishSession() {
        endSession()
        dismiss()
    }
}

private extension StudyMode {
    var navigationTitle: String {
        switch self {
        case .flashcards:
            "Flashcards"
        case .targetedReview:
            "Targeted review"
        case .mockTest:
            "Mock test"
        }
    }
}

#Preview {
    NavigationStack {
        FlashcardSessionView(configuration: OnboardingConfiguration(
            filingDate: Date(),
            selectedTestVersion: .twoThousandTwentyFive,
            isSixtyFiveTwentyEligible: false,
            studyLanguage: .english,
            disclaimerAccepted: true
        ))
    }
    .environment(ThemeManager())
    .modelContainer(for: [Item.self, SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self], inMemory: true)
}