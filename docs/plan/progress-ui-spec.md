# Progress Tab — UI Spec

Design for rebuilding `ProgressTabView`. Follows the same design-system conventions as
`HomeDashboardView` (`.cardStyle()`, `CivicText`, `Space`, `palette`). Read the domain spec
first: `docs/plan/progress-spec.md` (`coverageByTopic` must exist before this UI).

## Composition

`ProgressTabView` renders a vertical `ScrollView` + `VStack(spacing: Space.xl)` with
`.padding(Space.lg)`, inside a `NavigationStack`. Sections, top to bottom:

1. **Readiness hero** — mirrors Home's `readinessHeroCard`: `palette.primary` background,
   `onPrimary` text, `"homeReadinessLabel"` label, big percentage in `.metricDisplay`, and a
   subtitle `"N of M questions"`. Data: `readinessPercentage` + `coveredCount` (existing
   metrics).
2. **Coverage map** — the centerpiece. One card per topic built from `coverageByTopic(...)`.
   Each card:
   - Topic name in `.headlineSM`, `palette.ink`.
   - A progress bar (`.progressBar` style, `.tint(palette.primary)`) showing mastery %, plus a
     compact metric row: mastered (`palette.success`), due (`palette.warning`), unseen
     (`palette.dimmed`) via `SummaryMetricView`.
   - Trailing chevron (`.accessibilityHidden(true)`) — the whole card is tappable.
   - Tapping a topic opens targeted review **scoped to that topic** (see interaction below).
3. **Momentum strip** — one row of three `SummaryMetricView` (streak, total reviewed, sessions
   this week), mirroring Home's `todaySection`. Reuses existing metrics; smallest-cost section.
4. **Empty state** — when there are no attempts, replace sections 1–3 with a single
   `EmptyStateView(systemImage: "chart.bar", title: progressReadyEmptyTitle,
   message: progressReadyEmptyMessage)`.

## Interaction

A topic card navigates into targeted review filtered to that topic. Reuse the exact pattern
Home uses for its bookmarked card: set a `PendingNavigation` target from
`HomeDashboardView.openBookmarked()`, then switch the tab to Study — `StudyView` performs the
navigation and `TargetedReviewView` consumes + clears the pending scope. Pass the selected
topic through the same `PendingNavigation` channel (add a `scopedTopic` field if it does not
exist yet).

## Data flow

- The view resolves `topicIndex: [String: String]` (stableID → topic) once from the bundled
  bank via the content loader and passes it to `StudyProgressMetrics.coverageByTopic(...)`.
- The domain stays pure; the view only presents the returned `[TopicCoverage]`.
- No loading state: question banks are bundled and loaded synchronously.

## Localization

New keys under the `progress*` prefix in `SwiftyCitizen/Localizable.xcstrings` (English only):
`progressTitle`, `progressReadyEmptyTitle`, `progressReadyEmptyMessage`, plus any topic-card /
momentum labels. Reuse Home's existing metric/label keys where they fit.

## Acceptance

- [ ] Readiness hero reflects real coverage %.
- [ ] One topic card per topic with mastery bar + mastered/due/unseen counts.
- [ ] Tapping a topic opens targeted review scoped to it.
- [ ] Momentum strip shows streak / total reviewed / sessions.
- [ ] Empty state renders when there are no attempts.
- [ ] Visual consistency with Home/Study (cards, typography, spacing, tints).
- [ ] Build + tests pass.
