# SwiftyCitizen Current Status

Last verified: September 11, 2026

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
- A "Shuffle questions" toggle in Settings → Test configuration randomizes question order for both flashcard and mock-test study modes; the preference is persisted locally.
- Fixed the 2008 bank validation failure: four jurisdiction-dependent questions (2008-020, 2008-023, 2008-043, 2008-044) had empty answer variants and now use the official "Answers will vary." text mirrored from the 2025 bank, unblocking the derived 65/20 source.
- The Phase 1 flashcard slice is implemented: the flashcard session (question card → reveal answer → self-assess → next) follows the Phase 0.5 design flow, and sessions and attempts persist in SwiftData.
- The Phase 1 targeted-review slice is implemented: the Study tab offers Due, Unanswered, and Needs work scopes computed from attempt history by a SwiftData-free deck builder, starts sessions over the filtered deck, and allows resuming an interrupted targeted-review session from its persisted deck position and index.
- The Phase 2 mock-test slice is implemented behind the Practice tab: the setup screen surfaces the active version, bank size, maximum questions, and passing score, the session asks the version's question count in manual answer mode, applies early pass/fail rules and official scoring, and links missed questions into targeted review. `AnswerEvaluator` is a pure token-set matcher, and `ExamEngine`/`MockTestState` drive selection, pacing, and scoring deterministically.
- Mock-test session now shows per-answer feedback via `SessionFeedbackIndicator` (green "Correct", red "Incorrect", amber "Accepted: ...") rendered inline on the question card. `MockTestSessionView` records each answer without advancing, then shows its verdict inline and waits for a "Next" tap for every verdict (uniform manual advance), or advances immediately when the `sessionFeedbackEnabled` flag is off. The flag lives in `SessionFeedbackManager` (`@Observable`, persisted under `sessionFeedbackEnabled`) injected via `.environment`, mirroring `ThemeManager`.
- Wrong mock-test answers now give the learner control: below the verdict, an expandable "Show official answer" disclosure (toggled by `showOfficialAnswer` state) reveals the accepted variants via `AcceptedAnswerCard`. The decision is driven by `MockTestAnswer.needsOfficialAnswerReveal` (`!isCorrect`). Advancing still requires a "Next" tap, so the learner can read the official answer before moving on.
- Multi-select mock-test answers now include distractors so selection discriminates: `QuestionContent.distractorOptions(for:from:)` draws up to four distractors at runtime from other official answer variants in the same topic (excluding own variants and "answers will vary"/"testupdates"), shuffled deterministically per question. Distractors trace to official content only; scoring is unchanged — a selected distractor scores wrong through `AnswerEvaluator`. The mock-test-selection spec, flow doc, product plan, and decision log were updated to reflect this.
- Fixed a mock-test advance bug: after answering, tapping "Next" kept presenting the same question. Root cause was an inverted guard in `MockTestState.advance()` (it returned early while `phase == .active`, so `currentIndex` never incremented). The guard now returns early only when `phase == .complete`; covered by regression tests in `MockTestStateTests` and `SelectionAnswerTests`.
- The dashboard's Today and Due next sections now render real data: reviewed-today count, "Got it" rate, and the number of remaining questions in the configured set, all computed by a SwiftData-free metrics layer.
- Low-fidelity Penpot flows for onboarding, flashcards, mock tests, and speech fallback were aligned to the first-slice scope.
- Screen states are defined where they apply: empty states on Home (no sessions, all caught up, nothing due) and Progress; content-unavailable states in Study, Mock Test Setup, and Mock Test Session when a bank cannot load or is empty; an empty review-set state in Flashcard Session; zero-question scope footers in Targeted Review; and an inline validation error in Test Configuration that explains why Save is disabled. Loading states do not apply because question banks are bundled JSON loaded synchronously.
- Three user-selectable themes (Civic Navy, Paper & Emerald, Study Calm) are implemented: `AppTheme` defines semantic palette tokens with light/dark variants, `ThemeManager` (`@Observable`) owns the selection (persisted under `appThemeName` in UserDefaults) and is injected via `.environment`, so switching the theme in Settings re-renders the app live — including the global `.tint`. All status colors flow from palette tokens (assessment tints, pass/fail badge, validation error), replacing the old hardcoded `AppColor` and error reds, per the Phase 0.5 design decisions. Screens paint `palette.canvas` as their background so `surface` cards stay visibly elevated; the old `secondarySystemBackground`-based `surface` that no longer distinguished cards from the window was replaced by a real canvas/surface contrast.

## Still pending before closing Phase 0.5

- Final high-fidelity direction and visual refinements.
- Formal Dynamic Type and VoiceOver review on a small viewport (the code-level accessibility audit is complete; see the design spec's audit note).
- Final local backup/export of the design assets (the Penpot export is saved locally under `docs/plan/penpot/`, outside git).
- Formal design handoff review before expanding beyond onboarding.
- Wording for the 65/20 eligibility explanation and the current-answer warning pattern (both user-approved approaches; drafts pending).
- Targeted review of missed questions should show the learner's own answer next to the official one (currently only the official answer is shown; the typed reply already persists in `QuestionAttempt.answerText`).
- The mock test should support selection-based answers (single-select and multi-select), not only typed text. Slice A (tiles + fallback) is implemented and specified in `docs/plan/mock-test-selection-spec.md`; multi-select distractors are now implemented via runtime topic-pool generation (see completed list).
- **Current-answer feedback implemented:** per-answer feedback indicator for **all** verdicts (correct-exact "Correct", rejected "Incorrect", lenient-accepted "Accepted: ...") shown inline on the question card so nothing is hidden. Every verdict waits for a "Next" tap to advance (uniform manual advance). A `sessionFeedbackEnabled` flag (persisted, default true) toggles all indicators off; when off, only the question renders and the deck advances immediately. The rejected-but-close warning is deferred to a later refinement.
- **Apple Intelligence evaluation (future refinement):** layer semantic answer evaluation over the offline token-set baseline, with mandatory offline fallback and content traced to official sources.
- **State selector and jurisdiction-dependent answers (future refinement):** a state/territory selector is planned so answers like the governor resolve per state, and jurisdiction-dependent records form a modifiable content subset that Apple Intelligence can refresh on supported devices. See `docs/plan/uscis-test-rules.md` (Content That Can Change, Implementation Rules), `docs/plan/screen-inventory.md` (Test Configuration), and `docs/plan/product-plan.md` (Phase 5 Optional Intelligence Features).

## Deferred findings (mock test — revisit after closing the 4 phases)

Reported by the user while testing the live app against the removed 0.8s auto-advance model. These are **not** fixed yet; priority is to close the current 4 phases first, then revisit them under uniform manual advance:

- **Incorrect feedback too brief:** when the answer is incorrect, the "Incorrect" indicator flashes for less than one second (auto-advance window is 0.8s). The user wants it shown for at least two seconds before advancing.
- **No control on a failed question:** after a wrong answer there is no option to skip the question or see the official/correct answer; the deck moves on automatically. The user wants a skip option and the ability to view the real answer.
- Action once prioritized: increase the auto-advance window for rejected answers to ≥ 2s, and add skip / "see correct answer" affordances (or surface the correct answer in the review path).

Additional mock-test UI findings (same deferment):

- **"Start mock test" button doesn't look like a button** — its styling is ambiguous; the user can't tell it's tappable. Action: give it a clear primary-button style (consistent with `PrimaryActionButton`) so affordance is obvious.
- **"Mode / Manual" card lacks meaning** — the setup shows a "Mode" row defaulting to "Manual", but there is no way to choose automatic vs. manual, and nothing explains why it starts manual. Action: either remove the row or clarify its purpose (and expose an automatic mode later if needed).

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
- Three themes are preferred over a single palette so the civic-product tone is preserved while users pick a feel: Civic Navy (default), Paper & Emerald, and Study Calm. Progress is a permanent tab, typography is SF system defaults, and audio playback is deferred to Phase 4.
- Resume support stores the deck ordering and current position per session, so interrupting a targeted-review session does not lose in-progress state.
- The mock-test evaluator compares normalized token sets against accepted variants: a single-answer question passes when the reply is a subset of an official variant, and cardinality-2 questions pass when at least two distinct variants are named. It is lenient by design (optional parentheticals, capitalization, short replies) and deterministic by construction; future speech transcription will reuse the same matcher on the transcript.
- The app corrects three bank entries where `answerCardinality` claimed two answers but the official question asks for one (2008-088, 2025-028, 2025-037); the banks still verify without schema changes.
- Targeted review of missed questions should show the learner's own wrong answer next to the official one; the typed reply already persists in `QuestionAttempt.answerText` and is carried through the mock-test result, so this is a rendering gap rather than a data gap.
- Mock-test flow uses **uniform manual advance for every verdict**: correct-exact, rejected, and lenient-accepted all show their indicator inline and wait for a "Next" tap to advance; only when `sessionFeedbackEnabled` is off does the deck advance immediately. This surfaces transparency for all verdicts instead of auto-advancing some.
- The per-answer feedback indicator is gated behind a `sessionFeedbackEnabled` flag (persisted, default `true`) so it can be toggled off at runtime without code changes; when off, only the question renders and the deck advances normally.
- The mock test should support selection-based answers (single-select and multi-select) in addition to typed text; choice options must trace to official content or the learner's own comparison, never to AI-generated distractors. Multi-select distractors are generated at runtime from other official answer variants in the same topic (capped at four, shuffled deterministically per question) rather than hand-curated, so they scale and require no JSON edits; scoring is unchanged.
- Current-answer warning scope: the slice implements the **accepted-only** warning (lenient match on an accepted answer). The copy is chosen by the evaluator verdict ("Accepted: ..." only when `evaluate()` returns true). The rejected-but-close warning is a future refinement, deferred until the accepted-only warning is validated.
- Answer evaluation is layered and offline-first: baseline is a deterministic token-set matcher; Apple Intelligence semantic evaluation is an optional enhancement with mandatory offline fallback. Semantic evaluation must trace to official content or the learner's own comparison, never to AI grading of official answers.
