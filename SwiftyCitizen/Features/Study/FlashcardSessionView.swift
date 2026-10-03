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
    let currentBox: Int
    /// Stable ID of the question being studied; nil hides the bookmark toggle.
    let bookmarkStableID: String?
    var isBookmarked: Bool = false
    var onToggleBookmark: () -> Void = {}
    var onClose: () -> Void = {}

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        // ponytail: compact session header — less padding/spacing and a thinner bar so it does not crowd the small card screen.
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.ink)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("studyFlashcardCloseSession")

                Text(progressText)
                    .font(CivicText.labelSM.font)
                    .monospacedDigit()
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                // ponytail: box/mastery indicator moved up here (number + flame) to use the empty top-right and free the bottom card.
                HStack(spacing: 2) {
                    Text("\(currentBox)")
                        .font(CivicText.labelSM.font.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(palette.primary)
                    Image(systemName: "flame.fill")
                        .font(CivicText.labelSM.font)
                        .foregroundStyle(palette.warning)
                }
                .accessibilityLabel("\(String(localized: "studyFlashcardLeitnerBoxPrefix"))\(currentBox)")

                // ponytail: bookmark toggle at the far right so the learner can save the
                // current question without leaving the session.
                if bookmarkStableID != nil {
                    Button(action: onToggleBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark_border")
                            .font(CivicText.labelSM.font)
                            .foregroundStyle(isBookmarked ? palette.primary : palette.dimmed)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(String(localized: "studyFlashcardBookmark"))
                }
            }
            .padding(.horizontal, 20)

            ProgressView(value: fraction)
                .progressViewStyle(.linear)
                .tint(palette.primary)
                .frame(height: 4)
                .padding(.horizontal, 20)
                .accessibilityLabel("studyFlashcardHeaderProgress")
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

struct SpeakerButton: View {
    let textToSpeak: String
    let idleLabelKey: String
    @ObservedObject var speechManager: SpeechManager
    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        Button {
            speechManager.isSpeaking ? speechManager.stop() : speechManager.speak(textToSpeak)
        } label: {
            Image(systemName: speechManager.isSpeaking ? "speaker.wave.2.fill" : "speaker.fill")
                .font(.subheadline)
                .frame(width: 40, height: 44)
                .contentShape(Rectangle())
                .accessibilityLabel(
                    speechManager.isSpeaking
                        ? String(localized: "studyFlashcardStop")
                        : NSLocalizedString(idleLabelKey, comment: "")
                )
        }
        .buttonStyle(.borderless)
    }
}

struct QuestionCard: View {
    let question: QuestionContent
    // Optional so QuestionCard can be shared by flows without TTS (e.g. MockTestSessionView).
    // Plain stored optional (not @ObservedObject — an Optional can't be a property wrapper): the
    // flashcard session injects its SpeechManager and other callers omit it (init defaults nil); the
    // child SpeakerButton owns the observation of isSpeaking, so QuestionCard only needs to know if one is present.
    let speechManager: SpeechManager?

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    init(question: QuestionContent, speechManager: SpeechManager? = nil) {
        self.question = question
        self.speechManager = speechManager
    }

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

            HStack(alignment: .top, spacing: 6) {
                Text(question.officialQuestion)
                    .font(CivicText.headlineLG.font)
                    .foregroundStyle(palette.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let speechManager {
                    SpeakerButton(
                        textToSpeak: question.officialQuestion,
                        idleLabelKey: "studyFlashcardSpeakQuestion",
                        speechManager: speechManager
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

  struct AnswerCard: View {
     let question: QuestionContent
     let notice: String?
     let userAnswer: String?
    let grading: Bool
     // Plain stored value (the child SpeakerButton owns @ObservedObject + isSpeaking); AnswerCard only
     // forwards the manager it is given. The flashcard session always injects one.
     let speechManager: SpeechManager

      @Environment(ThemeManager.self) private var themeManager
      private var palette: AppPalette { themeManager.palette }

      private var presentation: AnswerPresentation {
          AnswerEvaluator.presentation(for: userAnswer, against: question)
      }

      static func hasExplanation(_ question: QuestionContent) -> Bool { question.explanation != nil }

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

              explanationBlock()

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
        .padding(.md)
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

    @ViewBuilder
    private func explanationBlock() -> some View {
        if let explanation = question.explanation, !explanation.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed")     // distinct study-aid icon; avoid translate/globe/checkmark/sparkles
                        .font(CivicText.labelSM.font)
                        .foregroundStyle(palette.dimmed)
                        .accessibilityHidden(true)
                    Text("studyFlashcardExplanation")
                        .font(CivicText.labelSM.font.weight(.semibold))
                        .foregroundStyle(palette.dimmed)
                    Spacer()
                    SpeakerButton(textToSpeak: explanation, idleLabelKey: "studyFlashcardSpeakExplanation", speechManager: speechManager)
                }
                Text(explanation)
                    .font(.footnote)
                    .foregroundStyle(palette.dimmed)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.sm)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "studyFlashcardExplanationAid"))
        }
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
        Group {
            if dynamicTypeSize >= .accessibility3 {
                VStack(spacing: 10) { assessmentButtons }
            } else {
                HStack(spacing: 10) { assessmentButtons }
            }
        }
        .padding(.md)
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

    private func gradeButton(_ assessment: SelfAssessment) -> some View {
        Button {
            onSelect(assessment)
        } label: {
            VStack(spacing: 0) {
                // ponytail: drop the per-button SF Symbol and the interval text ("< 1 min", "In 1 days") — just the grade label reads clearer on this small screen.
                Text(gradeLabel(assessment))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
    @Environment(SessionActivityCoordinator.self) private var sessionCoordinator
    private var palette: AppPalette { themeManager.palette }
    @Query private var bookmarks: [Bookmark]

    @State private var state: FlashcardState
    @State private var session: StudySession?
    @State private var confirmsExit = false
    @State private var draftAnswer: String = ""

    @StateObject private var speechManager = SpeechManager()

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
                        currentBox: state.currentBox,
                        bookmarkStableID: state.currentQuestion?.stableID,
                        isBookmarked: isCurrentQuestionBookmarked,
                        onToggleBookmark: { toggleCurrentBookmark() },
                        onClose: { confirmsExit = true }
                    )

                    ScrollView {
                        VStack(spacing: 16) {
                                 if let question = state.currentQuestion {
                                  QuestionCard(question: question, speechManager: speechManager)

                                 if !state.isRevealed {
                                     answerInput
                                 }

                                 if state.isRevealed {
                                     let answerForQuestion = userAnswers[question.stableID] ?? state.currentAnswer
                                     AnswerCard(
                                          question: question,
                                          notice: nil,
                                          userAnswer: answerForQuestion,
                                          grading: userAnswers[question.stableID] != nil,
                                          speechManager: speechManager
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
        .onAppear {
            beginOrResumeSession()
            sessionCoordinator.setActive(true)
        }
        // F4: when the tab-switch guard ends this session, dismiss it here.
        .onChange(of: sessionCoordinator.isActive) { _, active in
            if !active {
                endSession()
                dismiss()
            }
        }
        .onDisappear {
            if let session, session.endedAt == nil {
                endSession()
            }
            sessionCoordinator.setActive(false)
        }
        .alert(
              "studyFlashcardEndSessionConfirm",
              isPresented: $confirmsExit,
              actions: {
                  Button("studyFlashcardEndSession", role: .destructive) {
                      endSession()
                      dismiss()
                  }
                  Button("studyFlashcardKeepStudying", role: .cancel) {}
              }
          )
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

    private var activeVersionRawValue: String? {
        configuration.selectedTestVersion?.rawValue
    }

    /// Stable IDs of bookmarked questions for the active test version. Version scoping
    /// lives here (SwiftData query); the pure builder never touches SwiftData.
    private var bookmarkedStableIDs: Set<String> {
        guard let raw = activeVersionRawValue else { return [] }
        return Set(bookmarks.filter { $0.testVersionRawValue == raw }.map(\.questionStableID))
    }

    private var isCurrentQuestionBookmarked: Bool {
        guard let id = state.currentQuestion?.stableID else { return false }
        return bookmarkedStableIDs.contains(id)
    }

    /// Adds or removes the bookmark for the question currently on screen.
    private func toggleCurrentBookmark() {
        guard let version = configuration.selectedTestVersion,
              let stableID = state.currentQuestion?.stableID else { return }
        let raw = version.rawValue
        if let existing = bookmarks.first(where: { $0.questionStableID == stableID && $0.testVersionRawValue == raw }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(Bookmark(questionStableID: stableID, testVersion: version))
        }
        try? modelContext.save()
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
    .environment(SessionActivityCoordinator())
    .modelContainer(for: [SavedOnboardingConfiguration.self, StudySession.self, QuestionAttempt.self, Bookmark.self], inMemory: true)
}
