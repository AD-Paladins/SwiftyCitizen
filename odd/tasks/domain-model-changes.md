# Domain Model / Logic Changes

Feature: domain-model-changes
Route: direct inline (ODD). Small, focused work units; one feature file per logical area.
Status: AUDITED (2026-11-01 autonomous pass). T1/T4/T5 verified against code; T2 decided deferred with reason; T3 defect found and fixed (skip off-by-one + missed/skipped duplication). No SwiftUI design changes; one session-view consistency fix. Full suite 282/282.

## Why separate from mock-test-ux and Apple Intelligence

- `mock-test-ux-fixes.md` = UI surfaces only (buttons, cards, timing).
- `apple-intelligence-evaluation.md` = optional AI evaluation layer (deferred, out of scope).
- This file = pure domain / SwiftData / logic: `StudyDomain`, `FlashcardState`, `MockTestState`, `StudySession` persistence, resume wiring, `AnswerEvaluator` contract.

## Specs (verbatim needs from audit + current status + deferred findings)

S1. Resume logic must stay out of `@Model` (`StudySession`). `StudyDomain.resumeFlashcardState(...)` exists (audit 1 done); verify it works for interrupted targeted-review and mock-test resume paths.
S2. Mock-test session resume wiring (`FlashcardSessionView.init` path exists but entry-point suspension is deferred — 5.4). Decide + wire if needed; else document why not needed.
S3. Session state consistency: `MockTestState.skip()` writes `skippedIDs`; result view reads from session (done, verify no drift). Confirm no orphaned `phase` / `currentIndex` after skip + advance.
S4. `AnswerEvaluator` deterministic contract must stay intact if any domain change touches evaluation input (token sets, cardinality). No semantic layer — that belongs to Apple Intelligence file.
S5. No SwiftData schema change unless explicitly required (user confirmed: no migration needed, app is development-only).

## Tasks (each one commit; no design/UX file touched)

T1 (S1): Verify `StudyDomain.resumeFlashcardState` handles both flashcard session and targeted-review deck resume; add thin regression if missing. Verify: `StudyDomainTests` / `FlashcardStateTests` pass. Status: ✅ verified — no code change. `resumeFlashcardState` (free function in `StudyDomain.swift`) is mode-agnostic: it rebuilds a `FlashcardState` from any deck via `restore(attempts:)` + `seek(to:)`. Targeted-review resume IS wired (`TargetedReviewView` → `FlashcardSessionView(resumeSession:)`); mock-test attempts are correctly excluded from flashcard resume (empty `assessmentRawValue` → nil `flashcardAttemptRecord`). `StudyDomainTests` already pins it (empty deck, missing IDs, restore+seek, index clamp) — no new regression needed. Note: the plain-flashcards entry (`StudyView`) starts fresh with no `resumeSession`; not a spec-named path.
T2 (S2): Decide mock-test session resume — either wire (small) or document deferred with reason (YAGNI, no suspend entry point exists). Verify: `MockTestStateTests` + `MockTestSessionView` init. Status: ✅ decided — DEFERRED (no code change). `MockTestState` has no restore method and its `init` always starts fresh (`currentIndex` 0, empty answers/skips); there is no suspend entry point. A mock test is a short bounded linear pass (≤ `maximumQuestionsAsked`), so restarting is cheap; the app is development-only, and partial progress is still persisted (`attempts` + `currentIndex`) for analytics even without resume. Wiring mid-test resume would be YAGNI.
T3 (S3): Confirm skip + result-view consistency: after `MockTestState.skip()`, `MockTestResultView` shows skipped section and does not duplicate into missed-questions. Verify: `MockTestResultTests`. Status: ✅ defect found + fixed in `MockTestSessionView`. (1) Off-by-one: `skipQuestion()` read `state.currentQuestion` AFTER `state.skip()` advanced the index, so it mirrored the NEXT question's stableID into `session.skippedStableIDs`; now syncs the authoritative list (`session.skippedStableIDs = state.skippedIDs`). (2) Duplication: a wrong-then-skipped question appeared in both missed and skipped; `missedQuestions`/`missedAnswers` now exclude `skippedStableIDSet` so the two sections stay disjoint. Scoring is unaffected (`answers` unchanged). No orphaned `phase`/`currentIndex`: each verdict advances exactly once (Next or Skip, never both). Regression: `MockTestStateTests.skipAfterWrongAnswerKeepsBothRecordsAndAdvancesOnce`.
T4 (S4): Confirm `AnswerEvaluator` contract: single-answer subset pass, cardinality-2 at least-two-variants pass, "answers will vary" handled, distractor options do not affect scoring. Verify: `AnswerEvaluatorTests` / `SelectionAnswerTests`. Status: ✅ verified — no code change. Single-answer subset pass (`matches` = answer ⊆ variant); cardinality-2 via `namedVariantCount >= required`; "answers will vary"/"testupdates" force `.text` input mode and are excluded from `distractorOptions` (`QuestionContent.swift` L186-205); scoring uses only `acceptedAnswerVariants` — distractors are display-only. Pinned by `SelectionAnswerTests` / `AnswerMatchTests`.
T5 (S5): Audit domain files for import violations (`import Foundation` only for pure domain; no SwiftUI/SwiftData import in `StudyDomain`, `AnswerEvaluator`, etc.). Verify: `grep` / build. Status: ✅ verified — no code change. All 17 files under `Core/Domain` import `Foundation` only; no SwiftUI or SwiftData import anywhere in the pure-domain layer.

## Verification per task

- Build: `xcodebuild build -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen ...`
- Tests: narrow suite (`SwiftyCitizenTests`) + full suite (282/282 as of the 2026-11-01 audit).
- No `Localizable.xcstrings` edit expected (domain has no user-facing strings).
- Originally expected no `Features/` edits (all tasks assumed verification-only). T3's defect turned out to live in the view's persistence mirror, so `Features/Practice/MockTestSessionView.swift` was edited; no `Components.swift` or `Shared/Theme/` file was touched.

## Non-scope (absolute)

- Mock-test button / setup card / progress picker / feedback duration — `mock-test-ux-fixes.md`.
- Apple Intelligence / semantic evaluation — `apple-intelligence-evaluation.md`.
- Design tokens (`AppTheme`, `CivicText`, `CardStyle`), theme switching, progress-hero redesign, Home Daily Launchpad — completed / out of scope.
- Accessibility audit (VoiceOver / Dynamic Type / contrast) — simulator-only deferred (item 4), separate.
- New SwiftData model fields or schema migration (user: not needed, development only).

## Notes for execution (for Jr dev)

- Read `docs/architecture/data-and-persistence.md` before touching `StudySession.swift` or `FlashcardState.swift`.
- Read `AGENTS.md` "Working Rules": pure domain files must stay `import Foundation` only.
- `StudyDomain.swift` is the resume helper; `MockTestState.swift` is the session driver; `AnswerEvaluator.swift` is the scoring contract.
- If a task needs `MockTestSetupView.swift`, stop — wrong file, go to `mock-test-ux-fixes.md`.
- If a task mentions "semantic", "AI", or "Apple Intelligence", stop — wrong file.

## Log

- L1: Autonomous audit pass (2026-11-01) — user granted full autonomy to evaluate each task against code and correct discrepancies without confirmation. T1/T4/T5 verified; T2 decided deferred with reason; T3 defect found (skip off-by-one + missed/skipped duplication) and fixed in `MockTestSessionView` with a state-level regression. Full suite re-run: 282/282.
- L2: Follow-up (out of scope here → `mock-test-ux-fixes.md`): the "Skip this question" button is only reachable AFTER a wrong answer, so the "skips without answers" scenario referenced in `endMockTest()`'s comment is unreachable through the current UI. If skip should also be available on an unanswered question, that is a UX change belonging to the mock-test-ux feature, not this domain file. Flagged for user decision; no code changed.
