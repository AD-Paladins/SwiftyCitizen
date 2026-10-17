# Value Rebuild — Task Tracker

Feature: value-rebuild
Source of intent: `docs/plan/value-rebuild-plan.md` (2026-10-17), derived from `docs/audit/product-value-audit.md` (2026-10-16).
Route: delegated direct (ODD). Domain-first, one work unit per task (code + tests + docs in one Conventional Commit).
Engram mirror: **pending** (Engram not connected this session) — re-sync when available.

## Decision: Diagnostic Mirror vs Value Rebuild (made 2026-10-17)

The Diagnostic Mirror redesign (`ProgressAnalytics` + `ProgressTabView`, committed `4c4fcb0`, not on `main`)
encodes exactly the widgets the product-value-audit calls broken: heuristic `passRate`, "Interview Ready /
Standard met" badge (D2), back-computed hero (D3), inverted retention, `recommendation`. The value-rebuild is
the newer authoritative intent and its Phase 2 targets ~6 honest widgets, cutting those exact surfaces.

**Resolution:** value-rebuild wins for Progress. Phase 1 (data integrity, no UI) is independent of this and goes
first regardless. When we reach Phase 2 we keep the valuable, correct parts of the Diagnostic Mirror domain
(buckets shape, weakSpots, accuracyByDomain/topic coverage) but replace the heuristic/inverted/broken pieces with
honest version-scoped data; `ProgressTabView` is simplified to the honest widget set. Not decided yet: whether the
Stitch Diagnostic Mirror *design* file itself needs updating — deferred to Phase 2.

## Progress

Legend: ✅ done · 🚀 in progress · ⏳ pending · 🚫 skipped/deferred

### Phase 1 — Data integrity (domain + persistence, no UI)  ✅ COMPLETE (2026-10-17)

Commits (local branch `feat/design-aligned-redesign`):
- **1.1** ✅ `.again` now persists as box-1 miss (`FlashcardState.assess` builds & appends `FlashcardAttemptRecord`, returns it). `ef8b53e`
- **1.2** ✅ mock-test skips persisted on session (`StudySession.skippedStableIDs`), result view reads from session. `de9fa12`
- **1.3** ✅ `accuracyByWeek` + `retentionStability` now version-filtered. `959faf9`
- **1.4** ✅ `isCorrect` → mock `wasCorrect` only (`.gotIt` no longer accuracy); `dueCount` scheduler-based (single app-wide "due"). `4291685`
- **1.5** ✅ Needs Care includes unseen; In Review excludes unseen; topic counts use distinct questions (`≤ M`). `bda015e`

Verify (independently re-run this session): `ProgressAnalyticsTests` 22/22 ✔, `FlashcardLeitnerPersistenceTests` 6/6 ✔, build compiles. Worker reported full suite 231/231 + build OK.

⚠️ **Audit-staleness note for later phases:** the product-value-audit (§7) predates Phase 1. `FlashcardAttemptRecord.answerText` is now **LIVE** (used by the `.again` record) — do NOT remove it under 4.6. Re-verify every "dead field" against current code before deleting.

### Phase 4 — Cut dead/fake surfaces (independent; safe warm-up)  🚀 in progress

- [ ] **4.1** Remove oral-practice entry + placeholder. Ref M4.
- [ ] **4.2** Remove fake Settings rows: Streak Shield, Card Text Sizing. Ref §7.
- [ ] **4.3** Remove `sessionFeedbackEnabled` flag + persistence key; feedback always on. Ref §7 / Decision 2.
- [ ] **4.4** Remove `QuestionContent.insight` field + loader plumbing (verify nothing reads it). Ref D12.
- [ ] **4.5** Remove theme swatch + Archive capsule. Ref §7.
- [ ] **4.6** Remove dead model fields/accessors — **DEFERRED**: SwiftData lightweight-migration risk + some fields now live post-Phase-1. Re-evaluate against current code before touching. Ref D12.
- [ ] **4.7** ✅ Fixed empty `progressTopicReviewHint` → "Opens review questions for this topic" (xcstrings stays valid). Ref D15. `b641e37`
- [ ] **4.8** ✅ Documented `DemoSeeder` in AGENTS.md as UI-test data path. Ref Decision 4. `c13e42c`

Phase 4a verify: BUILD SUCCEEDED, full suite 231/231 ✔. Net −109/+24 lines (deletion-focused). Full key sweep + 4.6 model fields deferred.
⚠️ Git hygiene note: Phase 1 worker's reset/amend surgery left commit `959faf9` dangling (content folded into current commits; D10 verified present+tested in HEAD). Branch history is linear & clean; left the dangling commit as-is (recoverable via reflog, harmless).

### Phase 2 — Progress tab rebuild (depends on P1)  ✅ COMPLETE (2026-10-17)

Commit `c114b5b` (one work unit: code + `MockTestResult.swift` + catalog keys + tests + docs).
- **2.1 Hero** rebuilt on last mock test **scoped to active version** (`lastMockTest` filters `testVersion == version`): score `X of Y`, pass/fail, finish date + true "N of M seen". Removed heuristic %, back-computed N of M, weekly trend.
- **2.2** "Interview Ready / Standard met" badge cut (Decision 1).
- **2.3** Weak spots show question text (`D17`); queue opens exact set via new `.lowAccuracy` scope + `weakStableIDs` (closes `D8`).
- **2.4** Accuracy mock-only with honest empty state.
- **2.5** Cut: weekly trend, "Overall accuracy" dup, trajectory bars, retention, recommendation, standalone drill CTA (folded into weak-spots queue). Streak kept.
- **2.6** Empty state version-scoped ("no data for this test version").
Verify (independently re-run): `MockTestResultTests` 6/6 ✔, `TargetedReviewTests` ✔, worker reported full suite 240/240 + build OK.

### Phase 4 — Cut dead/fake surfaces (independent; safe any time)

- [ ] **4.1** Remove oral-practice entry + placeholder. Ref M4.
- [ ] **4.2** Remove fake Settings rows: Streak Shield, Card Text Sizing. Ref §7.
- [ ] **4.3** Remove `sessionFeedbackEnabled` flag (no UI writer). Ref §7 / Decision 2.
- [ ] **4.4** Remove `QuestionContent.insight` field + loader plumbing. Ref D12.
- [ ] **4.5** Remove theme swatch + Archive capsule. Ref §7.
- [ ] **4.6** Remove dead model fields/accessors (SwiftData lightweight-migration check). Ref D12.
- [ ] **4.7** Remove 32 dead keys + literal `—`; fix empty `progressTopicReviewHint`. Ref D15.
- [ ] **4.8** Document `DemoSeeder` in AGENTS.md as UI-test data path. Ref Decision 4.

### Phase 2 — Progress tab rebuild (depends on Phase 1)

- [ ] **2.1** Hero → last mock result + "N of M seen"; remove heuristic % and back-computed N of M. Ref D2, D3.
- [ ] **2.2** Remove "Interview Ready / Standard met" badge (Decision 1). Ref D2.
- [ ] **2.3** Weak spots → question text, queue CTA opens exact weak set, hide when empty. Ref D8, D17, M1.
- [ ] **2.4** Accuracy breakdown → mock-test only; honest empty state. Ref D4.
- [ ] **2.5** Remove retention widget, weekly trend arrow, recommendation card. Ref §9.
- [ ] **2.6** Empty state version-scoped. Ref D10.

### Phase 3 — Home dashboard cleanup (depends on Phase 1)

- [ ] **3.1** Remove Daily Milestone card. Ref §7.
- [ ] **3.2** Remove tip banner. Ref §7.
- [ ] **3.3** Remove readiness hero + mastery buckets from Home. Ref M10.
- [ ] **3.4** Label alignment: one "due" number app-wide. Ref M9, M10.

### Phase 3 — Home dashboard cleanup (depends on P1)  ✅ COMPLETE (2026-10-17)

Commits `5a38b05` (feat(home): remove fabricated Home widgets), `e271b77` (fix(study): correct stale due-count comment), `7f05874` (chore(localize): remove dead Home widget keys).
- **3.1** Daily Milestone card cut (`dailyTarget = 10` was fabricated; CTA duplicated Continue).
- **3.2** Tip banner cut (hardcoded `StudyTips` sample copy, day-of-year rotation).
- **3.3** Readiness hero + mastery buckets cut (Progress owns them; Home keeps greeting/streak/config/Continue/Today/Due/Bookmarked).
- **3.4** Verified: Home's "Due next" is ALREADY scheduler-based (`StudyProgressMetrics.dueCount` via `SpacedRepetitionScheduler.dueCards`) — the single app-wide "due". Fixed stale comment in `StudyView.swift:46-47` (was falsely claiming coverage-based).
- Localization: removed 10 tied keys (valid JSON, 289 en keys remain); `commonOf` untouched.
Verify (independently re-run): xcstrings valid JSON + 10 keys gone ✔, `ProgressAnalyticsTests` ✔, worker reported full suite 240/240 + build OK.

### Deferred-work scoping (2026-10-17) — risk picture for the next decision

Scoping read-only (worker could NOT run `git`/`.i18n-tooling/verify.py` this session — tool-routing fault; findings are from direct source reads, item 6 count unverified live).

**DEFER (high risk, needs deliberate care):**
- **4.6 dead model fields + migration**: `StudySession.startedAt` (dead), `Bookmark.createdAt` (dead), `QuestionAttempt.session` inverse (dead) — but `FlashcardAttemptRecord.answerText` is LIVE (Phase 1.1 uses it) and `QuestionContent.insight`→now `explanation` (live). Removing dead fields on an existing store fails with `NSCocoaErrorDomain 134110` (no `VersionedSchema`/migration plan exists). **Defer until migration strategy chosen.**
- **6.1 root font**: `.environment(\.font, .system(size: 16, ...))` at `SwiftyCitizenApp.swift:45` pins fixed size → no Dynamic Type scaling (systemic cause of known audit failures). App-wide reflow = high risk. **Defer.**

**Safe-to-now (low risk):**
- **5.1 Session Summary** (weak topics + one next action) — ✅ COMPLETE (2026-10-17), `5680d66`. Honest per-topic weakness from session attempts; recommended action reuses the `.lowAccuracy` queue via a direct `TargetedReviewView` entry that works from both flashcard origins.
- **5.2 About this content** (new ContentInformationView + Settings entry) — M-size, trust win.
- **5.4 Flashcard resume wiring** — small feature; only matters if interrupted sessions occur (current entry doesn't allow).
- **5.5 Bank cache** — `ProgressTabView` loads bank twice per render (perf-only, S-size).
- **6.2 Docs sync** — several stale docs (`current-status.md`, `product-plan.md`, `data-and-persistence.md`, `flow-flashcards.md`, `screen-inventory.md`). Mechanical, M-sized.

## Running delivery count

- [x] **5.1** Session Summary: weak topics + one next recommended action. Ref M6. `5680d66` — `SessionWeakTopics` computes per-topic weakness from session attempts + loaded questions (.again miss or per-card .gotIt rate ≤ 0.5); `SessionSummaryView` shows a "Weak topics" section + one "Review your weak topics" action (NavigationLink to `TargetedReviewView` opened at the session's `.lowAccuracy` set). Works from both flashcard origins without cross-stack PendingNavigation.
- [ ] **5.2** Settings "About this content": version, source URL, last-verified date. Ref M2.
- [ ] **5.3** Remove `studyLanguage` (Decision 3) — confirm product decision. Ref D13.
- [ ] **5.4** Flashcard session resume wiring for `.flashcards` mode. Ref M7.
- [ ] **5.5** Cache question-bank load. Ref D14.

### Phase 6 — Hygiene + docs sync (last)

- [ ] **6.1** Root font → Dynamic-Type-scaling. Ref ponytail scan.
- [ ] **6.2** Docs sync: current-status, product-plan checkboxes, screen-inventory, data-and-persistence; merge Progress specs. Ref §8, D16.

## Running delivery count

Authored changed lines (add+del), generated files excluded, tracked per work-unit commit. Budget ~400 lines/PR; re-evaluate when approaching.
