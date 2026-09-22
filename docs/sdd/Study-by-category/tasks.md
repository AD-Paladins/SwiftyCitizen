# Tasks — Study by category

**Change**: Study by category · **Spec**: `spec.md` · **Design**: `design.md`
**Delivery**: auto-chain (stacked PRs), 400-line review budget per PR.
**Verified test command** (use for every slice):

```
xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen \
  -destination 'platform=iOS Simulator,id=11E7E98A-D558-4E53-B211-CB4ACD1FBB38' \
  -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests
```

Slicing follows the pure-builder-first strategy: slice 1 is the entire domain change, fully unit-tested and view-free; slice 2 wires the ephemeral `@State` + native UI on top. Both slices are additive and default-safe (`categories: []`), so each can be reverted independently.

---

## PR slice 1 — pure builder (Foundation-only, fully tested)

**Files:** `SwiftyCitizen/Core/Domain/ReviewDeckBuilder.swift`, `SwiftyCitizenTests/Domain/TargetedReviewTests.swift`
**Est. changed lines:** ~110 net (builder ~25, tests ~85). **Under 400: Yes.**

### Task 1.1 — Extract `scopedDeck(...)` and add optional `categories:` to `build`/`questionCount`

**START:** `ReviewDeckBuilder.build` has the version guard + scope switch inline; no `categories` parameter exists.

**FINISH:**
- Private `scopedDeck(questions:attempts:scope:) -> [QuestionContent]` holds the existing version guard (`guard let version = questions.first?.testVersion else { return [] }`) and the `unanswered`/`needsWork`/`due` switch verbatim.
- `build` calls `scopedDeck(...)` then, when `categories` is non-empty, returns `scoped.filter { categories.contains($0.topic) }` (bank order preserved by `.filter`); empty set returns the scoped deck unchanged.
- `build` signature gains `categories: Set<String> = []`; `questionCount` mirrors it and passes `categories:` through to `build`.
- No new imports; file stays `import Foundation` only.

**Verification:**
- `xcodebuild test ... -only-testing:SwiftyCitizenTests` green (existing tests still pass unchanged).
- Manual: none (pure domain).

**Rollback:** Revert the two signatures and remove `scopedDeck`; restore inline switch.

### Task 1.2 — Add `CategorySummary` value type + `categorySummary(...)`

**START:** No per-topic summary exists in the builder.

**FINISH:**
- `struct CategorySummary: Equatable { var topics: [String]; var counts: [String: Int] }` added in the builder file (`topics` = sorted unique topics; `counts` = per-topic count).
- `static func categorySummary(questions:attempts:scope:) -> CategorySummary` reuses `scopedDeck(...)` (one scope pass) and returns `topics: counts.keys.sorted()` with per-topic counts over the **scope-filtered** deck.
- Foundation-only, no new imports.

**Verification:**
- `xcodebuild test ... -only-testing:SwiftyCitizenTests` green.

**Rollback:** Delete `CategorySummary` and `categorySummary(...)`.

### Task 1.3 — Unit tests for filter + summary in `TargetedReviewTests.swift`

**START:** No category tests; only `makeQuestion(id:)` exists (single topic "Government").

**FINISH:** Add a `makeQuestion(id:topic:)` overload (default topic "Government") reusing the existing `snapshot(id:assessment:at:)` helper, plus:
- `categoryFilterEmptySetReturnsScopeDeck` — empty set returns the scope-filtered deck.
- `categoryFilterSingleTopicKeepsOnlyThatTopic` — one pill → only that topic's questions.
- `categoryFilterMultiSelectUnionsTopics` — multiple pills → union of selected topics.
- `categoryFilterComposesWithScope` — e.g. `.needsWork` + one topic → unanswered/needs-work questions of that topic only.
- `categoryFilterPreservesBankOrder` — selected questions appear in bank order.
- `categorySummaryReportsSortedTopicsAndCounts` — summary returns sorted topics + counts over the scope-filtered deck (not the whole bank).

**Verification:**
- `xcodebuild test ... -only-testing:SwiftyCitizenTests` green.

**Rollback:** Delete the six new `@Test` methods and the `makeQuestion(id:topic:)` overload.

---

## PR slice 2 — view (ephemeral state + native UI)

**Files:** `SwiftyCitizen/Features/Study/TargetedReviewView.swift`
**Est. changed lines:** ~60. **Under 400: Yes.**

### Task 2.1 — Mode toggle, category pills, pass selection to builder

**START:** View has only `@State selectedScope`; `count(for:)`/`deck(for:)` take a single scope.

**FINISH:**
- Add `@State private var byCategory = false` and `@State private var selectedCategories: Set<String> = []`.
- `count(for:)` / `deck(for:)` gain a `categories:` parameter (default `[]`) forwarded to `ReviewDeckBuilder.questionCount/build`.
- Native `Toggle("By category", isOn: $byCategory)` added as its own section above "Review scope" (apply-time layout decision — see open questions).
- Category pills: iterate `categorySummary(questions:bankQuestions, attempts:snapshots, scope: selectedScope).topics`; each pill is a toggleable chip labeled `"\(topic) (\(counts[topic] ?? 0))"`; tap toggles membership in `selectedCategories`. Selected state resolved via conditional `.tint`/`.foregroundStyle` from `selectedCategories.contains(topic)` (apply-time decision — see open questions).
- When `byCategory == true`, the deck/count passed to the start button and resume flow use `selectedCategories`; empty selection yields an empty deck and reuses the existing "Nothing to review" state (start button already gated on count > 0).

**Verification:**
- `xcodebuild test ... -only-testing:SwiftyCitizenTests` green (no new view tests; slice 1 covers filter logic).
- Manual UI: toggle switches modes; multi-select pills filter the deck; deselecting all shows "Nothing to review" with a disabled start button; toggling back to all-questions restores the full scope-filtered deck.

**Rollback:** Revert `TargetedReviewView.swift` to pre-change; slice 1 remains intact and green.

---

## Open questions (carry into apply)

- **Native chip selected state** — `.buttonStyle(.chip)` has no built-in "selected" appearance in the current SDK. Resolve visuals with conditional `.tint`/`.foregroundStyle` from `selectedCategories.contains(topic)`; prefer a native selected style if the iOS 27 GM exposes one.
- **Mode toggle placement** — decide: standalone section above "Review scope" vs inline footer of the scope section. Layout only, no behavior impact.

---

## Budget forecast

```
Decision needed before apply: No
Chained PRs recommended: Yes
400-line budget risk: Low
```

Planned work stays well under 400 lines per slice (slice 1 ~110 net, slice 2 ~60). Recommend the two chained PRs above as stacked review units; each is additive and independently revertible.
