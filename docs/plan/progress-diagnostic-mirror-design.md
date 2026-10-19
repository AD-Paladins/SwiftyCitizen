# Progress Tab — "Diagnostic Mirror" Design

**Scope:** rebuild **only** the Progress tab (`ProgressTabView`) to match the Stitch screen
`Progress - Diagnostic Mirror` (project `13329010267888174190`,
`.../screens/ad7f4e8caa8344c592099b90af4a38a1`). All other Stitch screens are out of scope.
**Depends on:** T3.1 (domain scheduler, `eff0b74`), T3.2 (`ReviewDeckBuilder.due` → scheduler,
`478afc7`), T3.3 (Study due count, `0e2466f`). All verified.

---

## 1. Design → implementation mapping

Every design element is classified **derivable** (computable from existing data with a pure
function) or **gated** (needs data that is not persisted today). Gated elements are built as UI
slots but never fabricate a number — they show an honest "not enough data" state.

| # | Design element | Source / computation | Status |
|---|----------------|----------------------|--------|
| 1 | Readiness / "Predicted Pass Rate" big % | `StudyProgressMetrics.readinessPercentage` (coverage of bank) — labeled **predicted** (heuristic) | derivable |
| 2 | Weekly trend "+7% this week" | `passRateWeeklyDelta`: this-week value − prior-week value over `answeredAt` | derivable |
| 3 | "Interview Ready" verified badge | derived when readiness ≥ passing threshold (`requiredScore` of `TestConfiguration`) | derivable |
| 4 | Mastery buckets: Graduated / In Review / Needs Care | box-level + assessment + scheduler due — see §2 | derivable |
| 5 | "68 of 100 Graduated" label | graduated count vs bank count | derivable |
| 6 | "Standard met for <version>" | `standardMet`: coverage + accuracy meet threshold | derivable |
| 7 | Topic Coverage — per-topic %, "X of Y Qs" | `coverageByTopic` (mastered/due/unseen/accuracy) + topic totals from `topicIndex` | derivable |
| 8 | Accuracy Breakdown — overall + per domain | `coverageByTopic[].accuracy` per topic (uses `wasCorrect` + `gotIt`) | derivable |
| 9 | Critical Weak Spots — lowest accuracy, queue N | lowest-accuracy attempted cards; queue via `ReviewDeckBuilder.needsWork` | derivable |
| 10 | "under speed" / "recall under speed" qualifier | **needs per-answer timing** — NOT persisted | **gated** |
| 11 | Accuracy Trajectory — weekly 62%→92% (4 weeks) | `accuracyByWeek` over last N weeks | derivable |
| 12 | Study Momentum — streak | `StudyProgressMetrics.streak` | derivable |
| 13 | Retention Stability — "Remembered > 5 days" | fraction of attempted cards mastered with latest attempt > 5d ago | derivable |
| 14 | Avg Oral Speed — 2.8s | **needs per-answer timing** — NOT persisted | **gated** |
| 15 | Recommendation text | conditional heuristic over retention + trajectory | derivable |
| 16 | "Practice Diagnostic Drill (Needs Care)" CTA | navigates to `.needsWork`/`.due` deck (existing navigation) | derivable |

**Gated decision:** `answeredAt` is a timestamp only; there is no `elapsed`/`responseTime` field
anywhere in the codebase. Oral speed and "under-speed recall" cannot be computed without adding a
timing field to `QuestionAttempt` (a data-model change, out of scope). Those two slots render as
honest placeholders / are omitted, with a `ponytail:`-style note pointing to the required data
addition. Everything else matches the design.

---

## 2. Domain layer — `ProgressAnalytics` (pure, `import Foundation` only)

New type `Core/Domain/ProgressAnalytics.swift`. Operates on `[StudyAttemptSnapshot]`,
`TestConfiguration`, and plain inputs. No SwiftUI, no SwiftData, no bank loading. Deterministic
(`now: Date = .now`, `calendar: Calendar = .current` params). This mirrors the existing
`StudyProgressMetrics` pattern so it stays unit-testable in isolation.

```swift
struct ProgressAnalytics {
    // Buckets for the three-head row (Graduated / In Review / Needs Care).
    struct Buckets: Equatable { let graduated: Int; let inReview: Int; let needsCare: Int }

    // Weekly accuracy points (weekStart, accuracy?) for the trajectory chart.
    struct WeekPoint: Equatable { let weekStart: Date; let accuracy: Double?; let attempts: Int }

    // A single weak card to drill.
    struct WeakSpot: Equatable { let stableID: String; let topic: String; let accuracy: Double?; let lastAssessment: SelfAssessment? }

    // Predicted pass rate (0...1) — documented heuristic over coverage + mastery.
    static func passRate(attempts:for configuration: TestConfiguration, now: Date = .now) -> Double?
    // Delta vs the previous week (0...1); nil when <2 weeks of data.
    static func passRateWeeklyDelta(attempts:for configuration: TestConfiguration, now: Date = .now, calendar: Calendar = .current) -> Double?
    static func buckets(attempts:for configuration: TestConfiguration) -> ProgressAnalytics.Buckets
    static func standardMet(attempts:for configuration: TestConfiguration) -> Bool
    static func accuracyByDomain(attempts:topicIndex:for version: USCISTestVersion) -> [(topic: String, accuracy: Double?, count: Int)]
    static func weakSpots(attempts:questions:version:limit: Int = 8) -> [ProgressAnalytics.WeekSpot]
    static func accuracyByWeek(attempts:, weeks: Int = 4, now: Date = .now, calendar: Calendar = .current) -> [ProgressAnalytics.WeekPoint]
    static func retentionStability(attempts:, horizonDays: Int = 5, now: Date = .now, calendar: Calendar = .current) -> Double?
    static func recommendation(attempts:for configuration: TestConfiguration) -> String   // short English heuristic copy
}
```

**Bucket rules (documented, testable):**
- `graduated`: distinct cards whose latest assessment is `.gotIt` **and** `boxLevel >= 4`
  (multi-interval mastery — the design says "ready for oral exam pace").
- `inReview`: scheduler-due cards (`SpacedRepetitionScheduler.dueCards`) that are NOT graduated
  (active drill). = `dueCards.count − graduated`.
- `needsCare`: unseen cards (`boxLevel == nil`) + attempted cards whose latest assessment is
  `.again`/wrong and accuracy is low. Distinct card count.

**Pass-rate heuristic (labeled "predicted", never an official score):**
`passRate = 0.6 * coverageMastered + 0.4 * overallAccuracy`, where
`coverageMastered = graduated / questionBankCount` and `overallAccuracy` is the fraction of
correct attempts (`isCorrect`) across the version. Bounded to `0...1`. Rationale documented in-code;
tunable constants, no over-claim.

**Weak spots:** attempted cards sorted by ascending per-card accuracy (nil-accuracy unanswered are
excluded); take up to `limit`. Each maps to its topic via `topicIndex`. The queued drill reuses
`ReviewDeckBuilder.needsWork` (or `.due`) — no new scope path.

---

## 3. UI structure — `ProgressTabView` rebuild

Reuse existing primitives where they fit: `SummaryMetricView`, `.cardStyle()`, `CivicText`
(SF Pro Rounded), `Space`, `palette` (paperEmerald). New small components only when needed.

Sections in order (matches Diagnostic Mirror):

1. **Hero / readiness banner** (replaces current `readinessHero`): primary-background card with
   "Readiness" label, big predicted `%", "(covered of total)" subtitle, weekly trend with arrow,
   "Interview Ready" verified badge when `standardMet`, "Passing req: X of Y".
2. **Mastery buckets row**: three compact cells — Graduated / In Review / Needs Care — each with
   count + one-line meaning (Mastered / Active drill / Unseen-Low).
3. **"Standard met"** line (check + version name) when `standardMet` is true.
4. **Topic Coverage** (replaces current `coverageMap`): header "Are you hitting all areas?" +
   "X of Y seen", then one card per topic with icon, name, %, and "X of Y Qs" (reuse
   `topicCard` shape, extend with the "X of Y Qs" row).
5. **Accuracy Breakdown**: header + overall %; per-domain rows (icon, name, %, status label:
   High confidence / Needs review / Mastered derived from accuracy bands).
6. **Critical Weak Spots**: header + "N weak items" + the top weak cards (id + topic + accuracy) +
   a "Queue N targeted weak items" action → starts a `.needsWork` session. The "under speed"
   qualifier is OMITTED (gated).
7. **Study Momentum**: streak metric + Accuracy Trajectory over last 4 weeks (simple bar/point row;
   no charting dependency — use `ProgressView`/small bars).
8. **Retention Stability** + (ORAL SPEED OMITTED — gated): show retention % with "Remembered > 5d".
9. **Recommendation** text card (heuristic copy from `recommendation(...)`).
10. **"Practice Diagnostic Drill (Needs Care)"** CTA → navigates to the Needs-Care drill deck.

**Empty state:** keep existing `EmptyStateView` when `snapshots.isEmpty`.

**Dynamic Type:** all labels use `CivicText` semantic sizes (scale with Dynamic Type); no fixed
widths on text that can truncate. Verify at AX sizes during verification.

---

## 4. Localization (English-only, `study*`/`progress*` keys)

New keys (prefix by area; never reuse a key): `progressPredictedRate`, `progressWeeklyTrendUp`,
`progressWeeklyTrendDown`, `progressInterviewReady`, `progressPassingReq`, `progressBucketGraduated`,
`progressBucketInReview`, `progressBucketNeedsCare`, `progressStandardMet`, `progressTopicSeenOf`,
`progressAccuracyOverall`, `progressAccuracyHighConfidence`, `progressAccuracyNeedsReview`,
`progressAccuracyMastered`, `progressWeakSpotsHeader`, `progressQueueWeakItems`, `progressMomentumStreak`,
`progressTrajectoryTitle`, `progressRetentionLabel`, `progressRecommendationTitle`,
`progressDrillCTA`, `progressDrillNeedsCareLabel`. Interpolate counts around localized fragments
(the `String(localized:count:)`-with-raw-Int path does NOT compile in this Xcode 27/Swift — use the
`TargetedReviewView` interpolation pattern).

---

## 5. Tests (`SwiftyCitizenTests/ProgressAnalyticsTests.swift`)

Pure-domain tests, no UI:
- `passRate` bounded 0...1 and rises with coverage; `passRateWeeklyDelta` nil with <2 weeks.
- `buckets`: graduated requires `.gotIt` + boxLevel >= 4; inReview = due − graduated; needsCare
  includes unseen + low-accuracy.
- `standardMet` true/false by threshold.
- `accuracyByDomain` uses `wasCorrect`/`.gotIt`; weakSpots sorted ascending, capped at `limit`.
- `accuracyByWeek` groups by ISO week, accuracy correct.
- `retentionStability` counts only cards mastered with latest attempt > horizon days.

UI is covered indirectly by the full suite + a preview; no XCTest on SwiftUI here (matches repo
constraint — deeper-screen audits can't be automated pre-onboarding).

---

## 6. Constraints & non-goals

- Domain type stays `import Foundation` only — no SwiftUI/SwiftData in `ProgressAnalytics`.
- View layer resolves `topicIndex` from the bank (as `ProgressTabView` already does); domain stays pure.
- No charting dependency; trajectory rendered with native primitives.
- "Predicted Pass Rate" is explicitly a study aid heuristic, never an official passing claim
  (repo content-authority rule).
- Out of scope: oral-speed / under-speed timing metrics (need a `QuestionAttempt` timing field),
  all other Stitch screens, new persistence.
- Do not edit `project.pbxproj` (PBFileSystemSynchronizedRootGroup auto-includes new `.swift`).
