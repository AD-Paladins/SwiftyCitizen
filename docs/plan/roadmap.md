# SwiftyCitizen Roadmap

Single source of truth for what is built, what is next, and what decisions are pending.
Maintained by the tech lead; update this file whenever a slice changes status.

Verified against the code on: 2026-10-08.

## Current state (per tab)

The app ships a 4-tab root navigation (`Home`, `Study`, `Practice`, `Progress`) plus a
`Settings` entry. Status is verified against the live code, not just the plan docs.

| Tab | Status | Notes |
| --- | --- | --- |
| **Home** | ✅ built + restyled | Readiness hero, streak card, config summary, "Continue studying", daily milestone, Today (reviewed + got-it rate), mastery buckets (Mastered/Due/Unseen), Due next, bookmarks, tip banner. Full design-system pass done. |
| **Study** | ✅ built + restyled | Flashcards (Leitner) + targeted review (Due / Unanswered / Needs work). Restyled to match Home. |
| **Practice** | ✅ built + restyled | Card design system (`StudyEntryCard` + value-based nav), matching Home/Study. Mock Test + Oral Practice entry points preserved. |
| **Progress** | ✅ built | readiness hero + per-topic coverage map + momentum strip, replicating Home's bookmarked-card pattern. See caveat below. |
| **Settings** | ✅ built | Test configuration, language, audio, accessibility, reset. |

## The Progress tab decision

**Problem.** `Home` already shows a live progress snapshot (readiness %, streak, Today,
mastery buckets, Due next). `Progress` is empty and it is unclear what belongs there without
duplicating Home.

**Decision.** `Home` is *look-forward* (next action); `Progress` is *look-back* (history +
depth). They are complementary, not duplicative. `Progress` owns everything that needs a
time axis or a deeper breakdown that Home's snapshot does not show.

**What lives in Progress:**

1. **Stats summary** — "how far you've come": total questions reviewed, longest streak,
   total sessions. Lowest cost; reuses/extends existing metrics.
2. **Activity timeline** — recent study sessions grouped by date with mode, question count,
   and got-it rate. Home has no history at all, so this is the clearest gap.
3. **Coverage & weak spots** — mastery breakdown recontextualized as coverage %, plus a
   "review your weakest" CTA into targeted review.

**What stays on Home:** the live snapshot (readiness %, daily target, Due next CTA, Today,
bookmarks). Progress links *into* those flows but does not re-render them.

**Alternative considered and rejected.** Merge `Progress` into `Home` and drop the tab.
Rejected: the 4-tab navigation is already approved (`screen-inventory.md` + design), and
removing a tab mid-stream is a bigger UX risk than giving it real content.

**Domain dependency (important).** `StudyProgressMetrics` currently exposes only counts and
buckets — `masteryBreakdown`, `readinessPercentage`, `streak`, `reviewedToday`. It has **no
per-topic accuracy**. A "performance by topic" view therefore requires a separate domain
slice first: add `topic` to `StudyAttemptSnapshot`, add a per-topic metric function, and
cover it with tests. That is tracked below as a follow-up, not part of the Progress MVP.

## Remaining backlog

1. **Practice redesign** — ✅ done (`bbb2d53`): card design system, Home/Study parity.
2. **Progress content** — ✅ done (`46781d0`): readiness hero + coverage map + momentum strip.
   Caveat: the roadmap decision listed three sections (stats summary, activity timeline,
   coverage & weak spots). Progress covers coverage + momentum + readiness; the **activity
   timeline** is not yet rendered (deferred, low priority).
3. **Per-topic metrics follow-up** — ✅ done (`84eedbd`): `coverageByTopic` + `TopicCoverage`,
   `wasCorrect` on snapshots. Powers the coverage map.
4. **Phase 3 — spaced repetition** — Leitner scheduler is done at the domain level; needs a
   scheduling layer over self-assessment + answer history and its UI. **NEXT.**
5. **Phase 4 — speech practice** — `SpeechManager` exists; full oral-style simulation pending.
6. **Phase 5 — intelligence features** — deferred until core content, scoring, persistence,
   and tests are proven.

## Sequence & priorities

- **Done:** Practice restyle (`bbb2d53`), Progress content (`46781d0`), per-topic metrics
   (`84eedbd`).
- **Then:** Phase 3 — spaced-repetition scheduling layer + UI (next).
- **Then:** Phase 4 speech.
- **Deferred:** Phase 5 intelligence features.

## Constraints (do not break)

- No account system, backend, or analytics in the first release (explicit non-goal).
- Self-assessment stays learner-reported and is never presented as an official passing score.
- Progress views must derive from persisted attempts/sessions; add pure domain metrics for any
  new figure rather than computing SwiftUI inline.
- Official content remains the authoritative source; SwiftData stores learner state only.
