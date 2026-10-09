# SwiftyCitizen — Tasks

Detailed task tracker for the whole project. Status is the single source of truth for what to do next.
High-level phase intent lives in `roadmap.md`; this file breaks it into trackable tasks.

**Legend:** `✅` done · `🚀` in progress · `⏳` pending (depends) · `🚫` deferred / not starting now

---

## Phase 0.5 — Design foundation  ✅ complete

- **T0.5.1** Screen inventory (4-tab root: Home/Study/Practice/Progress + Settings) — `✅`
- **T0.5.2** Design spec (`paperEmerald`, SF Pro Rounded, card design system) — `✅`
- **T0.5.3** User checklist / design handoff — `⏳` pending items tracked in `phase-0.5-user-checklist.md`

## Phase 1 — Study / learning core  ✅ complete

- **T1.1** Flashcards (Leitner) + session bookmark toggle — `✅`
- **T1.2** Targeted review (Due / Unanswered / Needs work) — `✅`
- **T1.3** Restyle Study to match Home card system — `✅`

## Phase 2 — Practice + Progress  ✅ complete

- **T2.1** Practice restyle to card design system — `✅` (`bbb2d53`)
- **T2.2** Progress content (readiness hero + coverage map + momentum strip) — `✅` (`46781d0`)
- **T2.3** Per-topic metrics domain slice (`coverageByTopic`, `wasCorrect`) — `✅` (`84eedbd`)

## Phase 3 — Spaced repetition  🚀 in progress

Domain first, then UI. Do not touch UI before T3.2 is green.

- **T3.1** Domain — `boxLevel: Int?` on `StudyAttemptSnapshot` (default nil, populated in `QuestionAttempt.snapshot`) + pure `SpacedRepetitionScheduler.dueCards(questions, attempts, version, now)`.
  - `dueDate = answeredAt.addingTimeInterval(LeitnerScheduler.interval(forBox: boxLevel))` — `interval` returns `TimeInterval` (seconds), never `Date + interval`.
  - Keep only `isDue(dueDate, now)`; order by `dueDate` asc; unseen (`boxLevel` nil) first.
  - Tests: box2/2 days ago → due; box3/1 day ago → not due; ordering by urgency.
  - Status: `✅` done — commit `eff0b74`, verified by orchestrator; merged to local `main` via fast-forward (branch `feat/progress-and-practice`).
- **T3.2** Rewrite `ReviewDeckBuilder.due` to call the scheduler (unseen stays due → backward-compat). `✅` done — commit `478afc7` (already in `main` before PR #28); verified independently: `ReviewDeckBuilder.due` calls `SpacedRepetitionScheduler.dueCards`, ordering tested (`TargetedReviewTests`, 23/23). Orchestrator's earlier "minor note" on ordering was a misread of the `eff0b74` diff — resolved in code.
- **T3.3** UI — Study spaced-repetition view (`StudyEntryCard` + value-based nav, `paperEmerald` + SF Pro Rounded, Dynamic-Type-aware). `✅` done — commit `0e2466f`; surfaces the scheduler-driven `.due` count (unseen first, then most-overdue) two ways: a trailing "N due" badge on the Targeted Review card and a compact "Study now · N due" continuation action shown only when `dueCount > 0`. The count reuses `ReviewDeckBuilder.questionCount(.due)` (NOT the coverage-based `StudyProgressMetrics.dueCount` that Home shows as "Due next"). Verified independently: 205 tests pass.

## Phase 4 — Speech practice  🚫 pending

- **T4.1** `SpeechManager` integration + full oral-style simulation. Blocked on core (Phase 3) being proven.

## Phase 5 — Intelligence features  🚫 deferred

- **T5.x** Deferred until core content, scoring, persistence, and tests are proven.

---

## Cross-cutting / backlog (not part of a phase sequence)

- **B1** Progress — activity timeline (the 3rd section from the Phase 2 decision: stats + timeline + coverage). Only coverage + momentum were built; timeline is deferred, low priority.
- **B2** Stitch alignment — compare built screens against Stitch designs. Reference obtained via `get_screen` HTML (orchestrator cannot view images); developer compares structurally against `ProgressTabView.swift`.
- **B3** Accessibility design-system fix — make `CivicText` Dynamic-Type-aware + audit `palette` contrast pairs. Centralized fix (resolves Home/Practice/Progress at once), NOT a per-view patch. Confirmed on hardware before treating as blocking (simulator audit in Xcode 27 beta is unreliable).

---

## Current focus

**Phase 3 is complete.** T3.1 (domain), T3.2 (wiring) and T3.3 (Study spaced-repetition UI, commit `0e2466f`) are done and verified (205 tests pass). Sequence: Phase 4/5 and backlog per priority.
The developer owns implementation end-to-end; the orchestrator owns docs + architecture/quality review.
