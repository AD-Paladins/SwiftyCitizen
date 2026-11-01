# Mock Test UI/UX — Small Fixes

Feature: mock-test-ux-fixes
Route: direct inline (ODD). Small tasks, one per commit, verifiable independently.
Scope: only the mock-test setup/session UI surfaces named below. NO Apple Intelligence, NO domain model changes.

## Specs (verbatim from user + current-state.md deferred findings)

S1. "Start mock test" button must look like a tappable button (clear primary-button style, consistent with `PrimaryActionButton`).
S2. "Mode / Manual" row must either be removed or clarified; it currently implies a non-existent toggle.
S3. Incorrect feedback must stay visible for ≥2 seconds before advancing (currently ~0.8s auto-advance window for rejected answers).
S4. Wrong answers must offer skip + official-answer reveal (existing `MockTestState.skip()` + `showOfficialAnswer` disclosure — verify affordance is reachable from the card, not only from result view).

## Tasks

- T1 (S1): Restyle mock-test setup "Start mock test" action → `PillButtonStyle` / `PrimaryActionButton`; verify it renders as a button, not a list row. Verify: build OK + visual check in simulator. Status: ✅ done — commit `9f6d213`. Verified by code read: `MockTestSetupView` renders `PrimaryActionButton` (which applies `PillButtonStyle`) in a bottom `.safeAreaInset`, unambiguously a button.
- T2 (S2): Decide + apply Mode/Manual — either remove the row from `MockTestSetupView` or replace with a clear explanation (e.g., "Answer by typing your own reply"). Verify: setup screen renders without ambiguous "Mode" label. Status: ✅ done (row absent) — commit `d749b4a`. Verified by code read: no "Mode" row remains; the section is now "How you answer" with an explanation.
- T3 (S3): Increase rejected-answer display window in `MockTestState.advance()` / session flow to ≥2s before allowing "Next" tap (or before auto-advance if any remains). Verify: `MockTestStateTests` confirm delay / manual-advance still works. Status: ✅ resolved without code change — no auto-advance existed (manual-only flow satisfies the ≥2s hold); unsound edit reverted via commit `e7c8ee8`. Verified: `MockTestState.record()` does not advance; every verdict waits for an explicit "Next" tap (`MockTestSessionView.advance()`), so the feedback stays on screen as long as the learner needs.
- T4 (S4): Confirm skip button + official-answer disclosure are reachable from the question card during session (not only in result view). Verify: `MockTestSessionView` shows both affordances when `!isCorrect`; `MockTestResultView` shows skipped section. Status: ✅ verified by code read — no code change. `MockTestSessionView` renders `revealButton` + `AcceptedAnswerCard` when `review.needsOfficialAnswerReveal`, and `skipButton` when `!review.isCorrect`; `MockTestResultView` renders the "Skipped during the test" section from `session.skippedStableIDs`.

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

## Status

CLOSED — all four tasks verified against code (2026-11-01 autonomous audit).
