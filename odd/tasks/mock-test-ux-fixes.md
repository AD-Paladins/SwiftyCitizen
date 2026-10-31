# Mock Test UI/UX — Small Fixes

Feature: mock-test-ux-fixes
Route: direct inline (ODD). Small tasks, one per commit, verifiable independently.
Scope: only the mock-test setup/session UI surfaces named below. NO Apple Intelligence, NO domain model changes.

## Specs (verbatim from user + current-state.md deferred findings)

S1. "Start mock test" button must look like a tappable button (clear primary-button style, consistent with `PrimaryActionButton`).
S2. "Mode / Manual" row must either be removed or clarified; it currently implies a non-existent toggle.
S3. Incorrect feedback must stay visible for ≥2 seconds before advancing (currently ~0.8s auto-advance window for rejected answers).
S4. Wrong answers must offer skip + official-answer reveal (existing `MockTestState.skip()` + `showOfficialAnswer` disclosure — verify affordance is reachable from the card, not only from result view).

## Tasks (each is one work-unit: code + focused test + doc update if needed)

T1 (S1): Restyle mock-test setup "Start mock test" action → `PillButtonStyle` / `PrimaryActionButton`; verify it renders as a button, not a list row. Verify: build OK + visual check in simulator.
T2 (S2): Decide + apply Mode/Manual — either remove the row from `MockTestSetupView` or replace with a clear explanation (e.g., "Answer by typing your own reply"). Verify: setup screen renders without ambiguous "Mode" label.
T3 (S3): Increase rejected-answer display window in `MockTestState.advance()` / session flow to ≥2s before allowing "Next" tap (or before auto-advance if any remains). Verify: `MockTestStateTests` confirm delay / manual-advance still works.
T4 (S4): Confirm skip button + official-answer disclosure are reachable from the question card during session (not only in result view). Verify: `MockTestSessionView` shows both affordances when `!isCorrect`; `MockTestResultView` shows skipped section.

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
