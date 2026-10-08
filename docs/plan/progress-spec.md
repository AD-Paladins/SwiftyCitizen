# Progress Tab — Spec: Coverage Map

Concept verified against the code on 2026-10-08. Maintained by the tech lead.

## The idea

Progress is the **diagnostic** screen: *"Where do I stand, and what don't I know yet?"*
`Home` is look-forward (a snapshot + one next-action CTA). `Progress` is look-back and
organized by **content area (topic)**, not by time. The centerpiece is a **Coverage Map**:
the civics test rendered as topics, each lit by mastery state — answering the learner's real
anxiety, *"Am I ready to pass?"*

## Why this, and why it differs from Home

- `Home` shows readiness %, streak, Today, Due next — a live snapshot with one action.
- `Progress` shows per-topic coverage + accuracy + weak spots — a diagnostic that feeds
  targeted review.
- They complement; Progress does **not** re-render Home's cards. Reusing Home's numbers here
  would be the exact duplication we decided against in the roadmap.

## Screen composition

1. **Readiness hero** — *"You've covered N of M questions (P%)"* as a ring/progress bar. The
   visual answer to readiness; derived from `readinessPercentage` + `coveredCount`.
2. **Coverage map** — one card per topic: topic name, mastered / due / unseen counts, accuracy
   %, and a progress bar. Weak topics (low accuracy) are visually emphasized. Tapping a topic
   opens targeted review filtered to it.
3. **Momentum strip** — current streak, total reviewed, sessions this week. Reuses existing
   metrics; the smallest-cost section.
4. **Empty state** — "start a session to populate your map" when there are no attempts.

## Domain prerequisite (blocks the UI)

`StudyProgressMetrics` exposes only counts and buckets; it has **no per-topic data**, and
`QuestionAttempt` does not persist the question topic. Do **not** add a schema field. Instead
add a **pure** function that receives a topic index (`stableID → topic`, resolved once by the
content layer from the bundled bank) and returns per-topic coverage + accuracy:

```swift
struct TopicCoverage: Equatable {
    let topic: String
    let mastered: Int
    let due: Int
    let unseen: Int
    let accuracy: Double?   // .gotIt for study attempts; wasCorrect for mock-test attempts
}

enum StudyProgressMetrics {
    static func coverageByTopic(
        attempts: [StudyAttemptSnapshot],
        for version: USCISTestVersion,
        topicIndex: [String: String]   // stableID -> topic
    ) -> [TopicCoverage]
}
```

- `topicIndex` keeps `StudyProgressMetrics` SwiftData-free and unit-testable (no bank loading
  in the domain layer).
- Accuracy rule: a study attempt counts as "correct" when `assessment == .gotIt`; a mock-test
  attempt counts as correct when `wasCorrect == true`. Unseen = questions never attempted on
  that topic.
- Covered by unit tests (no SwiftUI): per-topic mastered/due/unseen, accuracy math, and empty
  handling.

## UI slice (after the domain slice)

Rebuild `ProgressTabView` with the design system (`.cardStyle()`, `CivicText`, `Space`,
`palette`) to match `HomeDashboardView` / `StudyView`. A topic card is a `NavigationLink` into
targeted review scoped by that topic — reuse `PendingNavigation` the same way Home's bookmarked
card deep-links into Study.

## Localization

New keys under the `progress*` prefix in `SwiftyCitizen/Localizable.xcstrings` (English only).

## Acceptance

- [ ] Coverage map shows every topic with mastered / due / unseen + accuracy.
- [ ] Tapping a topic opens targeted review filtered to it.
- [ ] Readiness hero reflects real coverage %.
- [ ] Empty state renders when there are no attempts.
- [ ] Build + tests pass; the per-topic metric is covered by unit tests.
