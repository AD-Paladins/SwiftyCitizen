# Apple Intelligence — Mock-Test Semantic Evaluation

Feature: apple-intelligence-evaluation
Route: deferred / not started
Status: **NOT implemented; out of scope** (per user decision 2026-10-31, `current-status.md`, `mem_save` 43).

## Why this file exists (separate, not mixed)

This is its own ODD feature file so the mock-test UX (`mock-test-ux-fixes.md`) stays clean, and domain model work (`domain-model-changes.md`) never touches Apple Intelligence logic. **No task in either of those files references this file.**

## Specs (verbatim from `current-status.md` / `uscis-test-rules.md`)

S1. Optional enhancement over the offline token-set `AnswerEvaluator`: Apple Intelligence semantic layer evaluates mock-test typed replies.
S2. Mandatory offline fallback: if Apple Intelligence unavailable or fails, the deterministic token-set matcher (`AnswerEvaluator`) must win unconditionally.
S3. Content provenance: any AI-evaluated result must trace to official source content or the learner's own comparison; never AI grading of official answers.
S4. No new persistence schema required at this stage (evaluation is session-time, not persisted per answer).

## Tasks (DEFERRED — do not start without explicit user authorization)

T1 (S1): Research / confirm Apple Intelligence APIs for offline-first text evaluation (local model / framework availability, not network-only). Verify: design doc, no code.
T2 (S2): Design offline-fallback contract (`AnswerEvaluator` always wins when AI unavailable). Verify: spec update only.
T3 (S3): Design provenance-tracking mechanism (tie AI verdict to official source reference). Verify: architecture doc.
T4 (S4): Confirm no SwiftData model change needed (session-time only). Verify: `data-and-persistence.md` check — must stay unchanged.

## Verification per task (when / if started)

- Each T gets its own commit; no merge with mock-test UX or model work.
- Before any code: user must explicitly re-authorize (current status = deferred, out of scope).
- Must not break `AnswerEvaluator` deterministic contract (existing 253 tests).

## Non-scope (absolute — Jr dev must not enter)

- Mock-test button / mode / feedback / skip fixes (those are `mock-test-ux-fixes.md`).
- Domain / SwiftData model changes (`domain-model-changes.md`).
- Any change to `AnswerEvaluator` token-set matcher until T2 contract is finalized.
- Any network-requiring service (must stay offline-first).
- Any delivery / publish / CI change.

## Notes for execution (for Jr dev)

- Read `docs/plan/uscis-test-rules.md` (§ "Implementation Rules") for the Apple Intelligence rule before touching anything.
- `AnswerEvaluator.swift` is the existing deterministic baseline — touch only after T2 is approved.
- If you find yourself editing `MockTestSessionView.swift` for this feature, you are in the wrong file; stop.
- If you find yourself adding SwiftData fields, you are in the wrong feature; stop (see `domain-model-changes.md`).
