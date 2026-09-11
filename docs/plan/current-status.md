# SwiftyCitizen Current Status

Last verified: September 10, 2026

## Current state

SwiftyCitizen now has the verified content and rules foundation for the USCIS civics app, the first onboarding slice in SwiftUI, the tab-based dashboard, three working study flows (flashcards, targeted review, and mock test) backed by SwiftData persistence with resume support, and a deterministic answer evaluator for typed replies. The app correctly distinguishes 2008, 2025, and 65/20 configurations, persists a validated learner configuration, records study attempts, and renders the dashboard's Today and Due next metrics from real data.

## Completed

- Official 2008, 2025, and 65/20 question banks are bundled and versioned.
- The rules model is separated from UI logic and is covered by unit tests.
- The Phase 0 content-validation work is complete and enforced in tests.
- The initial onboarding flow is implemented and stores the selected study configuration in SwiftData.
- The dashboard slice is implemented: the app now uses a tab-based root navigation (Home, Study, Practice, Progress) with a real Home dashboard showing the configuration summary and a Start review action.
- Study and Practice tabs expose the entry actions for flashcards, targeted review, mock test, and oral practice.
- Settings now edits the persisted configuration in place instead of resetting it, and keeps a destructive reset action.
- Fixed the 2008 bank validation failure: four jurisdiction-dependent questions (2008-020, 2008-023, 2008-043, 2008-044) had empty answer variants and now use the official "Answers will vary." text mirrored from the 2025 bank, unblocking the derived 65/20 source.
- The Phase 1 flashcard slice is implemented: the flashcard session (question card → reveal answer → self-assess → next) follows the Phase 0.5 design flow, and sessions and attempts persist in SwiftData.
- The Phase 1 targeted-review slice is implemented: the Study tab offers Due, Unanswered, and Needs work scopes computed from attempt history by a SwiftData-free deck builder, starts sessions over the filtered deck, and allows resuming an interrupted targeted-review session from its persisted deck position and index.
- The Phase 2 mock-test slice is implemented behind the Practice tab: the setup screen surfaces the active version, bank size, maximum questions, and passing score, the session asks the version's question count in manual answer mode, applies early pass/fail rules and official scoring, and links missed questions into targeted review. `AnswerEvaluator` is a pure token-set matcher, and `ExamEngine`/`MockTestState` drive selection, pacing, and scoring deterministically.
- The dashboard's Today and Due next sections now render real data: reviewed-today count, "Got it" rate, and the number of remaining questions in the configured set, all computed by a SwiftData-free metrics layer.
- Low-fidelity Penpot flows for onboarding, flashcards, mock tests, and speech fallback were aligned to the first-slice scope.

## Still pending before closing Phase 0.5

- Final high-fidelity direction and visual refinements.
- Final typography and color-token decisions.
- Formal Dynamic Type and VoiceOver review on a small viewport (the code-level accessibility audit is complete; see the design spec's audit note).
- Final local backup/export of the design assets.
- Formal design handoff review before expanding beyond onboarding.

## Phase 1 current slice

The flashcards and targeted-review slices are implemented: flashcard study (question, reveal, self-assessment Again / Hard / Got it, session summary), targeted review scopes (Due, Unanswered, Needs work), persistence of sessions and attempts, and resume of interrupted targeted-review sessions. The mock test slice behind Practice is also implemented: setup, manual-answer session with early pass/fail, scoring, and missed-questions review. The next Phase 1 slice is not yet scoped beyond the remaining Phase 0.5 accessibility and design-handoff items.

### Scope for the next slice

- Await the pending high-fidelity direction and accessibility review before expanding beyond the current study flows.

### Non-goals for the next slice

- No AI-generated official content.
- No backend or account system.
- No claim that a score predicts immigration outcomes.
- No speech practice beyond an explicit fallback state.

## Decision log

- Official USCIS content remains the authoritative source; SwiftData stores learner state only, and questions are referenced by stable ID and resolved from the bundled banks.
- UI and design are allowed to evolve independently, but must obey the same version rules.
- The 2008 jurisdiction-dependent answers use the official "Answers will vary." wording from the 2025 bank until a jurisdiction-aware answer path exists.
- Phase 0.5 is intentionally still open until the final design and accessibility review is complete.
- Self-assessment results are learner-reported and never represented as a passing score; accuracy-style metrics are labeled as "Got it" rate to avoid implying official grading.
- Resume support stores the deck ordering and current position per session, so interrupting a targeted-review session does not lose in-progress state.
- The mock-test evaluator compares normalized token sets against accepted variants: a single-answer question passes when the reply is a subset of an official variant, and cardinality-2 questions pass when at least two distinct variants are named. It is lenient by design (optional parentheticals, capitalization, short replies) and deterministic by construction; future speech transcription will reuse the same matcher on the transcript.
- The app corrects three bank entries where `answerCardinality` claimed two answers but the official question asks for one (2008-088, 2025-028, 2025-037); the banks still verify without schema changes.
