# Mock Test — Selection Answers (Scope + Spec) — Slice A

Status: **implemented.** Slice A is coded and covered by unit tests: tiles + content-driven fallback rule, no distractors. Verified build and 73 passing tests.

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
- Content-driven mode: `.selection` when a question has ≥2 fixed official variants (none containing "answers will vary"/"testupdates"), otherwise `.text`. The jurisdiction flag alone does not decide — e.g. `2008-036` is jurisdiction-flagged yet uses tiles.

UI:

- Tiles render the accepted variants.
- Submit is disabled until the selection constraint is satisfied.

## Roadmap / next iteration

Slice A delivers tiles + fallback with no distractors; multi-select in A is trivially winnable by design (all options correct).

Next iteration adds multi-select **distractors** so it discriminates. The method is to be decided **with the data in hand** (banks already loaded, ~9 multi-select questions total: 5 in `uscis-2008`, 4 in `uscis-2025`):

- **Static `distractorAnswerVariants` field** — hand-curated per question, precise; requires schema + validation changes.
- **Runtime topic-pool generation** — distractors drawn from other official answers in the same topic; deterministic, scales, no JSON edits.

The decision is gated on reviewing the multi-select questions and the topic pools before building anything.

## Slice B — Multi-select Distractors (implemented)

Status: **implemented.** Runtime topic-pool generation; no JSON or schema edits. Covered by unit tests.

### Method

- Distractors are drawn at runtime from other official answer variants in the **same topic** as the question, not hand-curated per question and not AI-generated.
- `QuestionContent.distractorOptions(for:from:)` returns up to four candidate strings (capped at four) filtered to exclude the question's own accepted variants, empty strings, and any variant containing "answers will vary" or "testupdates". The pool is sorted for determinism; the view shuffles it with a per-question seeded shuffle (`QuestionContent.shuffleSeed(for:)` + `Array.seededShuffled(seed:)`) so the tile order is reproducible across launches.
- The view builds each selection's options as `acceptedAnswerVariants + distractors`, shuffled. Selection state indexes into these combined options, and the recorded response is the selected option text joined — so a distractor that happens to be selected simply scores wrong through the unchanged `AnswerEvaluator`.

### Domain changes

- Added `QuestionContent.distractorOptions(for:from:) -> [String]` (pure, SwiftData-free).
- Added `QuestionContent.shuffleSeed(for:)` (FNV-1a 64-bit hash of the stable ID) and `Array.seededShuffled(seed:)` (Fisher-Yates over a seeded xorshift RNG) so shuffling is deterministic and testable.

### UI changes (`MockTestSessionView`)

- The view now caches the loaded bank once (stored `let bank`) instead of reloading it per question, and computes `currentTileOptions` from the current question's accepted variants plus its distractors.
- Selection tiles render the combined options; single-select still selects one, multi-select still toggles up to `cardinality` options; submit is enabled when exactly `cardinality` options are selected.

### Acceptance / tests

- Distractor pool is deterministic (same question + bank → same pool) and never overlaps the accepted variants.
- Variable-answer variants ("answers will vary", "testupdates") are excluded from the pool.
- The pool is capped at four; a topic with only the question itself yields no distractors.
- Selecting a distractor scores incorrect through the unchanged evaluator.
- Seeded shuffle is deterministic and preserves the multiset of options.

### Scope notes

- Distractors only appear for multi-select questions (cardinality > 1), which already use `.selection` mode; single-select questions keep their one accepted variant.
- Scoring, early pass/fail, and persistence are unchanged; distractors add presentation-only discrimination.
