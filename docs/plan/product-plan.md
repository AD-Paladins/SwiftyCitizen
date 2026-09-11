# SwiftyCitizen Product and Engineering Plan

SwiftyCitizen is an offline-first iOS study app for the USCIS naturalization civics test. The first release should help a learner study the official questions, practice answers aloud, and measure progress without requiring an account, a backend, or generative AI.

## Product Decisions

| Area | Decision |
| --- | --- |
| Platform | Native iOS app built with SwiftUI and SwiftData |
| Content | Versioned USCIS question banks, beginning with the 2008 and 2025 tests |
| Storage | Local-only persistence for questions, attempts, sessions, and preferences |
| Primary study modes | Flashcards, targeted review, and oral practice |
| Exam simulation | Uses the selected USCIS test version and its official scoring rules |
| Languages | English for official answers; Spanish may be provided as a study aid |
| AI | Deferred until deterministic learning and scoring behavior are proven |
| Backend | Out of scope for the first release |

The app must never present generated content as an official USCIS question or answer.

## Scope by Phase

### Phase 0: Content and Rules Foundation

- Verify and version the official USCIS question banks.
- Add the 2008 and 2025 test configurations.
- Represent question topics, accepted answers, answer constraints, jurisdiction-dependent answers, and source metadata.
- Define the filing-date rule and the 65/20 special consideration flow.
- Add content validation tests so incomplete or duplicated questions fail before release.

#### Phase 0 Deliverables

- A verified source record for each supported USCIS question bank.
- A versioned content format for questions, answer variants, answer cardinality, topics, and source metadata.
- A `TestConfiguration` definition for the 2008, 2025, and 65/20 configurations.
- A documented policy for answers that depend on current officials or the learner's jurisdiction.
- Content validation fixtures covering missing fields, duplicate identifiers, invalid answer cardinality, and unsupported configurations.
- A short content-update procedure describing how a revised USCIS source is reviewed and shipped.

#### Phase 0 Exit Criteria

- [x] Every bundled question has a stable identifier and source metadata.
- [x] The 2008 and 2025 banks are distinguishable and cannot be mixed accidentally.
- [x] The 65/20 configuration selects only its designated question set.
- [x] Test configurations provide question count, passing score, and applicable rules without hardcoded UI logic.
- [x] Validation fails for malformed or duplicated content.
- [x] Dynamic answers have a verification date and a review path.
- [x] The content format can be loaded in a unit test without SwiftUI or SwiftData.

The 65/20 membership is stored in the derived `uscis-65-20.json` manifest. The 2008 source bank remains a complete 100-question source and does not duplicate special-set flags; the loader applies the flag when resolving the designated subset.

### Phase 0.5: Product and Design Definition

- Review the screen inventory in `docs/plan/screen-inventory.md`.
- Use `docs/plan/phase-0.5-design-spec.md` as the repository-backed design source.
- Follow `docs/plan/phase-0.5-user-checklist.md` for the Penpot work and handoff.
- Confirm the first-release navigation and the responsibilities of each screen.
- Define the visual language, accessibility baseline, and reusable UI components.
- Create low-fidelity flows and a small number of high-fidelity screens before implementation.
- Record the selected design tools and their verified free-plan limitations.
- Keep design assets exportable and usable without a paid subscription.

#### Phase 0 to 0.5 Transition Review

Phase 0 established three selectable content configurations, versioned source metadata, a derived 65/20 set, and a clear distinction between official content and learner-facing features. Phase 0.5 must reflect those constraints in the product definition:

- Show the selected test version and source revision before a learner starts a mock test.
- Design onboarding for test version, filing-date context, 65/20 eligibility, and study language without making legal claims.
- Include source and verification information in the content-information flow.
- Design explicit states for content updates and answers that depend on current officials or jurisdiction.
- Keep the official question and answer visually distinct from optional explanations or future AI-generated study aids.
- Prototype the fallback path that works without microphone permission or speech recognition.

#### Phase 0.5 Exit Criteria

- [x] Navigation is approved against the screen inventory.
- [x] Onboarding clearly configures 2008, 2025, or 65/20 without silently mixing banks.
- [x] Mock-test screens expose the active rules before the session starts.
- [x] Content source, revision, and verification states have a defined presentation.
- [ ] Accessibility behavior is defined for cards, oral practice, feedback, and unavailable capabilities.
- [ ] High-risk flows have low-fidelity and selected high-fidelity prototypes.
- [ ] Design assets and decisions are backed up in a format that does not require a paid tool.

The repository currently reflects a completed low-fidelity pass for onboarding, flashcards, mock-test setup, and speech fallback, but Phase 0.5 remains intentionally open until the final high-fidelity polish, typographic review, accessibility pass, and export backup are complete.

#### Phase 0.5 to Phase 1 Transition Review

The aligned Penpot wireframes establish the first implementation slice: onboarding and test configuration. Phase 0.5 remains open until high-fidelity prototypes, final visual decisions, accessibility review, and backup are complete. The onboarding code is a Phase 1 implementation slice and must preserve the selected test version, filing-date context, 65/20 eligibility, study language, and study-aid disclaimer.

#### Phase 1 First Slice Exit Criteria

- [x] A first-time learner can complete Welcome and Test Configuration.
- [x] The app persists filing-date context, selected test version, 65/20 eligibility, and study language locally.
- [x] The selected configuration is visible after onboarding and can be edited from Settings.
- [x] Invalid or incomplete configuration cannot continue.
- [ ] Onboarding is usable with Dynamic Type and VoiceOver.
- [x] The configuration persistence and version selection logic are covered by unit tests without SwiftUI.

#### Phase 1 First Slice Transition Review

The onboarding slice now stores one validated learner configuration in SwiftData and exposes the selected USCIS rules in the placeholder Home state. The dashboard slice replaced that placeholder: the app now runs a tab-based root navigation (Home, Study, Practice, Progress) with a real dashboard, and Study/Practice expose the entry points for flashcards, targeted review, mock test, and oral practice. It preserves this configuration as the source of truth for future study flows and does not change the filing-date boundary or 65/20 selection rules without new domain tests.

During the dashboard slice, the 2008 bank failed content validation: four jurisdiction-dependent questions (2008-020, 2008-023, 2008-043, 2008-044) had empty answer variants, which also blocked the derived 65/20 source. They now use the official "Answers will vary." wording mirrored from the 2025 bank, and all content tests pass again. Future slices should build the study sessions behind these entry points and persist attempts and sessions so the dashboard can render real progress.
- [x] Unit tests cover configuration persistence and version selection without SwiftUI.

#### Phase 1 Flashcard Slice Exit Criteria

- [x] A learner can start a flashcard session from the Study tab using the selected test version.
- [x] A card shows the official question, reveals the official answers, and records a self-assessment (Again, Hard, Got it).
- [x] Sessions and attempts persist in SwiftData and survive relaunch.
- [x] The dashboard's Today and Due next sections render from persisted attempts instead of empty states.
- [x] Self-assessment is learner-reported and never presented as a passing score.
- [x] Targeted review can select weak or unanswered questions from the attempt history.
- [x] Sessions can be exited and resumed without losing the in-progress deck position.
- [ ] A learner can give their own answer before revealing the official one, and then verify how theirs compares against it.

#### Phase 1 Flashcard Slice Transition Review

The flashcard slice is implemented: `StudySession` and `QuestionAttempt` are SwiftData models that reference questions by stable ID (the bundled banks remain the authoritative content source), and a pure `FlashcardState` drives reveal/assess/advance so it is testable without SwiftUI. `StudyProgressMetrics` derives Today and Due next figures from persisted attempts without depending on SwiftData. The design-spec flow (official question → reveal → self-assess → next → summary) is implemented, and 24 tests pass covering state transitions, SwiftData round-trips, and metrics.

Two decision points surfaced during this slice: session resume (persisting deck position) and targeted review selection. Both are deferred to the next targeted-review slice, which will reuse the persisted attempt history. The dashboard shows the "Got it" rate as learner-reported, not as an official correctness score. Future slices must not present self-assessment intensity as exam accuracy.

#### Phase 1 Targeted Review Slice Exit Criteria

- [x] Targeted review offers Due, Unanswered, and Needs work scopes computed from persisted attempt history.
- [x] The scope selection shows matching question counts before starting.
- [x] A targeted-review session runs over the filtered deck and records attempts as `StudyMode.targetedReview`.
- [x] An interrupted targeted-review session can be resumed to its saved deck position and answered count.
- [x] The deck builder and resume logic are covered by unit tests without SwiftUI.
- [ ] A mock test behind the Practice entry point asks the active version's question count and applies its passing rules.

#### Phase 1 Targeted Review Slice Transition Review

The targeted-review slice is implemented: `ReviewDeckBuilder` is a pure, SwiftData-free selector that resolves Due (unanswered or last self-assessment is not Got it), Unanswered, and Needs work scopes against the persisted attempt history, preserving bank order. `StudySession` now persists its deck ordering and current index so an interrupted targeted-review session can be resumed in place, and `FlashcardSessionView` accepts a mode, a custom deck, and an optional resume session. `TargetedReviewView` exposes scope selection with live counts and an in-progress resume row. The suite grew from 24 to 34 tests.

The next slice is the mock test behind Practice (Phase 2 scope). The setup screen must surface the active version, bank size, maximum questions, and passing score before starting, and missed questions should link into targeted review. SwiftData schema now includes `currentIndex` with a default value so existing on-disk stores migrate cleanly.

#### Phase 2 Mock Test Slice Exit Criteria

- [x] A learner can start a mock test from the Practice tab using the selected test version.
- [x] The setup screen surfaces the active version, bank size, maximum questions, and passing score before starting.
- [x] The session asks the active version's question count and applies its passing rules with early pass/fail.
- [x] Answers are typed and evaluated deterministically against the official variants before scoring.
- [x] The result shows a pass/fail summary with a disclaimer that the app is a study aid, not an immigration authority.
- [x] Missed questions link directly into targeted review.
- [x] Scoring, early completion, failed attempts, randomization, and question selection are covered by unit tests without SwiftUI.

#### Phase 2 Mock Test Slice Transition Review

The mock test slice is implemented behind Practice: `MockTestSetupView` shows the active version and rules, `MockTestSessionView` runs a manual-answer session through a deterministic `MockTestState` (pass once the passing score is reached, fail once it is unreachable, complete at the version question count), `AnswerEvaluator` normalizes typed replies against accepted variants as token sets, and `MockTestResultView` shows the pass/fail summary with the study-aid disclaimer and a direct link into targeted review for missed questions. `QuestionAttempt` records optional `answerText` and `wasCorrect` for exam attempts while self-assessed attempts stay excluded from the Got-it rate. The suite grew from 34 to 47 tests.

Three bank entries (2008-088, 2025-028, 2025-037) declared `answerCardinality` 2 while the official question asks for one; they were corrected to 1 and the banks still validate. Remaining work in Phase 2 will add the official oral-style (speech) simulation and manual override per the Phase 4 boundary.

### Phase 1: Core Study Experience

- [x] Replace the template screen with a simple dashboard.
- [x] Implement flashcards with reveal, self-assessment, and next-question actions.
- [x] Implement targeted review for unanswered, incorrect, and due questions.
- [x] Persist attempts and study sessions with SwiftData.
- [x] Add an onboarding choice for filing date, test version, study language, and 65/20 eligibility.

### Phase 2: Exam Simulation

- [ ] Implement the official oral-style simulation by default (speech input is Phase 4; typed manual answers are in place).
- [x] Ask the correct number of questions for the selected test version.
- [x] Stop and score according to that version's official rules.
- [x] Show the result with a clear disclaimer that the app is a study aid, not an immigration authority.
- [x] Add deterministic tests for scoring, early completion, failed attempts, randomization, and question selection.
- [ ] Support single-select and multi-select answers, not only plain typed text. Choice questions must be scored against official answer variants and the learner's backlog only, never against AI-generated content.
- [ ] When reviewing missed questions in targeted review, show the learner's own wrong answer next to the official one so the comparison is visible and reviewable.

### Phase 3: Retention and Accessibility

- Add a transparent spaced-repetition scheduler based on learner self-assessment and answer history.
- Keep scheduling logic independent of SwiftUI and SwiftData so it can be tested in isolation.
- Add Dynamic Type, VoiceOver labels, color-independent feedback, reduced motion support, and clear audio controls.
- Add optional Spanish explanations without changing the official English answer used for practice.

### Phase 4: Speech Practice

- Use Apple's Speech framework to transcribe live answers when supported.
- Show the transcript before recording the attempt as correct or incorrect.
- Compare against curated answer variants and allow the learner to override the result.
- Treat speech recognition as an assistive feature; do not claim that automatic semantic grading is equivalent to an officer's evaluation.
- Test permission denial, unavailable language assets, interruptions, silence, and partial transcripts.

### Phase 5: Optional Intelligence Features

Only consider these after the core product has reliable content, scoring, persistence, and tests:

- Foundation Models for optional local study summaries.
- Guided question explanations that are clearly labeled as generated and never replace official content.
- App Intents for actions such as starting a study session or opening due questions in Siri, Shortcuts, and Spotlight.
- Readiness insights based on deterministic metrics first; do not market a probability of passing without validated evidence.

## Proposed Domain Boundaries

- `QuestionBank`: immutable, versioned official content and source metadata.
- `TestConfiguration`: test version, filing-date applicability, question count, passing score, and special rules.
- `QuestionAttempt`: one learner interaction, including answer mode, result, transcript if available, and timestamp.
- `StudySession`: a bounded learning session and its attempts.
- `Progress`: derived or persisted learner history for scheduling and dashboard metrics.
- `StudyScheduler`: pure logic that selects due and weak questions.
- `ExamEngine`: pure logic that selects questions and evaluates a simulation.
- `SpeechTranscriber`: platform adapter around Apple's Speech framework.

SwiftUI views should depend on use-case-oriented models, not directly on audio, scheduling, or exam-rule implementation details.

## Content Model Requirements

Each question should support:

- Stable identifier within a test version.
- Official English question and answer text.
- Accepted answer variants and answer cardinality, such as "name one" or "name two."
- Answer format: typed free-text (current), single-select, and multi-select. Choice options must trace to official content or the selected candidate's context; AI-generated or fabricated distractors are an explicit non-goal.
- Topic and difficulty metadata maintained by the app, not inferred by AI.
- Optional Spanish translation or explanation for study support.
- A flag for answers that depend on current officials, state, district, or territory.
- Source URL, source revision, and verification date.

Question content should be shipped as validated bundled data first. SwiftData should store learner state, not become the authoritative source for official content.

## Explicit Non-Goals

- No account system, cloud sync, analytics backend, or admin dashboard in the first release.
- No Core ML model before there is enough validated learner data to justify one.
- No AI-generated distractors in the official exam simulator.
- No automatic promise that a readiness score predicts USCIS outcomes.
- No assumption that every learner takes the 2025 test.

## Phase Checklist

- [x] Phase 0: official content, test configurations, and content validation are complete.
- [ ] Phase 0.5: screen inventory, navigation, design language, and tool decision are approved.
- [ ] Phase 1: dashboard, flashcards, targeted review, onboarding, and local progress are usable.
- [ ] Phase 2: both exam versions and the 65/20 configuration score correctly (manual mock test is in place; speech is Phase 4).
- [ ] Phase 3: scheduling, Dynamic Type, VoiceOver, reduced motion, and Spanish study support are implemented.
- [ ] Phase 4: oral speech practice handles permissions, unavailable services, and learner overrides.
- [ ] Phase 5: optional intelligence features are isolated from official content and deterministic scoring.

## Acceptance Checklist

- [ ] A learner can select or confirm the applicable USCIS test version.
- [ ] The app supports both the 2008 and 2025 civics test rules.
- [ ] Official content is versioned and validated at build time.
- [ ] Study progress survives app relaunch without a network connection.
- [ ] Exam scoring is covered by unit tests independently of SwiftUI.
- [ ] Oral practice remains usable when speech recognition is unavailable.
- [ ] Generated features, if added later, cannot overwrite official content.
- [ ] Accessibility and permission-denied states are tested before release.

## References (keep this up to date)

- [USCIS 2025 Civics Test: 128 Questions and Answers](https://www.uscis.gov/sites/default/files/document/questions-and-answers/2025-Civics-Test-128-Questions-and-Answers.pdf)
- [Apple Foundation Models](https://developer.apple.com/documentation/foundationmodels)
- [Apple App Intents](https://developer.apple.com/documentation/appintents)
- [Apple Speech](https://developer.apple.com/documentation/speech)
