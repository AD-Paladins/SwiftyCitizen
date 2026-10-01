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
            .accessibilityLabel("studyFlashcardCloseSession")

            Spacer()

            Text(progressText)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityLabel("\(String(localized: "studyFlashcardProgressPrefix"))\(progressText)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct FlashcardSessionHeader: View {
    let progressText: String
    let fraction: Double
    let onClose: () -> Void

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(palette.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("studyFlashcardCloseSession")

                Text(progressText)
                    .font(CivicText.labelMD.font)
                    .monospacedDigit()
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(.horizontal, 20)

            ProgressView(value: fraction)
                .progressViewStyle(.linear)
                .tint(palette.primary)
                .padding(.horizontal, 20)
                .accessibilityLabel("studyFlashcardHeaderProgress")
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct QuestionCard: View {
    let question: QuestionContent

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(String(localized: "studyFlashcardQuestionPrefix"))\(question.stableID)")
                .font(CivicText.labelSM.font.weight(.semibold))
                .foregroundStyle(palette.dimmed)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "tag")
                    .font(CivicText.labelSM.font)
                    .accessibilityHidden(true)
                Text(question.topic)
                    .font(CivicText.labelSM.font)
                    .foregroundStyle(palette.dimmed)
            }

            Text(question.officialQuestion)
                .font(CivicText.headlineLG.font)
                .foregroundStyle(palette.ink)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.xl)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

  struct AnswerCard: View {
     let question: QuestionContent
     let notice: String?
     let userAnswer: String?
     let grading: Bool

     @Environment(ThemeManager.self) private var themeManager
     private var palette: AppPalette { themeManager.palette }

     private var presentation: AnswerPresentation {
         AnswerEvaluator.presentation(for: userAnswer, against: question)
     }

     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             if grading {
                 switch presentation.verdict {
                 case .correct:
                     verdictColumn(yourColor: palette.success, yourImage: "checkmark.seal.fill")
                 case .partial:
                     verdictColumn(yourColor: palette.warning, yourImage: "exclamationmark.triangle.fill")
                 case .incorrect:
                     comparisonColumn
                 case .unanswered:
                     officialVariants(success: false)
                 }
             } else {
                 plainComparison
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
                     text: String(localized: "studyFlashcardAnswerDependsNotice")
                 )
             }

             if case .exactly(let count) = question.answerCardinality, count > 1 {
                 notice(
                     systemImage: "number",
                     text: "\(String(localized: "studyFlashcardProvidePrefix"))\(count) \(String(localized: "commonOf"))\(String(localized: "studyFlashcardAnswersShownSuffix"))"
                 )
             }

            SourceBadge(question: question)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.xl)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private func verdictColumn(yourColor: Color, yourImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            officialVariants(success: true)
            answerBlock(
                title: "studyFlashcardYourAnswer",
                text: presentation.yourAnswer ?? "",
                systemImage: yourImage,
                color: yourColor
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var plainComparison: some View {
         VStack(alignment: .leading, spacing: 12) {
             answerBlock(
                 title: "studyFlashcardYourAnswer",
                 text: userAnswer ?? "",
                 systemImage: "pencil",
                 color: palette.dimmed
             )
             .frame(maxWidth: .infinity, alignment: .leading)
             officialVariants(success: true)
         }
     }

   private var comparisonColumn: some View {
        HStack(alignment: .top, spacing: 12) {
            answerBlock(
                title: "studyFlashcardYourAnswer",
                text: presentation.yourAnswer ?? "",
                systemImage: "xmark.circle.fill",
                color: palette.danger
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            officialVariants(success: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func officialVariants(success: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                 Image(systemName: "checkmark.seal.fill")
                     .font(CivicText.labelSM.font)
                     .foregroundStyle(palette.primary)
                     .accessibilityHidden(true)
                 Text("studyFlashcardOfficialAnswer")
                     .font(CivicText.labelSM.font.weight(.semibold))
                     .foregroundStyle(palette.ink)
             }

            ForEach(Array(question.acceptedAnswerVariants.enumerated()), id: \.offset) { variant in
                HStack(alignment: .top, spacing: 8) {
                    if question.acceptedAnswerVariants.count > 1 {
                        Image(systemName: "checkmark")
                            .font(.footnote.bold())
                            .foregroundStyle(success ? palette.success : palette.ink)
                            .accessibilityHidden(true)
                    }
                    Text(variant.element)
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func answerBlock(title: String, text: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.footnote.bold())
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.dimmed)
            }
            Text(text)
                .font(.footnote)
                .foregroundStyle(palette.ink)
        }
    }

    private func notice(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.footnote)
            .foregroundStyle(palette.dimmed)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SourceBadge: View {
    let question: QuestionContent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
         Text("studyFlashcardSource")
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
        .accessibilityLabel("\(String(localized: "studyFlashcardSourcePrefix"))\(question.sourceURL?.host ?? "unknown")")
    }
}

struct SelfAssessmentControl: View {
    let onSelect: (SelfAssessment) -> Void
    let currentBox: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("studyFlashcardHowWellDidYouKnowIt")
                    .font(CivicText.headlineSM.font)
                    .foregroundStyle(palette.ink)
                Text("\(String(localized: "studyFlashcardLeitnerBoxPrefix"))\(currentBox)")
                    .font(CivicText.labelSM.font.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }

            if dynamicTypeSize >= .accessibility3 {
                VStack(spacing: 10) { assessmentButtons }
            } else {
                HStack(spacing: 10) { assessmentButtons }
            }
        }
        .padding(.xl)
        .cardStyle()
    }

    private var assessmentButtons: some View {
        ForEach(SelfAssessment.allCases, id: \.self) { assessment in
            gradeButton(assessment)
        }
    }

    private func gradeLabel(_ assessment: SelfAssessment) -> String {
        switch assessment {
        case .again, .hard:
            return assessment.displayName
        case .gotIt:
            return String(localized: "studyFlashcardMasteredLabel")
        }
    }

    /// Interval the grade leaves the card in. `again` re-presents now; `hard`/`mastered` show days from the Leitner table.
    private func intervalLabel(_ assessment: SelfAssessment) -> String {
        let nextBox = assessment == .again ? 1 : LeitnerScheduler.nextBox(after: assessment, currentBox: currentBox)
        let interval = LeitnerScheduler.interval(forBox: nextBox)
        if interval <= 0 {
            return String(localized: "studyFlashcardAgainInterval")
        }
        let days = Int(round(interval / 86_400))
        return String(format: String(localized: "studyFlashcardIntervalFormat"), String(max(days, 1)))
    }

    private func gradeButton(_ assessment: SelfAssessment) -> some View {
        Button {
            onSelect(assessment)
        } label: {
            VStack(spacing: 2) {
                Label(gradeLabel(assessment), systemImage: assessment.systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(intervalLabel(assessment))
                    .font(CivicText.labelSM.font)
                    .foregroundStyle(palette.dimmed)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(palette.tint(for: assessment))
        .accessibilityLabel("\(String(localized: "studyFlashcardIAnsweredPrefix"))\(gradeLabel(assessment))")
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
    @State private var draftAnswer: String = ""

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
            let resumed = resumeFlashcardState(
                deckStableIDs: resumeSession.deckStableIDs,
                currentIndex: resumeSession.currentIndex,
                attempts: resumeSession.attempts.compactMap { $0.flashcardAttemptRecord },
                deckQuestions: questions ?? []
            ) {
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
                         title: "studyFlashcardNothingToReview",
                         message: "studyFlashcardNothingToReviewMessage"
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
                VStack(spacing: 0) {
                    FlashcardSessionHeader(
                        progressText: state.progressText,
                        fraction: progressFraction,
                        onClose: { confirmsExit = true }
                    )

                    ScrollView {
                        VStack(spacing: 16) {
                            if let question = state.currentQuestion {
                                 QuestionCard(question: question)

                                 if !state.isRevealed {
                                     answerInput
                                 }

                                 if state.isRevealed {
                                     let answerForQuestion = userAnswers[question.stableID] ?? state.currentAnswer
                                     AnswerCard(
                                         question: question,
                                         notice: nil,
                                         userAnswer: answerForQuestion,
                                         grading: userAnswers[question.stableID] != nil
                                     )
                                 }
                             }
                        }
                        .padding(20)
                    }

                    controls
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(mode.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(palette.canvas.ignoresSafeArea())
        .onAppear(perform: beginOrResumeSession)
        .confirmationDialog(
             "studyFlashcardEndSessionConfirm",
             isPresented: $confirmsExit,
             titleVisibility: .visible
         ) {
             Button("studyFlashcardEndSession", role: .destructive) {
                 endSession()
                 dismiss()
             }
             Button("studyFlashcardKeepStudying", role: .cancel) {}
         }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 0) {
            Divider()
            if state.isRevealed {
                SelfAssessmentControl(onSelect: { assessment in record(assessment) }, currentBox: state.currentBox)
            } else {
                PrimaryActionButton(title: "studyFlashcardRevealAnswer", systemImage: "eye") {
                    state.recordAnswer(draftAnswer)
                    state.reveal()
                }
            }
        }
        .padding(20)
        .padding(.bottom, 8)
    }

    private var progressFraction: Double {
        let total = state.questions.count
        guard total > 0 else { return 0 }
        return Double(min(state.currentIndex + 1, total)) / Double(total)
    }

    private var answerInput: some View {
         VStack(alignment: .leading, spacing: 8) {
         Text("studyFlashcardYourAnswer")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(palette.dimmed)
              TextField("studyFlashcardOptionalPractice", text: $draftAnswer, axis: .vertical)
                 .multilineTextAlignment(.leading)
                 .lineLimit(1...4)
                 .padding(12)
                 .background(palette.canvas, in: RoundedRectangle(cornerRadius: 12))
                 .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(palette.dimmed.opacity(0.3), lineWidth: 1)
                 )
         }
         .frame(maxWidth: .infinity, alignment: .leading)
     }

   private static func loadedQuestions(for configuration: OnboardingConfiguration) -> [QuestionContent] {
        guard let version = configuration.selectedTestVersion else { return [] }
         guard let testConfiguration = configuration.testConfiguration else { return [] }
         let loaded = (try? QuestionBankLoader().load(version: version)) ?? []
         return selectQuestions(
             from: loaded,
             maximum: testConfiguration.maximumQuestionsAsked,
             shuffleEnabled: configuration.shuffleQuestions
         )
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
       let attempt = state.assess(assessment)
        guard let attempt else {
            draftAnswer = ""
            return
        }

        let record = QuestionAttempt(
            questionStableID: attempt.stableID,
            testVersion: attempt.testVersion,
            assessment: attempt.assessment,
            answerText: attempt.answerText,
            boxLevel: attempt.boxLevel
        )
        draftAnswer = ""
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

#Preview {
    NavigationStack {
        FlashcardSessionView(configuration: OnboardingConfiguration(
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
