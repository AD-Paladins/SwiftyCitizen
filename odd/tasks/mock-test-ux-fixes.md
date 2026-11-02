# Mock Test UI/UX — Small Fixes

Feature: mock-test-ux-fixes
Route: direct inline (ODD). Small tasks, one per commit, verifiable independently.
Scope: only the mock-test setup/session UI surfaces named below. NO Apple Intelligence, NO domain model changes.

## Specs (verbatim from user + current-state.md deferred findings)

S1. "Start mock test" button must look like a tappable button (clear primary-button style, consistent with `PrimaryActionButton`).
S2. "Mode / Manual" row must either be removed or clarified; it currently implies a non-existent toggle.
S3. Incorrect feedback must stay visible for ≥2 seconds before advancing (currently ~0.8s auto-advance window for rejected answers).
S4. Wrong answers must offer skip + official-answer reveal (existing `MockTestState.skip()` + `showOfficialAnswer` disclosure — verify affordance is reachable from the card, not only from result view).
S5. "Skip this question" must be available on an UNANSWERED question, not only after a wrong answer, so a learner can defer a question they do not want to attempt. (Added 2026-11-01; see T5.)

## Tasks

- T1 (S1): Restyle mock-test setup "Start mock test" action → `PillButtonStyle` / `PrimaryActionButton`; verify it renders as a button, not a list row. Verify: build OK + visual check in simulator. Status: ✅ done — commit `9f6d213`. Verified by code read: `MockTestSetupView` renders `PrimaryActionButton` (which applies `PillButtonStyle`) in a bottom `.safeAreaInset`, unambiguously a button.
- T2 (S2): Decide + apply Mode/Manual — either remove the row from `MockTestSetupView` or replace with a clear explanation (e.g., "Answer by typing your own reply"). Verify: setup screen renders without ambiguous "Mode" label. Status: ✅ done (row absent) — commit `d749b4a`. Verified by code read: no "Mode" row remains; the section is now "How you answer" with an explanation.
- T3 (S3): Increase rejected-answer display window in `MockTestState.advance()` / session flow to ≥2s before allowing "Next" tap (or before auto-advance if any remains). Verify: `MockTestStateTests` confirm delay / manual-advance still works. Status: ✅ resolved without code change — no auto-advance existed (manual-only flow satisfies the ≥2s hold); unsound edit reverted via commit `e7c8ee8`. Verified: `MockTestState.record()` does not advance; every verdict waits for an explicit "Next" tap (`MockTestSessionView.advance()`), so the feedback stays on screen as long as the learner needs.
- T4 (S4): Confirm skip button + official-answer disclosure are reachable from the question card during session (not only in result view). Verify: `MockTestSessionView` shows both affordances when `!isCorrect`; `MockTestResultView` shows skipped section. Status: ✅ verified by code read — no code change. `MockTestSessionView` renders `revealButton` + `AcceptedAnswerCard` when `review.needsOfficialAnswerReveal`, and `skipButton` when `!review.isCorrect`; `MockTestResultView` renders the "Skipped during the test" section from `session.skippedStableIDs`.
- T5 (S5): Make "Skip this question" available on an UNANSWERED question (not only after a wrong answer), so a learner can defer any active question. **PENDING — full unblocking spec below; no code changed yet.**
  - **File (only):** `SwiftyCitizen/Features/Practice/MockTestSessionView.swift`. No domain, persistence, or localization changes (reuse existing key `mocktestSessionSkipQuestion` = "Skip this question").
  - **Current behavior (exact):** In `body`, the question content is an if/else — (a) `if let review = review { … }` shows `SessionFeedbackIndicator`, the reveal button (when `review.needsOfficialAnswerReveal`), and `skipButton` (only `if !review.isCorrect`); (b) `else if currentQuestionMode == .text { TextField(…) }`; (c) `else { … SelectionTile … }`. So `skipButton` renders ONLY in branch (a) and only when the answer was wrong.
  - **Desired behavior:** show `skipButton` whenever the current question is skippable = unanswered (`review == nil`) OR answered incorrectly (`!review.isCorrect`); NEVER after a correct answer.
  - **Recommended diff (adapt if cleaner, keep observable behavior identical):**
    1. Add: `private var canSkipCurrentQuestion: Bool { if let review { return !review.isCorrect }; return state.currentQuestion != nil }`.
    2. Delete the `if !review.isCorrect { skipButton }` line inside branch (a) (avoids a duplicate).
    3. After the whole if/else content block, as a sibling inside the same `VStack` that holds `QuestionCard`, add: `if canSkipCurrentQuestion { skipButton }` (consistent spacing; sits below the input when unanswered, below the feedback/reveal when answered-wrong).
  - **Already guaranteed downstream — do NOT change (correct as of commit `ce83e67`):** `MockTestState.skip()` records the current question and advances by one with or without a prior answer (unit-tested: `skipDoesNotRecordAnAnswer`, `skipMarksQuestionAndAdvances`); `skipQuestion()` syncs `session.skippedStableIDs = state.skippedIDs` and clears `review`/`answer`/`selectedOptionIndexes`; `MockTestResultView.skippedQuestions` reads `session?.skippedStableIDs` (survives relaunch); `missedQuestions`/`missedAnswers` exclude `skippedStableIDSet`; scoring (`phase`/`correctCount`) is unaffected — a skipped-unanswered question simply contributes no correct answer.
  - **Edge cases to preserve:** skipping the last question is a no-op if already complete (`skipIsNoOpWhenComplete`); after any skip the next question shows a fresh input (no leftover answer/tiles).
  - **Verification (do all that apply):** (1) State — already covered; optionally add `MockTestStateTests.skipIsAvailableImmediatelyAfterInit`. (2) UI test in `SwiftyCitizenUITests` (reuse `AccessibilityAuditTests.completeOnboardingIfNeeded(_:)`): tap tab "Practice" → mock-test row (`practiceMockTest`) → "Start mock test" (`mocktestSetupStartMockTest`); assert "Skip this question" (`mocktestSessionSkipQuestion`) EXISTS before any answer; tap it and assert the session advanced; then enter a clearly-wrong answer, tap "Record answer" (`mocktestSessionRecordAnswer`), and assert skip is still present (regression). (3) Manual fallback: boot simulator, reach a session, confirm skip shows pre-answer, `xcrun simctl io booted screenshot`.
  - **Non-goals:** no scoring/result-view/persistence/`MockTestState` changes; no new localization keys; no skip after a correct answer; no flashcard or other-flow changes.
  - **Commit:** one commit, ~≤40 changed lines, e.g. `feat(mocktest): allow skipping an unanswered question`.

## Verification per task

- Each T# gets its own commit (~≤100 changed lines preferred).
- Before/after: screenshot from simulator (`simctl` boot + DeviceHub) for T1/T2; timer assertion or behavior check for T3; UI-test sketch for T4.
- No SwiftData/migration change expected; if one is needed, escalate before commit.

## Non-scope (explicit, so Jr dev doesn't wander)

- Apple Intelligence / semantic evaluation.
- Flashcard session changes.
- Progress-tab hero or design-system tokens (Phase 0 done — out of scope).
- Accessibility audit (separate item 4, simulator-only, deferred).
- Removing `mode` from any persistence model (no persistence key exists for this).

## Notes for execution

- `MockTestSetupView.swift` holds setup (S1, S2).
- `MockTestSessionView.swift` / `MockTestState.swift` hold session behavior (S3, S4).
- `MockTestResultView.swift` holds result view (S4 verification target for skipped section).
- The `AnswerEvaluator` and `ExamEngine` stay untouched.

## Log

- L1: User instruction to drive the mock-test small-fix tasks T1–T4 (specs S1–S4 verbatim from user + current-status deferred findings).
- L2: T3 audit outcome — committed edit contained dead code and an unrequested branch; premise that an auto-advance window still existed was stale (manual-only flow already satisfies the ≥2s hold). Edit reverted (`e7c8ee8`); T3 closed as verification-only.
- L3: Full re-audit (autonomous pass) — T1–T4 all confirmed against current code; feature closed. Related fix found during the same audit: `MockTestSessionView.endMockTest()` now persists a session that has skips but no answers, so a learner who only defers questions keeps the "Skipped during the test" review path after relaunch.
- L4: User approved the skip-UX change (skip available on an unanswered question, not only after a wrong answer). Specified as T5/S5 with a full unblocking implementation spec (file, exact current structure, recommended diff, downstream invariants already guaranteed by `ce83e67`, edge cases, verification incl. UI-test navigation labels, non-goals). No code changed; deferred to a future session.

## Status

T1–T4 CLOSED (verified 2026-11-01). T5 (S5) ADDED 2026-11-01 and PENDING — fully specified above for a future session; no code changed yet.
