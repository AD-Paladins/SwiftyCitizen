# SwiftyCitizen Current Status

Last verified: September 21, 2026

## Current state

SwiftyCitizen now has the verified content and rules foundation for the USCIS civics app, the first onboarding slice in SwiftUI, the tab-based dashboard, three working study flows (flashcards, targeted review, and mock test) backed by SwiftData persistence with resume support, and a deterministic answer evaluator for typed replies. The app correctly distinguishes 2008, 2025, and 65/20 configurations, persists a validated learner configuration, records study attempts, and renders the dashboard's Today and Due next metrics from real data.

## Visual redesign planning (started September 24, 2026)

A high-fidelity visual redesign is planned against the Google Stitch designs ("App Ciudadanía
USA", project `13329010267888174190`, read via the `stitch` MCP). The full phased plan, the
locked decisions, the design-system tokens, and the Home component breakdown live in
`docs/plan/design-redesign-plan.md`. Locked decisions: restyle the current app (keep
architecture and official content), use **SF Pro Rounded** natively instead of Stitch's Plus
Jakarta Sans (no `Info.plist`, no font bundling), and align the existing `paperEmerald` theme
to the Stitch tokens first. Phase 0 is the design-system base (colors, typography helper,
cards/buttons, spacing); the Home is the biggest single change (~13 components, ~7 of which
need logic or data that does not exist yet).

## Engineering-hygiene progress (docs/audit/code-and-architecture-audit.md)

Phase 0.5 closed on September 21, 2026. The cross-cutting audit items below are tracked in `docs/audit/code-and-architecture-audit.md`; item 4 (accessibility device review) is deferred to lowest priority and is no longer part of the 0.5 closure.

- [x] 1. Moved `StudySession.resumeState()` out of the `@Model` into pure `StudyDomain.resumeFlashcardState(...)`; the `@Model` now only exposes its persisted deck, index, and attempts plus a `flashcardAttemptRecord` projection. Tests and architecture docs updated (89 tests pass). PR: https://github.com/AD-Paladins/SwiftyCitizen/pull/1.
- [x] 2. Added thin tests for `StudyDomain`, `QuestionContent` (validator, `answerInputMode`, `distractorOptions`, `shuffleSeed`), `TestConfiguration`, and `OnboardingConfiguration` (94 tests pass).
- [x] 3. Deferred mock-test findings resolved: uniform manual advance already removes the "too brief" incorrect feedback; official-answer reveal covers "see the real answer". Added a "Skip this question" defer-to-review affordance for wrong answers (MockTestState.skip() + MockTestResultView skipped section).
- [ ] 4. Accessibility device review (VoiceOver + Dynamic Type on a real iPhone) — DEFERRED, lowest priority. The code-level VoiceOver/contrast audit is complete; only the on-device checks remain and they are no longer part of the 0.5 closure.

The audit file is deleted once all four items are complete.

## Next session — first task

### Deferred: accessibility review on a real device
The code-level VoiceOver/contrast audit is complete (verdict icon hidden in `SessionFeedbackIndicator`). The on-device checks below are deferred to lowest priority and are no longer part of the 0.5 closure; run them only when a real iPhone becomes available and nothing higher-priority is queued.

- **VoiceOver** (Settings → VoiceOver ON): navigate Home, Study (Targeted review), Mock-test session. Check each metric reads as a coherent unit, the selected scope announces "selected", the verdict → "Show official answer" disclosure → Next button reads in order and the toggle exposes its state, and tappable rows announce an action rather than being silent.
- **Dynamic Type** (Text size → max): SessionSummaryView fixed-height container (400/600) does not clip; Home metric big numbers wrap instead of truncate; Question/Answer card long text fits at max size.
- **Contrast** (visual): amber "Accepted" and green "Correct" labels read comfortably at normal brightness (code-level estimate: amber ≈3.1:1, green ≈4.4:1 — both under WCAG AA for 15pt body text).

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
- Mock-test session now shows per-answer feedback via `SessionFeedbackIndicator` (green "Correct", red "Incorrect", amber "Accepted: ...") rendered inline on the question card. `MockTestSessionView` records each answer without advancing, then shows its verdict inline and waits for a "Next" tap for every verdict (uniform manual advance), or advances immediately when the `sessionFeedbackEnabled` flag is off. The flag lives in `ThemeManager.sessionFeedbackEnabled` (`@Observable`, persisted under `sessionFeedbackEnabled`) injected via `.environment`.
- Wrong mock-test answers now offer a skip/defer affordance: below the verdict, a "Skip this question" button calls `MockTestState.skip()`, which records the question in `skippedIDs` (without appending an answer) and advances. Skipped questions surface in the result view as a distinct "Skipped during the test" section with a link to targeted review, giving the learner a durable place to revisit them later — separate from the all-wrong "Review missed questions" recap.
- Wrong mock-test answers now give the learner control: below the verdict, an expandable "Show official answer" disclosure (toggled by `showOfficialAnswer` state) reveals the accepted variants via `AcceptedAnswerCard`. The decision is driven by `MockTestAnswer.needsOfficialAnswerReveal` (`!isCorrect`). Advancing still requires a "Next" tap, so the learner can read the official answer before moving on.
- Mock-test setup UX polished: the misleading "Mode: Manual" row (which implied a toggle that does not exist) was removed and replaced with a clear "How you answer" explanation; the "Start mock test" action now renders as a floating primary button in a bottom `.safeAreaInset` so it reads unambiguously as a button rather than a list row.
- VoiceOver audit applied: the mock-test verdict icon in `SessionFeedbackIndicator` was marked `.accessibilityHidden(true)` so screen readers announce only the verdict text ("Correct"/"Incorrect"/"Accepted: …") instead of the symbol name. The official-variant checkmarks, scope checkmarks, and progress/chevron decorations were already hidden. On-device Dynamic Type / VoiceOver review still needs a real iPhone to confirm no clipping at max text sizes and to verify live focus order.
- Code-level contrast audit automated: added `testAccessibilityAudit()` to `SwiftyCitizenUITests`, which runs `XCUIElement.performAccessibilityAudit()` on the Welcome and Home screens after launch. Root cause of the failures was `.secondary`/dimmed text (only ~2.2:1 vs canvas) and small SF Symbol glyphs (e.g. the Home card chevron) that fail contrast even when `accessibilityHidden`, because the audit runs on the rendered layer. Fixed by adding a `dimmed` palette token (0.30 light / 0.70 dark) to `AppTheme` and switching small glyph images to `palette.ink`; all `.foregroundStyle(.secondary)` calls across 9 views now use `palette.dimmed`. The audit passes on both screens.
- Added a persistent `xcode27-accessibility` skill (terminal + simulator VoiceOver/Dynamic Type/contrast testing via Xcode 27 / Device Hub) and registered it in `AGENTS.md`; the code-level contrast portion of item 1 is captured here. The remaining on-device VoiceOver + Dynamic Type review still needs a real iPhone.
- Honest note on the tab-audit attempt: added `AccessibilityAuditTests` to run `performAccessibilityAudit()` on Home, Study, Practice, and Progress. It could not be automated from XCTest because reaching those tabs requires completing onboarding first (accept disclaimer + pick study language + Save), and SwiftUI `Toggle`/`Picker` controls do not map cleanly to XCTest query properties (`switchViews`/`otherViews` are unavailable) on this Xcode version. The Welcome/Home audit remains the only automated pass. Two paths under investigation to reach the deeper screens without manual entry: (a) inject a persisted config at launch, or (b) automate the flow with Maestro.
- Multi-select mock-test answers now include distractors so selection discriminates: `QuestionContent.distractorOptions(for:from:)` draws up to four distractors at runtime from other official answer variants in the same topic (excluding own variants and "answers will vary"/"testupdates"), shuffled deterministically per question. Distractors trace to official content only; scoring is unchanged — a selected distractor scores wrong through `AnswerEvaluator`. The mock-test-selection spec, flow doc, product plan, and decision log were updated to reflect this.
- Fixed a mock-test advance bug: after answering, tapping "Next" kept presenting the same question. Root cause was an inverted guard in `MockTestState.advance()` (it returned early while `phase == .active`, so `currentIndex` never incremented). The guard now returns early only when `phase == .complete`; covered by regression tests in `MockTestStateTests` and `SelectionAnswerTests`.
- The dashboard's Today and Due next sections now render real data: reviewed-today count, "Got it" rate, and the number of remaining questions in the configured set, all computed by a SwiftData-free metrics layer.
- Closed audit item 3: added thin unit tests for the previously untested core — `StudyDomain.resumeFlashcardState`, `QuestionContent` (validator, `answerInputMode`, `distractorOptions`, seeded shuffle), `TestConfiguration` static configs, and `OnboardingConfiguration` derivation/validation. The Swift Testing `Result` type shadows the Foundation one, so validator tests use `.failure`/`.success` pattern matching rather than `Result` comparison.
- Low-fidelity Penpot flows for onboarding, flashcards, mock tests, and speech fallback were aligned to the first-slice scope.
- Screen states are defined where they apply: empty states on Home (no sessions, all caught up, nothing due) and Progress; content-unavailable states in Study, Mock Test Setup, and Mock Test Session when a bank cannot load or is empty; an empty review-set state in Flashcard Session; zero-question scope footers in Targeted Review; and an inline validation error in Test Configuration that explains why Save is disabled. Loading states do not apply because question banks are bundled JSON loaded synchronously.
- Three user-selectable themes (Civic Navy, Paper & Emerald, Study Calm) are implemented: `AppTheme` defines semantic palette tokens with light/dark variants, `ThemeManager` (`@Observable`) owns the selection (persisted under `appThemeName` in UserDefaults) and is injected via `.environment`, so switching the theme in Settings re-renders the app live — including the global `.tint`. All status colors flow from palette tokens (assessment tints, pass/fail badge, validation error), replacing the old hardcoded `AppColor` and error reds, per the Phase 0.5 design decisions. Screens paint `palette.canvas` as their background so `surface` cards stay visibly elevated; the old `secondarySystemBackground`-based `surface` that no longer distinguished cards from the window was replaced by a real canvas/surface contrast.

## Phase 0.5 — closed (September 21, 2026)

Phase 0.5 is now closed. Nothing further is planned here; the items below were open at closure and are carried only for historical context. The accessibility on-device review was deferred to lowest priority (see engineering-hygiene item 4). High-fidelity direction, design handoff, the 65/20 wording, and the missed-question own-answer rendering remain as backlog candidates but are out of scope for this phase.

- Final high-fidelity direction and visual refinements. Note: the live app now renders better than the Penpot UX designs, so those designs (`docs/plan/penpot/`, outside git) are obsolete — use the live app as the source of truth.
- Formal Dynamic Type and VoiceOver review on a small viewport (the code-level accessibility audit is complete; see the design spec's audit note). No real device available right now, so this is pending but not blocking.
- Final local backup/export of the design assets (the Penpot export is saved locally under `docs/plan/penpot/`, outside git).
- Formal design handoff review before expanding beyond onboarding. Base it on the live app, not the obsolete Penpot designs.
- Wording for the 65/20 eligibility explanation and the current-answer warning pattern (both user-approved approaches; drafts pending).
- Targeted review of missed questions should show the learner's own answer next to the official one (currently only the official answer is shown; the typed reply already persists in `QuestionAttempt.answerText`).
- The mock test should support selection-based answers (single-select and multi-select), not only typed text. Slice A (tiles + fallback) is implemented and specified in `docs/plan/mock-test-selection-spec.md`; multi-select distractors are now implemented via runtime topic-pool generation (see completed list).
- **Current-answer feedback implemented:** per-answer feedback indicator for **all** verdicts (correct-exact "Correct", rejected "Incorrect", lenient-accepted "Accepted: ...") shown inline on the question card so nothing is hidden. Every verdict waits for a "Next" tap to advance (uniform manual advance). A `sessionFeedbackEnabled` flag (persisted, default true) toggles all indicators off; when off, only the question renders and the deck advances immediately. The rejected-but-close warning is deferred to a later refinement.
- **Apple Intelligence evaluation (future refinement):** layer semantic answer evaluation over the offline token-set baseline, with mandatory offline fallback and content traced to official sources.
- **State selector and jurisdiction-dependent answers (future refinement):** a state/territory selector is planned so answers like the governor resolve per state, and jurisdiction-dependent records form a modifiable content subset that Apple Intelligence can refresh on supported devices. See `docs/plan/uscis-test-rules.md` (Content That Can Change, Implementation Rules), `docs/plan/screen-inventory.md` (Test Configuration), and `docs/plan/product-plan.md` (Phase 5 Optional Intelligence Features).

## Planned features (backlog)

- **Study by category:** extend the Study tab deck builder with a category filter. Add a switch to toggle between "all" and "by category"; in category mode, surface the available categories as a list of named pills and allow selecting one or multiple. The deck is then filtered to the selected categories' questions. Builds on the existing SwiftData-free deck builder (Due / Unanswered / Needs work). Priority feature per the user.

## Deferred findings (mock test — revisit after closing the 4 phases)

Reported by the user while testing the live app against the removed 0.8s auto-advance model. These are **not** fixed yet; priority is to close the current 4 phases first, then revisit them under uniform manual advance:

- **Incorrect feedback too brief:** when the answer is incorrect, the "Incorrect" indicator flashes for less than one second (auto-advance window is 0.8s). The user wants it shown for at least two seconds before advancing.
- **No control on a failed question:** after a wrong answer there is no option to skip the question or see the official/correct answer; the deck moves on automatically. The user wants a skip option and the ability to view the real answer.
- Action once prioritized: increase the auto-advance window for rejected answers to ≥ 2s, and add skip / "see correct answer" affordances (or surface the correct answer in the review path).

Additional mock-test UI findings (same deferment):

- **"Start mock test" button doesn't look like a button** — its styling is ambiguous; the user can't tell it's tappable. Action: give it a clear primary-button style (consistent with `PrimaryActionButton`) so affordance is obvious.
- **"Mode / Manual" card lacks meaning** — the setup shows a "Mode" row defaulting to "Manual", but there is no way to choose automatic vs. manual, and nothing explains why it starts manual. Action: either remove the row or clarify its purpose (and expose an automatic mode later if needed).

## Phase 1 current slice

The flashcards and targeted-review slices are implemented: flashcard study (question, reveal, self-assessment Again / Hard / Got it, session summary), targeted review scopes (Due, Unanswered, Needs work), persistence of sessions and attempts, and resume of interrupted targeted-review sessions. The mock test slice behind Practice is also implemented: setup, manual-answer session with early pass/fail, scoring, and missed-questions review.

The visual redesign (Phase 0 design-system base + Phase 1 Home) is underway against the Stitch designs: Phase 0 (colors, typography `CivicText`, `CardStyle`/`PillButtonStyle`, `Space`) is complete, and Phase 1 slices 1 (Home restyled), 2 ("Exam Readiness" hero from a coverage-based readiness metric), 3 (Mastery breakdown: Mastered / Due / Unseen tiles), and 4 (Streak from existing attempt dates) are done. The next Phase 1 slice continues the Home backlog (Tip banner, Daily Milestone); remaining study-flow slices stay scoped to the current flows until the high-fidelity direction and accessibility review land.

### Non-goals for the next slice

- No AI-generated official content.
- No backend or account system.
- No claim that a score predicts immigration outcomes.
- No speech practice beyond an explicit fallback state.

## Decision log

- Official USCIS content remains the authoritative source; SwiftData stores learner state only, and questions are referenced by stable ID and resolved from the bundled banks.
- UI and design are allowed to evolve independently, but must obey the same version rules.
- The 2008 jurisdiction-dependent answers use the official "Answers will vary." wording from the 2025 bank until a jurisdiction-aware answer path exists.
- Phase 0.5 closed on September 21, 2026. The final high-fidelity direction and on-device accessibility review were deferred rather than completed; the phase boundary is now fixed and further work lands in later phases or the backlog.
- Self-assessment results are learner-reported and never represented as a passing score; accuracy-style metrics are labeled as "Got it" rate to avoid implying official grading.
- Three themes are preferred over a single palette so the civic-product tone is preserved while users pick a feel: Civic Navy (default), Paper & Emerald, and Study Calm. Progress is a permanent tab, typography is SF system defaults, and audio playback is deferred to Phase 4.
- Phase 0 colors done: `paperEmerald` tokens are aligned to the Stitch design-system values in `docs/plan/design-redesign-plan.md`. Ink → #1A1C19, primary (deep forest emerald) → #0B6E4F, canvas (paper) → #FDF9F1, success/mastered → #22C55E, warning/secondary amber → #E08714, danger/critical coral → #EF4444, dimmed/muted metadata → #566158 (light). Token names are unchanged so every view re-renders in sync; `surface` (#FFFFFF) and `onPrimary` (#FFFFFF) were already correct. Build and all 137 unit tests pass. Typography helper, CardStyle, and the spacing scale remain as Phase 0 items 2–4.
- Phase 0 typography done: added `CivicText` (`Shared/Theme/CivicText.swift`) mapping the Stitch named scale (display-lg … label-sm) to SF Rounded via `.system(size:weight:design:.rounded)`, and applied SF Rounded globally at the app root with `.environment(\.font, .system(design: .rounded))`. That global pass only rounds views without an explicit font style; the 67 existing semantic-style `.font(` call sites (`.headline`/`.subheadline`/`.footnote`/`.caption`) keep their non-rounded font and are intentionally deferred. They get rounded/migrated per-screen as each phase restyles its screen — the backlog and priority order live in `docs/plan/design-redesign-plan.md` (Typography migration backlog). Build and tests pass.
- Phase 0 cards + buttons done: added `CardStyle` (`Shared/UI/CardStyle.swift`, surface + radius 16–20px + warm dual shadow from the Stitch spec) and `PillButtonStyle` (`Shared/UI/PillButtonStyle.swift`, fully-rounded CTA). Applied `CardStyle` to the shared cards in `Components.swift` (AcceptedAnswerCard, EmptyStateView, ConfigurationSummaryView, SummaryMetricView; tint-filled chips like SessionFeedbackIndicator left untouched) and `PillButtonStyle` to `PrimaryActionButton`. The remaining card surfaces (old `.background(_, in: RoundedRectangle(cornerRadius: 12))` recipe) and rating/CTA buttons migrate per-screen as each phase restyles — backlog + priority live in `docs/plan/design-redesign-plan.md` (Cards + buttons migration backlog). Note: iOS 27 changed `ButtonStyle`'s requirement to `makeBody(configuration:)` (was `body`). Build and tests pass.
- Phase 0 spacing done: added `Space` (`Shared/Theme/Space.swift`, enum `xs=4, sm=8, md=16, lg=20, xl=28, 2xl=40` mirroring the CivicText pattern, plus a `.padding(_:)` extension). Applied to shared `Components.swift`: `spacing: 8` → `Space.sm.value`, `.padding(.vertical, 20)` → `Space.lg.value`, `.padding(16)` → `.padding(.md)`. Left hardcoded (no new tokens invented): `24` (page padding, ~7 sites, not in the Stitch scale), `12` (most common stack gap, not a Stitch token), tight gaps `2/6/10`, no-arg `.padding()`, and unused `40`. These map per-screen as each phase restyled — backlog lives in `docs/plan/design-redesign-plan.md` (Spacing migration backlog). Build and tests pass.
- Phase 1 slice 1 done: restyled `HomeDashboardView` with the Phase 0 base (`Space`, `CivicText`, `.cardStyle()`) instead of hardcoded radii/semantic fonts. It renders the data-backed sections that already have persisted input — a time-based greeting, the version pill (`ConfigurationSummaryView`), "Continue studying" (Start review CTA), "Today" (reviewed-today + "Got it" rate), and "Due next" (due-count card → Study). Shared `SummaryMetricView`, `ConfigurationSummaryView`, and `EmptyStateView` were restyled to `CivicText`/`Space`. Deferred until their data layer exists (backlog, later Phase 1 slices): Readiness Score, Mastery buckets, Streak, Tip banner, Daily Milestone, Focused Practice carousel, Oral Mock Interview (→ Phase 4), Weak Spots, Weekly Retention, Reading card, and the personalized "Good morning, Alex" header (no user-name field). Backlog + priority live in `docs/plan/design-redesign-plan.md` (Phase 1 progress). Build and tests pass.
- Resume support stores the deck ordering and current position per session, so interrupting a targeted-review session does not lose in-progress state.
- The mock-test evaluator compares normalized token sets against accepted variants: a single-answer question passes when the reply is a subset of an official variant, and cardinality-2 questions pass when at least two distinct variants are named. It is lenient by design (optional parentheticals, capitalization, short replies) and deterministic by construction; future speech transcription will reuse the same matcher on the transcript.
- The app corrects three bank entries where `answerCardinality` claimed two answers but the official question asks for one (2008-088, 2025-028, 2025-037); the banks still verify without schema changes.
- Targeted review of missed questions should show the learner's own wrong answer next to the official one; the typed reply already persists in `QuestionAttempt.answerText` and is carried through the mock-test result, so this is a rendering gap rather than a data gap.
- Mock-test flow uses **uniform manual advance for every verdict**: correct-exact, rejected, and lenient-accepted all show their indicator inline and wait for a "Next" tap to advance; only when `sessionFeedbackEnabled` is off does the deck advance immediately. This surfaces transparency for all verdicts instead of auto-advancing some.
- The per-answer feedback indicator is gated behind a `sessionFeedbackEnabled` flag (persisted, default `true`) so it can be toggled off at runtime without code changes; when off, only the question renders and the deck advances normally.
- The mock test should support selection-based answers (single-select and multi-select) in addition to typed text; choice options must trace to official content or the learner's own comparison, never to AI-generated distractors. Multi-select distractors are generated at runtime from other official answer variants in the same topic (capped at four, shuffled deterministically per question) rather than hand-curated, so they scale and require no JSON edits; scoring is unchanged.
- Current-answer warning scope: the slice implements the **accepted-only** warning (lenient match on an accepted answer). The copy is chosen by the evaluator verdict ("Accepted: ..." only when `evaluate()` returns true). The rejected-but-close warning is a future refinement, deferred until the accepted-only warning is validated.
- Answer evaluation is layered and offline-first: baseline is a deterministic token-set matcher; Apple Intelligence semantic evaluation is an optional enhancement with mandatory offline fallback. Semantic evaluation must trace to official content or the learner's own comparison, never to AI grading of official answers.
