# Design — Study by category

**Change**: Study by category · **Phase**: sdd-design (full) · **Artifact**: `docs/sdd/Study-by-category/design.md`
**Spec**: `spec.md` · **Proposal**: `proposal.md`

## Technical Approach

Pure builder first, view second. The category filter is **Foundation-only** and lives in `ReviewDeckBuilder`; the view owns only ephemeral state and rendering — mirroring the existing split where `TargetedReviewView` already delegates deck math to the builder (`count(for:)`, `deck(for:)`).

1. **Filter seam.** Add optional `categories: Set<String> = []` to `build`/`questionCount`. Extract the existing scope switch into a private `scopedDeck(questions:attempts:scope:)` so both `build` and the summary helper reuse one scope pass. Non-empty `categories` filters the scope-filtered result by `$0.topic`, preserving bank order; empty set = no filtering (every existing call/test stays identical).
2. **Summary helper.** One pure function returns sorted topics + per-category counts over the *scope-filtered* deck, so counts already reflect the chosen scope.
3. **View.** Native `Toggle` for all/by-category mode; pills from the summary; selection is `@State Set<String>`. Empty selection → empty deck → existing "Nothing to review" state (start button already gated on count > 0).

## Architecture Decisions

| Choice | Alternatives | Rationale |
|--------|--------------|-----------|
| Filter logic in `ReviewDeckBuilder` (Foundation-only) | SwiftUI `.filter { }` in the view | Keeps the pure, unit-tested seam; view stays state-only; matches `count(for:)`/`deck(for:)`; prevents filter logic leaking into SwiftUI. |
| Extract `scopedDeck(...)` private helper | Inline category filter in the scope switch | One scope pass reused by `build` and `categorySummary`; no recomputation. |
| `categories: Set<String> = []` default param | Required param / new config struct | Additive; existing callers/tests compile unchanged; empty set = no filtering. |
| `Set<String>` selection in the view | Array, or persisted model | O(1) toggle + dedup; matches existing `selectedScope` `@State`. Ephemeral (no SwiftData). |
| Native `.buttonStyle(.chip)` pills | Custom pill (`RoundedRectangle`) | iOS 27 target enables native chip; less chrome, free accessibility. Counts as label text. |
| `CategorySummary` value type in builder file | Two parallel arrays from the view | Single ordered source for pills; `Equatable`; stays Foundation-only. |

## Data Flow

```
bankQuestions + snapshots  ──► scopedDeck(scope)        (Foundation, pure)
selectedCategories Set<String> ─► filter by $0.topic   (only if non-empty)
                                        │
                                        ▼
                                 deck: [QuestionContent]
                     ┌──────────────────┴─────────────────┐
                     ▼                                    ▼
   FlashcardSessionView(questions: deck)    questionCount → Start label + gate
   empty deck → "Nothing to review" state

categorySummary(questions:attempts:scope:) ──► pills: "\(topic) (\(count))"
```

## File Changes

| File | Change | Notes |
|------|--------|-------|
| `SwiftyCitizen/Core/Domain/ReviewDeckBuilder.swift` | Modify | Add `categories:` param to `build`/`questionCount`; extract private `scopedDeck(...)`; add `categorySummary(...)` + `CategorySummary`. Foundation-only, no new imports. |
| `SwiftyCitizen/Features/Study/TargetedReviewView.swift` | Modify | `@State byCategory`, `@State selectedCategories: Set<String>`; native Toggle; pills from summary; pass `categories:` to `count(for:)`/`deck(for:)`. |
| `SwiftyCitizenTests/Domain/TargetedReviewTests.swift` | Modify | New tests reusing `makeQuestion(id:)` + `snapshot(id:assessment:)` helpers. |

## Interfaces / Contracts

**New builder API (Foundation-only):**

```swift
struct CategorySummary: Equatable {
    var topics: [String]        // sorted unique topics present in the scope-filtered deck
    var counts: [String: Int]   // per-topic count over the scope-filtered deck
}

static func build(questions:attempts:scope:categories: Set<String> = []) -> [QuestionContent]
// questionCount mirrors build with a categories: param, returns .count

static func categorySummary(questions:attempts:scope:) -> CategorySummary
```

**View state (in `TargetedReviewView`):**
- `@State private var byCategory = false` (mode toggle); `@State private var selectedCategories: Set<String> = []` (ephemeral multi-select).
- Pills iterate `categorySummary(questions:bankQuestions, attempts:snapshots, scope: selectedScope).topics`; label `"\(topic) (\(counts[topic] ?? 0))"`; tap toggles membership.

## Testing Strategy

Reuse existing helpers in `TargetedReviewTests.swift`: `makeQuestion(id:)` and `snapshot(id:assessment:)`, plus a small `makeQuestion(id:topic:)` overload to vary topics. Tests are **pure builder** unit tests (no SwiftData):

- **Filter**: empty set returns the scope deck; single/multi select keeps only selected topics in bank order; composes with `.needsWork`/`.due` scopes.
- **Summary**: reports sorted topics + per-topic counts over the scope-filtered deck (not the whole bank).

Run against the verified command (AGENTS.md):

```
xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen \
  -destination 'platform=iOS Simulator,id=11E7E98A-D558-4E53-B211-CB4ACD1FBB38' \
  -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests
```

View state is thin; filter logic is fully covered in the pure builder, so no new view tests are needed for slice 1.

## Threat Matrix

**N/A.** No routing, shell, subprocess, VCS, network, or filesystem-write boundary. The change is a pure domain filter + SwiftUI state/rendering. `QuestionContent.topic` values are read-only bank data; no new permissions or secrets.

## Migration / Rollout

Additive and default-safe: `categories: []` preserves every existing `build`/`questionCount` call and test. No SwiftData schema change, no content/bank change, no new dependency. Revert = delete the two source-file edits; nothing persisted to touch.

## Open Questions

1. **Native chip selected state** — `.buttonStyle(.chip)` has no built-in "selected" appearance in the current SDK. Resolution: drive selection visuals with a conditional `.tint`/`.foregroundStyle` from `selectedCategories.contains(topic)`. Confirm against the final iOS 27 GM; if a native selected style exists, prefer it.
2. **Mode toggle placement** — place the all/by-category Toggle as its own section above "Review scope", or inline in the scope section footer? (Layout only; no behavior impact.)

---

## Design Created

**Change**: Study by category · **Location**: `docs/sdd/Study-by-category/design.md` (Engram unavailable this session — no memory tool; durable filesystem copy only)
- **Approach**: Pure builder first — optional `categories: Set<String> = []` on `build`/`questionCount`, extracted `scopedDeck(...)` reused by a new pure `categorySummary(...)`. View owns only `@State` mode + selection; native Toggle + `.chip` pills.
- **Decisions**: filter in Foundation-only `ReviewDeckBuilder`; ephemeral `Set<String>` multi-select (no SwiftData); native chip pills (selected state via conditional tint); default empty set = additive, zero behavior change.
- **Threats**: N/A — pure domain filter + SwiftUI state; no routing/shell/VCS/network boundary.
- **Testing**: pure-builder unit tests reusing `makeQuestion`/`snapshot`; verified `-only-testing:SwiftyCitizenTests`.
- **Open Qs**: native chip selected-state rendering; mode-toggle placement.
