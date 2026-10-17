# SwiftyCitizen — Value Rebuild Plan

Source of intent: `docs/audit/product-value-audit.md` (2026-10-16). Defect IDs (`D*`) and mismatch IDs (`M*`) refer to that audit.

**Goal:** make every number the app shows true, remove every surface that exists to exist, and close the two trust gaps (content provenance, session feedback). No new features beyond what the product plan already promises.

> **STATUS: COMPLETE (2026-10-17).** All 6 phases executed; suite 253/253 ✔ throughout. Retained as a historical record — the plan's intent is fulfilled and its outcomes are documented in `current-status.md` ("Value rebuild — COMPLETE") and `odd/tasks/value-rebuild.md`.

## Rules

- Domain first, then UI (repo convention from `tasks.md`).
- One work unit per task: code + tests + docs in the same commit (Conventional Commits).
- Pure domain files stay `import Foundation` only; no `project.pbxproj` edits (file-system synchronized groups).
- Each phase ends green: build + full test suite.
- When execution starts, this file is mirrored to `odd/tasks/value-rebuild.md` + Engram for recovery.

## Decision register (all resolved 2026-10-16 — user approved the recommendations)

| # | Fork | Decision | Affects |
|---|------|----------|---------|
| 1 | "Standard met" badge | Remove it; the coverage line already states the true thing | 2.2 |
| 2 | `sessionFeedbackEnabled` flag | Remove (feedback always on) | 4.3 |
| 3 | `studyLanguage` setting | Remove from onboarding + settings — Spanish support was cancelled, the step does nothing | 5.3 |
| 4 | `DemoSeeder` dev backdoor (`#if FILL_USER_DATA`) | Document in AGENTS.md as the UI-test data path | 4.8 |

Metric baseline (audit §9 — assumed approved, flag any you want to flip before Phase 1):
covered = distinct questions seen in active version · due = scheduler-based, one definition everywhere · accuracy = mock-test `wasCorrect` only · hero = last mock result + coverage · retention widget removed · all metrics version-scoped.

---

## Phase 1 — Data integrity (domain + persistence, no UI)

Everything downstream reads these numbers; fix them first.

| ID | Area | Task | Ref | Size |
|----|------|------|-----|------|
| 1.1 | Study (flashcards) | Persist `.again` attempts: `assess(.again)` writes a `QuestionAttempt` (assessment `.again`, box 1); resume restores box 1. Repairs Leitner scheduler, review decks, and two Progress buckets at once | D1 | M |
| 1.2 | Practice (mock test) | Persist skipped question IDs on the session so "Review skipped" survives relaunch; targeted review can later offer a `.skipped` scope | D9 | S-M |
| 1.3 | Cross-cutting | Version-scoped metrics: pass active test version through `ProgressAnalytics` + `StudyProgressMetrics`; empty state is version-scoped, not global | D10 | M |
| 1.4 | Cross-cutting | Single definitions: one `covered` (distinct seen), one `due` (scheduler), one `accuracy` (mock-test only); delete the second formula in each pair | M9, M10, D2, D4 | M |
| 1.5 | Cross-cutting | Buckets match labels: Needs Care includes unseen; In Review = actually due; topic counts use distinct questions, not attempts | D5, D7 | S |

Verify: `ProgressAnalyticsTests`, scheduler tests, new `.again` persistence tests. No UI changes in this phase.

## Phase 2 — Progress tab rebuild (depends on Phase 1)

The worst screen; now that data is honest, cut to the widgets that drive a decision. Target: ~6 widgets from 14.

| ID | Task | Ref | Size |
|----|------|-----|------|
| 2.1 | Hero → last mock test result (score, pass/fail, date) + "N of M seen"; remove heuristic % and back-computed N of M | D2, D3 | M |
| 2.2 | ⚠️ Decision 1: remove "Interview Ready / Standard met" badge (or reduce to a plain coverage statement) | D2 | S |
| 2.3 | Weak spots → show question text (not stableID); queue CTA opens the exact weak set it counts; hide section when empty | D8, D17, M1 | M |
| 2.4 | Accuracy breakdown → mock-test only; honest empty state when no mock test taken | D4 | S-M |
| 2.5 | Remove retention widget (inverted), weekly trend arrow, recommendation card — no action behind any of them | §9 | S |
| 2.6 | Empty state version-scoped ("no data for this test version") | D10 | S |

Keep: momentum/streak, topic cards (with fixed counts), weak spots, coverage.

## Phase 3 — Home dashboard cleanup (depends on Phase 1)

| ID | Task | Ref | Size |
|----|------|-----|------|
| 3.1 | Remove Daily Milestone card (duplicate of Continue CTA, fabricated target of 10) | §7 | S |
| 3.2 | Remove tip banner (sample copy, no source) | §7 | S |
| 3.3 | Remove readiness hero + mastery buckets from Home — Progress owns them; Home keeps Continue CTA + Due next + Today + Bookmarked + config summary | M10 | M |
| 3.4 | Label alignment: one "due" number app-wide, honest labels (no "readiness" without a real formula) | M9, M10 | S |

## Phase 4 — Cut dead/fake surfaces (independent; safe any time, good first warm-up)

| ID | Screen | Task | Ref | Size |
|----|--------|------|-----|------|
| 4.1 | Practice | Remove oral-practice entry + "Planned for a later phase" placeholder | M4 | S |
| 4.2 | Settings | Remove fake rows: Streak Shield, Card Text Sizing | §7 | S |
| 4.3 | Settings | ⚠️ Decision 2: remove `sessionFeedbackEnabled` flag (no UI writer exists) | §7 | S |
| 4.4 | Content | Remove `QuestionContent.insight` field + loader plumbing | D12 | S |
| 4.5 | Home/Study | Remove theme swatch + Archive capsule (no archive feature) | §7 | S |
| 4.6 | Data | Remove dead model fields/accessors (`StudySession.startedAt`, `Bookmark.createdAt`, `QuestionAttempt.session` inverse, `FlashcardAttemptRecord.answerText`) — SwiftData lightweight-migration check required | D12 | S-M |
| 4.7 | Localization | Remove 32 dead keys + literal `—` key (verified sweep of all 297); fix empty `progressTopicReviewHint` (VoiceOver reads the raw key) | D15 | S |
| 4.8 | App | ⚠️ Decision 4: document `DemoSeeder` in AGENTS.md as the UI-test data path, or remove it | ponytail scan | S |

## Phase 5 — Product gaps: trust + loop closure

| ID | Screen | Task | Ref | Size |
|----|--------|------|-----|------|
| 5.1 | Study (session summary) | Session Summary gains weak topics + one next recommended action — the study loop currently ends in a dead end | M6 | M |
| 5.2 | Settings | "About this content": test version, source URL, last-verified date — `sourceRevision`/`verificationDate` are validated but never shown; core trust gap for a trust-focused product | M2 | S |
| 5.3 | Onboarding/Settings | ⚠️ Decision 3: remove `studyLanguage` (mandatory onboarding step with zero effect) or make it honest | D13 | S-M |
| 5.4 | Study | Flashcard session resume: wire the existing resume path for `.flashcards` mode like targeted review has | M7 | M |
| 5.5 | Data | Cache question-bank load (re-parsed from disk on every body evaluation, twice per render in Progress) | D14 | S |

## Phase 6 — Hygiene + docs sync (last)

| ID | Task | Ref | Size |
|----|------|-----|------|
| 6.1 | Root font: replace fixed `.system(size: 16, design: .rounded)` at app root (`SwiftyCitizenApp.swift:45`) with a Dynamic-Type-scaling approach — likely systemic cause of the known accessibility audit failures in Home/Practice/Progress | ponytail scan | M |
| 6.2 | Docs sync: `current-status.md`, `product-plan.md` checkboxes (incl. stale M8), `screen-inventory.md` (M1/M3/M5/M11/M12 — align docs to the real scope), `data-and-persistence.md` (D16); retire/merge the three overlapping Progress specs into one | §8, D16 | M |

---

## Sequencing

```
Phase 1 (data) ──► Phase 2 (Progress) ─┐
              └──► Phase 3 (Home)     ─┼──► Phase 6 (hygiene/docs)
Phase 4 (cuts, independent) ───────────┤
Phase 5 (gaps, independent of 2/3) ────┘
```

- Phases 2 and 3 can run in parallel once Phase 1 is green.
- Phase 4 is pure deletion: safe at any time, quick wins if you want momentum before the domain work.
- ~28 tasks total; S/M = relative difficulty (S < M < M+). Recalibrate after Phase 1 lands.
