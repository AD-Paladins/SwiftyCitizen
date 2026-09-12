# Mock Test — Selection Answers (Scope + Spec) — Slice A

Status: **Draft spec, pending implementation.** Confirmed decisions: tiles, fallback rule, lean scope (no distractors in A).

## Context

The mock test accepts typed text only today. The domain already models answer cardinality (single vs multi), so this slice adds selection-based answers (tiles) so the mock test supports single-select and multi-select without typing. Driven by the product requirement: "The mock test should support selection-based answers (single-select and multi-select), not only typed text."

## Scope

### In scope (Slice A)

- Mock-test session view: render selectable tiles instead of the `TextField`.
- Domain: per-question answer input mode (`.selection` / `.text`) via a pure presentation rule; record the selected option(s).
- Fallback rules for when selection has no value.
- Unit tests for the domain rule and selection scoring, plus UI rendering where feasible.

### Out of scope (documented)

- **Flashcards / targeted review** — another slice.
- **Fabricated / AI distractors** — rejected by the project decision log; any distractor must trace to official content. Multi-select distractors are deferred to a follow-up iteration (see Roadmap).
- **Automatic vs manual mode** — the ambiguous "Mode / Manual" setup row stays for a later iteration.

## Design decisions (confirmed)

1. **UI = tiles (buttons), not text.** Selection is the feature; text would nullify it. Mirrors existing state-management patterns (`@State`, injected managers).
2. **Options = official `acceptedAnswerVariants` only.** No distractors in A. This honors "choice options must trace to official content, never AI-generated distractors" and stays 100% deterministic with zero content curation.
3. **Fallback to text when selection has no value.** Rule: `.selection` iff the question has ≥2 accepted variants AND none of them is a free-form/variable answer (contains "answers will vary" or "testupdates"); otherwise `.text`. Detection is **content-driven, not flag-driven**: the jurisdiction flag alone does not decide the mode.

   Why the fallback exists (verified against the banks):

   - 51 of 95 single questions in `uscis-2008.json` have exactly one variant — nothing to select from.
   - Questions whose accepted variants say "Answers will vary." cannot be pre-optioned.
   - Current-answer questions point to `uscis.gov/citizenship/testupdates` (President, judges, etc.).

   Note: a question can be jurisdiction-flagged yet still use selection when its answers are fixed — e.g. `2008-036` (Cabinet positions) has 16 variants and uses tiles despite the flag.

## Domain changes

- Add `enum AnswerInputMode { case selection; case text }`.
- Add a pure, SwiftData-free presentation function: `func answerInputMode(for question: QuestionContent) -> AnswerInputMode` implementing the fallback rule above.
- Selection recording: the learner's chosen option(s) become the recorded response. Single-select records one variant; multi-select records the selected variants joined. This feeds the existing `MockTestState.record(response:)` — **no change to `AnswerEvaluator`.**
- No change to `QuestionContent` schema or the bundled banks in A.

## UI changes (`MockTestSessionView`)

- Replace the `TextField` with a tile container when `answerInputMode == .selection`.
- **Single-select** (cardinality 1): tap to select one option; submit enabled when one is selected.
- **Multi-select** (cardinality > 1): tap to toggle selection up to `cardinality` options; submit enabled when exactly `cardinality` are selected.
- **Text** (`answerInputMode == .text`): keep the existing `TextField`.
- Selection state lives in `@State` and resets on advance, matching the current answer lifecycle.

## Acceptance / tests

Domain:

- `answerInputMode` returns `.selection` for multi-variant, non-jurisdiction, non-current-answer questions; `.text` otherwise.
- Single-select scores correct when the picked variant matches an accepted variant; incorrect otherwise.
- Multi-select scores per cardinality (≥ distinct required variants).
- Jurisdiction-dependent and current-answer questions force `.text`.

UI:

- Tiles render the accepted variants.
- Submit is disabled until the selection constraint is satisfied.

## Roadmap / next iteration

Slice A delivers tiles + fallback with no distractors; multi-select in A is trivially winnable by design (all options correct).

Next iteration adds multi-select **distractors** so it discriminates. The method is to be decided **with the data in hand** (banks already loaded, ~9 multi-select questions total: 5 in `uscis-2008`, 4 in `uscis-2025`):

- **Static `distractorAnswerVariants` field** — hand-curated per question, precise; requires schema + validation changes.
- **Runtime topic-pool generation** — distractors drawn from other official answers in the same topic; deterministic, scales, no JSON edits.

The decision is gated on reviewing the multi-select questions and the topic pools before building anything.
