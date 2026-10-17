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

- [x] **4.1** Oral-practice entry + placeholder — **DONE 2026-10-17**. Swift surface already gone (prior phases; `PracticeView` has only `.mockTest`). Removed 3 orphaned catalog keys with no `.swift` reader: `practiceOralPracticeEntryAction`, `practiceOralPracticeMessage`, `practiceOralPracticeTitle`. `648a154`.
- [x] **4.2** Fake Settings rows — **DONE 2026-10-17**. Rows already gone (`AppearanceSection` renders only the theme `Picker`). Removed 4 orphaned keys: `settingsStreakShield`, `settingsStreakShieldValue`, `settingsCardTextSizing`, `settingsCardTextSizingValue`. `648a154`.
- [x] **4.3** `sessionFeedbackEnabled` — **DONE 2026-10-17**. Nothing to delete: flag already absent from code; feedback always-on via `SessionFeedbackIndicator` (`Components.swift:3`, `MockTestSessionView.swift:70`). Stale references remain in docs (`current-status.md`, `phase-0.5-design-spec.md`) — doc correction deferred.
- [x] **4.4** `QuestionContent.insight` — **DONE 2026-10-17**. Nothing to delete: `insight` already removed; keep live `explanation` (flashcard explanations + TTS). No domain file touched.
- [x] **4.5** Theme swatch + Archive capsule — **DONE 2026-10-17**. Swift surface already gone (`AppearanceSection` renders only the theme `Picker`). Removed 1 orphaned key: `settingsThemePaletteSwatch`. `648a154`.
- [x] **4.6** Remove dead model fields/accessors — **DONE 2026-10-17**. `9d137f1` — removed `StudySession.startedAt`, `Bookmark.createdAt`, `QuestionAttempt.session` (all confirmed dead via full-reader grep; `FlashcardAttemptRecord.answerText` is LIVE, kept). Automatic SwiftData **lightweight** migration only (no `VersionedSchema`/`MigrationPlan`). Added `SwiftyCitizenTests/Domain/MigrationTests.swift` persistent round-trip guard (Path C — both opens use new schema; real upgrade path rests on 5.3 precedent + documented in-memory caveat, user-accepted). Updated `data-and-persistence.md`, fixed stale `TargetedReviewTests` ref. Suite 253/253 ✔. SDD cycle (explore→propose→spec→tasks→apply→archive) complete; archived to `openspec/changes/archive/2026-10-17-4.6-remove-dead-model-fields/`.
- [ ] **4.7** ✅ Fixed empty `progressTopicReviewHint` → "Opens review questions for this topic" (xcstrings stays valid). Ref D15. `b641e37`
- [ ] **4.8** ✅ Documented `DemoSeeder` in AGENTS.md as UI-test data path. Ref Decision 4. `c13e42c`

Phase 4a verify: BUILD SUCCEEDED, full suite 231/231 ✔. Net −109/+24 lines (deletion-focused). Phase 4 surface keys swept (8 orphaned catalog keys, `648a154`); broader 4.7 key sweep + 4.6 model fields deferred.
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

- [x] **4.1** Oral-practice entry + placeholder — **DONE 2026-10-17**. Swift gone; removed 3 orphaned catalog keys (`practiceOralPracticeEntryAction`, `practiceOralPracticeMessage`, `practiceOralPracticeTitle`). `648a154`.
- [x] **4.2** Fake Settings rows — **DONE 2026-10-17**. Rows gone; removed 4 orphaned keys (`settingsStreakShield`, `settingsStreakShieldValue`, `settingsCardTextSizing`, `settingsCardTextSizingValue`). `648a154`.
- [x] **4.3** `sessionFeedbackEnabled` — **DONE 2026-10-17**. Already absent from code; feedback always-on via `SessionFeedbackIndicator`. Nothing to delete.
- [x] **4.4** `QuestionContent.insight` — **DONE 2026-10-17**. Already removed; keep live `explanation`. Nothing to delete.
- [x] **4.5** Theme swatch + Archive capsule — **DONE 2026-10-17**. Swift gone; removed 1 orphaned key (`settingsThemePaletteSwatch`). `648a154`.
- [x] **4.6** Remove dead model fields/accessors. Ref D12. `9d137f1` — `StudySession.startedAt`, `Bookmark.createdAt`, `QuestionAttempt.session` removed (automatic lightweight migration; Path C round-trip guard + 5.3 precedent). Suite 253/253 ✔.
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

### Phase 5.1 — Session Summary: weak topics + one next action (M6)  ✅ COMPLETE (2026-10-17)

Commits `5680d66` (feat(study): weak topics + one next action), `1162b0e` (docs).
- **New pure domain** `SessionWeakTopics.swift` (`import Foundation` only): maps each attempt's stableID → question.topic, aggregates weak cards per topic. Weak = `.again` miss OR per-card `.gotIt` success ≤ 0.5 (same threshold as Progress "Low accuracy" queue). Honest: no invented %.
- **SessionSummaryView**: renders "Weak topics" section + one "Review your weak topics" action, ONLY when the session produced weak cards (no invented busywork). Existing output (counts, assessment rows, Done) untouched.
- **FlashcardSessionView**: computes weak topics + weak stable IDs from `state.attempts` + `state.questions`, threads them in.
- **TargetedReviewView**: additive `weakCards:` param (defaults `[]`, existing callers unchanged); opens straight at `.lowAccuracy` for the explicit set.
- **Judgment call**: recommended action uses a direct `NavigationLink` to `TargetedReviewView` (not Phase 2's `PendingNavigation`), because flashcards launch from two stacks (Study tab + Practice mock-test result) and `PendingNavigation` only fires when `StudyView` is alive. Direct link works from both; reuses the same `.lowAccuracy` deck.
Verify (independently re-run): `SessionWeakTopicsTests` ✔, worker reported full suite 248/248 + build OK.

### Phase 5.2 — About this content provenance (M2)  ✅ COMPLETE (2026-10-17)

Commit `da7aa94` (+359 lines, purely additive).
- **New pure domain** `ContentProvenance.swift` (`import Foundation` only): extracts shared `(sourceURL, sourceRevision, verificationDate)` from a version's questions; reports the true distinct-reference count (honest — "Sourced from N references" if a bank ever mixes sources).
- **ContentInformationView**: shows active test version + content source URL/revision + last-verified date. Empty/failed load degrades to "Not available," never crashes.
- **SettingsView**: new "About this content" section inserted between Appearance and DangerZone (existing sections untouched).
- Loads the active version's bank via the existing `QuestionBankLoader().load(version:)` pattern — no new/heavy loader.
Verify (independently re-run): `ContentProvenanceTests` ✔, worker reported full suite 253/253 + build OK. Pre-existing unrelated warning: SpeechManager.swift:40 AVSpeechSynthesizerDelegate isolation.

### Deferred-work scoping (2026-10-17) — risk picture for the next decision

Scoping read-only (worker could NOT run `git`/`.i18n-tooling/verify.py` this session — tool-routing fault; findings are from direct source reads, item 6 count unverified live).

**DEFER (high risk, needs deliberate care):**
- **4.6 dead model fields + migration**: ✅ **DONE 2026-10-17** (`9d137f1`). Removed `StudySession.startedAt`, `Bookmark.createdAt`, `QuestionAttempt.session` inverse (all confirmed dead; `FlashcardAttemptRecord.answerText` LIVE, kept). Automatic SwiftData lightweight migration (no plan). SDD cycle complete + archived. Real upgrade path covered by 5.3 precedent + Path C round-trip guard (user-accepted).
- **6.1 root font**: ✅ **DONE 2026-10-17** (`bbb916e` + `06aceb6`, SDD cycle complete + archived). Replaced the frozen `.environment(\.font, .system(size: 16, ...))` pin at `SwiftyCitizenApp.swift:45` with scaling `.body` → inherited-font Text/Label/Button now reflow with Dynamic Type. Suite 253/253 ✔. Probe test omitted (XCTest infeasible); on-device reflow check (task 1.7) pending manual verification. CivicText + 12 direct `.system(size:)` calls deferred to B3 (brand-locked SF Pro Rounded, accepted known limitation).

**Safe-to-now (low risk):**
- **5.1 Session Summary** (weak topics + one next action) — ✅ COMPLETE (2026-10-17), `5680d66`. Honest per-topic weakness from session attempts; recommended action reuses the `.lowAccuracy` queue via a direct `TargetedReviewView` entry that works from both flashcard origins.
- **5.2 About this content** (new ContentInformationView + Settings entry) — ✅ COMPLETE (2026-10-17), `da7aa94`.
- **5.4 Flashcard resume wiring** — small feature; only matters if interrupted sessions occur (current entry doesn't allow).
- **5.5 Bank cache** — `ProgressTabView` loads bank twice per render (perf-only, S-size).
- **6.2 Docs sync** — several stale docs (`current-status.md`, `product-plan.md`, `data-and-persistence.md`, `flow-flashcards.md`, `screen-inventory.md`). Mechanical, M-sized.

### Phase 5.5 — Bank cache (verified)  ✅ COMPLETE (2026-10-17)

Commit `cef4677` (+11/−6, ProgressTabView only).
- Introduced a single `loadedBank` load site; `topicIndex` + `bankQuestions` now derive from it (was two independent `QuestionBankLoader().load(version:)` calls per render). Behavior unchanged — view renders identically, just without the redundant file read + JSON decode.
Verify: git clean ✔, confirmed one load site (`loadedBank` :29) ✔, build OK, suite 253/253.

### Phase 6.2 — Docs sync (verified)  ✅ COMPLETE (2026-10-17)

Commit `0bae01f` (docs-only, 6 files).
- Corrected against current code: `current-status.md` (Bookmark is a live @Model; insight→explanation), `product-plan.md` (checked off own-answer M8; left oral-style deferred), `data-and-persistence.md` (deckStableIDs [String]; scheduler-based dueCount), `flow-flashcards.md` (.again persists as box-1 miss), `content-pipeline.md` (insight removed), `screen-inventory.md` (4 tabs shipped + deferred-scope note).
- "Merge Progress specs" reported, not merged — Phase 2 superseded the coverage-based hero/buckets these specs describe; left for a follow-up design decision.
Verify: git clean ✔, spot-checked deckStableIDs + Bookmark against code ✔, build OK.

- [x] **5.1** Session Summary: weak topics + one next recommended action. Ref M6. `5680d66` — `SessionWeakTopics` computes per-topic weakness from session attempts + loaded questions (.again miss or per-card .gotIt rate ≤ 0.5); `SessionSummaryView` shows a "Weak topics" section + one "Review your weak topics" action (NavigationLink to `TargetedReviewView` opened at the session's `.lowAccuracy` set). Works from both flashcard origins without cross-stack PendingNavigation.
- [x] **5.2** Settings "About this content": version, source URL, last-verified date. Ref M2. `da7aa94` — new `ContentProvenance` (pure domain) extracts shared `(sourceURL, sourceRevision, verificationDate)` from the active version's bank and reports the true distinct-reference count; `ContentInformationView` shows version + source URL/revision + last-verified ("Sourced from N references" if mixed); Settings section inserted between Appearance and DangerZone. Provenance verified consistent across uscis-2008/2025 (one ref) and 65-20 (derived, copies source).
- [x] **5.3** Remove `studyLanguage` (Decision 3, approved + done 2026-10-17). Ref D13. Display-only "Spanish study support" with zero functional effect (all exits pass `.english`/`.spanish` defaults; Spanish support cancelled). Full removal — persistence field `studyLanguageRawValue` drops via automatic SwiftData **lightweight** migration (removing a property = data dropped, no custom plan needed; verified against Apple docs + Donny Wals; app has zero explicit VersionedSchema/MigrationPlan and relies on automatic migration through v1.0.0). Scope done: domain (`StudyLanguage` enum, `.missingStudyLanguage`, validation guard), persistence (`studyLanguageRawValue` read/write sites), `TestConfigurationView` language `ConfigCard` + picker + validation case, `ConfigPreferencesSection` summary segment, `DemoSeeder`, ~15 preview/test `studyLanguage:` args, 6 string keys (`configChooseALanguage`, `configLanguageSettings`, `configMissingStudyLanguage`, `configStudyLanguageSection`, `configStudySupportLabel`, `settingsStudyLanguage`), `dependencies.md`. Verify: build OK, suite 252/252 (removed obsolete `validationFailsOnMissingLanguage`). Broader dead-field migration strategy still belongs to 4.6 (SDD).
- [~] **5.4** Flashcard session resume wiring — DEFERRED (2026-10-17): not applicable to current entry point. All exits call `endSession()` (sets `endedAt` ⇒ complete, or deletes the session), so no incomplete session exists to resume from; backgrounding doesn't interrupt (SwiftUI keeps the view). Wiring = speculative crash-only recovery (YAGNI). Resume path already built/tested (`resumeFlashcardState` + `FlashcardSessionView.init`) — small additive wiring only if a future entry point deliberately suspends a session. Zero changes.
- [x] **5.5** Cache question-bank load. Ref D14. `cef4677` — ProgressTabView loads the active version's bank once (`loadedBank`); topicIndex + bankQuestions derived from it (one load site, was two). Behavior unchanged, perf-only (+11/−6).

### Phase 6 — Hygiene + docs sync (last)

- [x] **6.1** Root font → Dynamic-Type-scaling. Ref ponytail scan. **DONE 2026-10-17** via SDD cycle (explore→propose→spec→tasks→apply→archive, archived to `openspec/changes/archive/2026-10-17-6.1-inherited-font-dynamic-type/`). Commits `bbb916e` (feat(accessibility): replace frozen `.environment(\.font, .system(size: 16, weight: .regular, design: .rounded))` at `SwiftyCitizenApp.swift:45` with scaling `.body`) + `06aceb6` (test(accessibility): add `DynamicTypeReflowTests.swift` preview rendering inherited-font Text/Label/Button at `.medium` vs `.accessibility3`). Spec synced to `openspec/specs/inherited-font-dynamic-type/spec.md`. Suite 253/253 ✔. Probe test OMITTED (XCTest has no public API to introspect the resolved SwiftUI environment font; spec scenario "Probe infeasibility falls back to preview + suite green" honored). Pending manual: task 1.7 on-device reflow check (requires physical device, cannot run headlessly). Deferred to B3 (accepted known limitation, NOT a regression): CivicText SF Pro Rounded tokens + 12 direct `.system(size:)` calls remain fixed.
- [x] **6.2** Docs sync: current-status, product-plan checkboxes, screen-inventory, data-and-persistence; merge Progress specs (reported, not merged — design decision). `0bae01f` — 6 docs corrected against current code (Bookmark @Model, deckStableIDs [String], scheduler-based dueCount, .again persists, insight→explanation, screen-inventory scope note); Progress-spec merge left for follow-up.

## Running delivery count

Authored changed lines (add+del), generated files excluded, tracked per work-unit commit. Budget ~400 lines/PR; re-evaluate when approaching.
