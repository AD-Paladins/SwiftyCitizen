# Proposal: Study by category

## Intent

Targeted review scopes a deck by due/unanswered/needs-work, but there's no way to study one USCIS topic at a time. Categories already exist as `QuestionContent.topic`, so this adds a category filter with no new content model or persistence.

## Scope

### In Scope
- Toggle between "all questions" and "by category" in Targeted Review.
- Surface topics as selectable pills with counts.
- Filter the built deck to selected categories' questions.
- Unit tests for the category filter in the pure builder.

### Out of Scope
- Flashcards mode (random subset, no scope/category concept).
- Persisting category selection across sessions.
- New content model, topics, or bank changes.

## Capabilities

### New Capabilities
- `category-filter`: filter a targeted-review deck to selected `topic`s; empty set = no filtering.
- `category-summary`: sorted topics + per-category counts from the scope-filtered deck.

### Modified Capabilities
- `targeted-review`: gains an all-questions / by-category mode layered on the chosen scope.
- `deck-building`: `build`/`questionCount` accept an optional category set, applied after scope filtering.

## Approach

Pure builder first, view second.

- Add `categories: Set<String> = []` to `build`/`questionCount`; when non-empty, filter the scope-filtered result by `$0.topic`, preserving bank order.
- One pure helper returns sorted topics + per-category counts from the scope-filtered deck.
- View: native `Toggle` for mode, native `.buttonStyle(.chip)` pills over `Set(bankQuestions.map(\.topic)).sorted()`, backed by a `@State Set<String>` selection.
- Empty selection → empty deck → reuse the existing "Nothing to review" state (start button already gated on count > 0).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `SwiftyCitizen/Core/Domain/ReviewDeckBuilder.swift` | Modified | Optional `categories` param + per-category summary; stays Foundation-only. |
| `SwiftyCitizen/Features/Study/TargetedReviewView.swift` | Modified | Mode toggle, category pills, pass selection to deck/count. |
| `SwiftyCitizenTests/Domain/TargetedReviewTests.swift` | New | Cover category filter + summary in the pure builder. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| One topic dwarfs scope counts (e.g. 47/128) | Med | Show per-category counts on pills. |
| View leaks filter logic into SwiftUI | Low | Filter stays in Foundation-only builder; view manages state only. |

## Rollback Plan

Additive change with a default empty set; existing callers and tests unaffected. Revert the two source files — no schema or content impact.

## Dependencies

- Existing `QuestionContent.topic` values (2025 bank: 8 topics). No new dependency.

## Success Criteria

- [ ] Toggle switches modes.
- [ ] Pills list every topic with a count; selecting filters the deck.
- [ ] Empty selection yields an empty deck and the existing empty state.
- [ ] Category filter covered by tests; full suite green.

## Proposal question round

1. **Ephemeral vs persisted** — Recommend `@State` (ephemeral) for slice 1; persist only if desired.
2. **Single vs multi select** — Requirement allows one OR multiple. Confirm multi-select pills for slice 1?
3. **Per-category counts** — Recommend showing counts (e.g. "System of Government (47)") to signal scope.

## Proposal Created

**Change**: Study by category · **Location**: docs/sdd/Study-by-category/proposal.md (+ Engram best-effort)
- **Intent**: Topic-based category filter on Targeted Review, reusing existing `QuestionContent.topic`.
- **Scope**: 4 in; 3 deferred (flashcards, persisted selection, new content).
- **Approach**: Additive optional `categories` set on the Foundation-only builder; native Toggle + `.chip` pills; pure unit-tested filter.
- **Risk Level**: Low · **Next Step**: Ready for specs (sdd-spec) or design (sdd-design).
