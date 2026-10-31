# Domain Model / Logic Changes

Feature: domain-model-changes
Route: direct inline (ODD). Small, focused work units; one feature file per logical area.
Status: deferred / partial (some done — see audit item 1 — but resume wiring, session-state consistency, and evaluation model still need work). No SwiftUI or design changes here.

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

T1 (S1): Verify `StudyDomain.resumeFlashcardState` handles both flashcard session and targeted-review deck resume; add thin regression if missing. Verify: `StudyDomainTests` / `FlashcardStateTests` pass.
T2 (S2): Decide mock-test session resume — either wire (small) or document deferred with reason (YAGNI, no suspend entry point exists). Verify: `MockTestStateTests` + `MockTestSessionView` init.
T3 (S3): Confirm skip + result-view consistency: after `MockTestState.skip()`, `MockTestResultView` shows skipped section and does not duplicate into missed-questions. Verify: `MockTestResultTests`.
T4 (S4): Confirm `AnswerEvaluator` contract: single-answer subset pass, cardinality-2 at least-two-variants pass, "answers will vary" handled, distractor options do not affect scoring. Verify: `AnswerEvaluatorTests` / `SelectionAnswerTests`.
T5 (S5): Audit domain files for import violations (`import Foundation` only for pure domain; no SwiftUI/SwiftData import in `StudyDomain`, `AnswerEvaluator`, etc.). Verify: `grep` / build.

## Verification per task

- Build: `xcodebuild build -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen ...`
- Tests: narrow suite (`SwiftyCitizenTests`) + full suite (253/253 when complete).
- No `Localizable.xcstrings` edit expected (domain has no user-facing strings).
- No `.swift` file in `Components.swift` / `Features/` / `Shared/Theme/` edited for these tasks.

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
