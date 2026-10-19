# SwiftyCitizen — Product Value & Code Audit

Date: 2026-10-16
Method: three independent read-only passes (screens/flows vs. product docs; data layer & learning logic with a Progress deep dive; over-engineering/dead-code scan), cross-checked against `docs/plan/` intent documents and verified against source.

## 1. Executive Summary

The **core loop is real and solid**: onboarding → flashcards (Leitner) → targeted review → mock test (official rules, deterministic scoring) → review of missed questions. The content/rules foundation complies with `uscis-test-rules.md` (bank counts, passing scores, early pass/fail all verified correct).

The problem is everything **around** the core loop. The app has accumulated features that exist only to exist:

- One **dead entry point** (Oral Practice — a "Start" button leading to a "Planned for a later phase" card).
- Two **fake Settings rows** (Streak Shield, Card Text Sizing) that render state no code provides.
- A **required onboarding setting with zero effect** (study language — Spanish support was cancelled).
- Home and Progress show the **same metrics with different formulas**, so a learner sees two contradictory "readiness" numbers in one app.
- The **Progress tab is structurally broken, not cosmetically**: of 14 rendered widgets, only 4 drive a real decision. The hero number is an invented heuristic relabeled "Readiness"; the "Interview Ready / Standard met" badge compares bank *coverage* against the *passing fraction of questions asked* (a category error that contradicts the USCIS rules); the retention metric **drops when you study**; and the whole accuracy layer silently treats "Got it" self-assessment as correctness.
- The app's own product plan says *"No automatic promise that a readiness score predicts USCIS outcomes"* — yet Progress displays exactly that, unlabeled.

The single highest-leverage code fix is persisting `.again` attempts: today the strongest negative signal a learner can give is **discarded**, which corrupts the Leitner scheduler, the review decks, and two Progress buckets at once.

Top actions (detail in §10): 1) persist `.again`, 2) rebuild the Progress hero on honest data (last mock test + coverage), 3) cut the dead/fake surfaces, 4) one definition per metric app-wide, 5) scope all Progress metrics to the active test version.

## 2. What the App Is Supposed to Be (per docs)

From `product-plan.md` and `screen-inventory.md`:

- **Purpose**: offline-first iOS study app for the USCIS naturalization civics test. Study official questions, practice answers, measure progress — no account, no backend, no generative AI.
- **Core loop**: Learn (flashcards) → Drill (targeted review) → Simulate (mock test with official rules) → Know (progress).
- **Trust is the product**: official content versioned and validated; source/verification visible; self-assessment never presented as a passing score; no readiness claim that predicts USCIS outcomes.
- **Explicit non-goals**: no accounts/cloud/analytics, no AI-generated distractors or content, no probability-of-passing claims, no assumption that every learner takes the 2025 test.

## 3. What the App Actually Does

Navigation (verified in code): `SwiftyCitizenApp → ContentView` (no config → Welcome → Test Configuration; config exists → `MainTabView`). Four tabs — Home, Study, Practice, Progress. Settings is a push from Home's toolbar (the inventory specifies it as a fifth tab). Cross-tab deep links go through `PendingNavigation` (`App/AppCoordination.swift:12-34`). No sheets anywhere.

| Screen | Verdict | Notes |
| --- | --- | --- |
| Welcome (`App/ContentView.swift:32-69`) | Core | Static hero + disclaimer → Test Configuration. |
| Test Configuration (`Features/Configuration/TestConfigurationView.swift`) | Core | Every control feeds validation; Save persists. Study-language picker is a no-op (see §5-D13). |
| Home Dashboard (`Features/Home/HomeDashboardView.swift`) | Core + filler | 4 of 5 tappable elements just switch to the Study tab; only Bookmarked deep-links a scope. Carries decorative filler: Daily Milestone, tip banner (see §7). Duplicates Progress metrics with different formulas (§5-D6/D10). |
| Settings (`Features/Settings/SettingsView.swift`) | Supporting | Config edit ✓, theme ✓, reset ✓. Two fake rows: "Streak Shield: 1 active" and "Card Text Sizing: Dignified Large" — no control, no state, no behavior (`AppearanceSection.swift:21,23`). |
| Study hub (`Features/Study/StudyView.swift`) | Core | Due banner + flashcards + targeted review; consumes deep links. |
| Flashcard Session (`Features/Study/FlashcardSessionView.swift`) | Core | Reveal → self-assess (Again/Hard/Mastered) → Leitner box, TTS, own-answer comparison, bookmark, resume (targeted only). `.again` writes nothing (§5-D1). |
| Session Summary (`Features/Study/SessionSummaryView.swift`) | Supporting, partial | Shows counts only; the documented "weak topics + next recommended action" are missing. |
| Targeted Review (`Features/Study/TargetedReviewView.swift`) | Core | 4 scopes with live counts, category filter, resume row. |
| Practice hub (`Features/Practice/PracticeView.swift`) | Half dead | Mock test ✓; Oral Practice card → static placeholder, action label literally "Start" (§7-1). |
| Mock Test Setup / Session / Result (`Features/Practice/MockTest*.swift`) | Core | Rules surfaced before start; deterministic scoring; early pass/fail; missed + skipped link into review. Skips are not persisted (§5-D9). |
| Progress (`Features/Progress/ProgressTabView.swift`) | **Structurally broken** | See §6. |

## 4. Inconsistencies: Docs vs Code

| # | Mismatch | Evidence |
| --- | --- | --- |
| M1 | Question Detail screen (inventory) does not exist. Weak-spot rows show a raw stable ID and tap to a *topic* scope, not the question. | `screen-inventory.md:30`; `ProgressTabView.swift:419-440` |
| M2 | Content Information screen does not exist. `sourceRevision`/`verificationDate` are validated but never shown — a trust gap for a trust-focused product. | `screen-inventory.md:32`; `QuestionContent.swift:132-142` |
| M3 | Permissions & Availability screen doesn't exist — and there is no speech recognition at all. `SpeechManager` is TTS-only (`AVSpeechSynthesizer`). Phase 4 unimplemented. | `screen-inventory.md:33`; `Features/Study/SpeechManager.swift:1-44` |
| M4 | Oral practice is a *primary study mode* in the product plan; the only entry is a dead-end placeholder with a "Start" label. | `product-plan.md:12`; `PracticeView.swift:33-42,53-58` |
| M5 | Settings scope far smaller than documented (no audio/accessibility/notifications sections). | `screen-inventory.md:31`; `SettingsView.swift:14-47` |
| M6 | Session Summary missing documented weak topics + next action. | `screen-inventory.md:24`; `SessionSummaryView.swift:32-39` |
| M7 | "Sessions can be exited and resumed" is half true: resume exists for targeted review only; no UI ever resumes a flashcard session. | `TargetedReviewView.swift:40-44`; `StudyView.swift:63-64` |
| M8 | Stale doc: Phase 2 "show learner's own wrong answer" is unchecked but implemented. | `product-plan.md:170`; `FlashcardSessionView.swift:544-551` |
| M9 | Two different "due" numbers: Home = bank − covered (unseen count); Study = scheduler due. Code comment admits the split. | `StudyProgressMetrics.swift:80-86`; `StudyView.swift:46-47` |
| M10 | Two different "readiness" percentages with near-identical labels: Home = coverage/bank; Progress = 0.6·graduated + 0.4·accuracy heuristic. | `StudyProgressMetrics.swift:95-102`; `ProgressAnalytics.swift:59-75` |
| M11 | Navigation model differs: inventory specifies 5 tabs incl. Settings; app has 4 tabs, Settings pushed from Home. | `screen-inventory.md:9-13`; `App/AppTab.swift:3-8` |
| M12 | Mock Test Setup "audio behavior" (inventory) is not configurable; TTS exists only in flashcards. | `screen-inventory.md:26`; `MockTestSetupView.swift:10-51` |

## 5. Data & Logic Defects (ranked)

Journey trace: onboarding writes one config row; flashcard grading writes `QuestionAttempt(assessment, answerText, boxLevel)` **only for `.hard`/`.gotIt`**; mock test writes `QuestionAttempt(answerText, wasCorrect, assessmentRawValue="")`; bookmarks write `Bookmark`. Home reads attempts via a direct `@Query`; Progress reads them via session snapshots **unfiltered by version**.

| # | Sev | Defect | Evidence |
| --- | --- | --- | --- |
| D1 | **CRITICAL** | `.again` is never persisted: `assess(.again)` resets the box in memory and returns nil; `record()` drops it. Consequences: Leitner reset to box 1 is lost on resume; a just-failed box-5 card stays due in 14 days; `needsWork` can miss it; `needsCareCount`'s `.again` branch is dead code. The strongest negative signal the learner can give is discarded. | `FlashcardState.swift:100-104`; `FlashcardSessionView.swift:697-701`; `SpacedRepetitionScheduler.swift:28-35` |
| D2 | HIGH | "Interview Ready / Standard met" compares bank **coverage** to the **passing fraction of questions asked** (e.g. 2025: seeing 77/128 flips the badge regardless of accuracy). Contradicts `uscis-test-rules.md:13-14` (pass = 12-of-20 correct) and can render next to a low hero % on the same screen. | `ProgressAnalytics.swift:136-146`; `ProgressTabView.swift:198-207,271-281` |
| D3 | HIGH | Hero "N of M questions" is **back-computed from the pass-rate heuristic**, not actual coverage (20 seen at 80% self-assessed → "41 of 128"). Deviates from both progress specs. | `ProgressTabView.swift:166-167` |
| D4 | HIGH | Self-assessment presented as accuracy: `isCorrect = .gotIt \|\| wasCorrect==true` feeds every "accuracy" surface. A learner who taps "Got it" without answering shows 100%. Inverse asymmetry: mock `wasCorrect` never counts toward mastered/graduated/retention. | `StudyProgressMetrics.swift:128-130`; call sites in `ProgressAnalytics.swift` |
| D5 | HIGH | "Needs Care" bucket excludes all truly-unseen cards (iterates attempted IDs only) while its label promises "Unseen or low accuracy"; "In Review" absorbs the unseen instead. Fresh learner: Needs Care = 0, In Review ≈ 128. Two dead branches inside (`boxLevel==nil`, `.again`). | `ProgressAnalytics.swift:319-346,118-125` |
| D6 | MEDIUM | Two "due" numbers (see M9): a seen-but-overdue card appears in neither Home number nor as "unseen". | `StudyProgressMetrics.swift:80-86`; `StudyView.swift:36-50` |
| D7 | MEDIUM | Topic card "N of M Qs" uses **attempt count**, not distinct questions — inflates with repeats, can exceed M ("10 of 5"). | `ProgressAnalytics.swift:171-174`; `ProgressTabView.swift:305-306` |
| D8 | MEDIUM | CTA/count mismatch: weak-spot button shows `weakSpots.count` but opens the `.needsWork` deck (different definition) — "Queue 3" can open a 40-card deck. Drill CTA label says "Needs Care" but queues "needs work". Both render with empty decks. | `ProgressTabView.swift:413-415,567-582,607-610`; `ReviewDeckBuilder.swift:91-96` |
| D9 | MEDIUM | Mock-test skipped questions are never persisted — the "defer to review" promise evaporates when the session ends. | `MockTestState.swift:113-125`; `MockTestSessionView.swift:294-300` |
| D10 | MEDIUM | Version mixing in Progress: trajectory, retention, streak and the empty-state check run over **all** versions; after a config change, old-version numbers sit next to "—" sections. | `ProgressTabView.swift:104-114,124`; `ProgressAnalytics.swift:216-259` (no version param) |
| D11 | MEDIUM | `coverageByTopic` — the spec's centerpiece (per-topic mastered/due/unseen) — is dead production code; only tests call it. The UI substituted accuracy-shaped data. | `StudyProgressMetrics.swift:138-182` |
| D12 | LOW | Written-but-never-read: `StudySession.startedAt`, `Bookmark.createdAt`, `QuestionContent.insight`, `QuestionAttempt.session` inverse, `FlashcardAttemptRecord.answerText` (carried into resume, discarded). | see §7 |
| D13 | LOW | `studyLanguage` ("Spanish study support") has zero functional effect — display only. Spanish support was cancelled by user decision. | `ConfigPreferencesSection.swift:12`; `OnboardingConfiguration.swift:3-17` |
| D14 | LOW | Question bank re-read from disk + JSON-decoded + validated on every body evaluation, twice per render in Progress; no cache. | `QuestionBankLoader.swift:68-138`; `ProgressTabView.swift:26-42` |
| D15 | LOW | Accessibility: `progressTopicReviewHint` has an **empty** catalog entry → VoiceOver reads the raw key; ~9 stale `progress*` keys left behind. | `ProgressTabView.swift:324`; `Localizable.xcstrings` |
| D16 | LOW | Doc drift: `data-and-persistence.md:38` documents `deckStableIDsRaw: String?` (actual `[String]`); :73 says "each answer appends a QuestionAttempt" (false for `.again`). | `docs/architecture/data-and-persistence.md:38,73` |
| D17 | LOW | Weak-spot rows show raw stable IDs ("2025-042") as the question label instead of question text. | `ProgressTabView.swift:419-434` |

**Compliant parts (verified):** bank counts/passing scores match the rules doc exactly (100/10/6, 128/20/12, 20/10/6); early pass/fail logic correct; 65/20 modeled as a separate configuration with a derived bank. The only rule contradiction is D2.

## 6. Progress Tab Deep Dive (the worst screen — confirmed)

Actual rendered sections (`ProgressTabView.swift:123-161`): hero, mastery buckets, standard-met line, topic coverage, accuracy breakdown, weak spots, momentum, retention, recommendation, drill CTA.

| Widget | Data source | Classification |
| --- | --- | --- |
| Hero % "Readiness" (:177) | `passRate = 0.6·graduated/bank + 0.4·accuracy` (`ProgressAnalytics.swift:59-75`) | REAL but an **invented heuristic** labeled as readiness; contradicts Home's coverage-based "Exam Readiness"; violates the product plan's no-prediction non-goal. |
| Hero "N of M questions" (:180) | Back-computed from the heuristic (`ProgressTabView.swift:167`) | **Misleading** — not actual coverage. |
| Weekly trend arrow (:185-195) | Delta of the heuristic over two ISO weeks | DERIVED-MEANINGLESS — no CTA; only feeds the recommendation text. |
| "Interview Ready" + "Standard met" (:198-207, :271-281) | Coverage ≥ passing fraction (D2) | **Broken** — wrong quantity, contradicts rules doc and the hero on the same screen. |
| "Passing req: X of Y" (:208-217) | Static config | DECORATIVE (honest constant). |
| Bucket "Graduated" (:230) | Latest `.gotIt` + box ≥ 4 | REAL, but pure self-assessment ("Ready for oral pace" from tapping "Got it"). |
| Bucket "In Review" (:236) | Scheduler due − graduated; **includes all unseen cards** | REAL but mislabeled — a fresh learner sees ~128 "Active drill" while 0 cards are in review. |
| Bucket "Needs Care" (:242) | Attempted cards only (D5) | **BROKEN** — unseen questions never counted; label promises otherwise. |
| Topic coverage cards (:285-325) | `accuracyByDomain`; "N of M" = attempt count (D7) | REAL, drives action (tap → topic-scoped review) — the tab's best widget. |
| Accuracy breakdown (:338-389) | `isCorrect` incl. `.gotIt` (D4); status labels drive nothing | DERIVED-MEANINGLESS + presents self-assessment as accuracy. |
| Weak spots + queue button (:393-452) | Per-card last-5 accuracy; CTA count mismatch (D8); raw stable IDs (D17) | REAL, drives action — but the button lies about what it opens. |
| Momentum: streak (:464-471) | All versions | REAL, no CTA. Duplicated from Home. |
| Momentum: "Overall accuracy" (:473-481) | Same number as section 5, two cards apart | DERIVED-MEANINGLESS duplicate. |
| Accuracy trajectory bars (:484-516) | All versions (D10) | REAL, no CTA. |
| Retention "Remembered > 5 days" (:524-541) | Fraction of `.gotIt` older than 5 days | **INVERTED** — reviewing a card yesterday *removes* it from the numerator; active study lowers the metric. No CTA. |
| Recommendation card (:545-563) | String built from hero/trend/retention | DERIVED-MEANINGLESS — text only, no action. |
| Drill CTA (:567-582) | Queues `.needsWork` (D8) | REAL action, wrong label, renders on empty decks. |

**Why it feels wrong:** the tab answers no question. A learner opens Progress to know "Am I ready? What should I do next?" — instead they get 14 widgets, several of which contradict each other on the same screen (badge vs hero), one that punishes studying (retention), and only two that lead anywhere (topic cards, weak spots).

**What it should be:** one honest readiness answer (last mock test result + coverage), the buckets fixed to their labels, topic coverage and weak spots kept (they work), and everything that drives no action cut. Detail in §9-10.

## 7. Dead Weight & Over-Engineering

Items confirmed by two independent passes (full ponytail scan pending — will be merged here):

| Item | Evidence | Cut? |
| --- | --- | --- |
| Oral practice entry point ("Start" → placeholder) | `PracticeView.swift:33-42,53-58`; `Components.swift:252-269` | Yes — remove until Phase 4 exists. |
| "Streak Shield: 1 active" Settings row | `AppearanceSection.swift:23`; no code provides the state | Yes. |
| "Card Text Sizing: Dignified Large" Settings row | `AppearanceSection.swift:21`; no control, no preference key | Yes. |
| `sessionFeedbackEnabled` persisted flag — documented as user-facing but **no UI writes it**; always default true | `AppTheme.swift:11-13,23`; only read at `MockTestSessionView.swift:264` | Yes (or wire a real toggle). |
| `QuestionContent.insight` field — decoded and transported through the loader, never rendered ("Civics Insight" card was dropped) | `QuestionContent.swift:28`; `QuestionBankLoader.swift:29,45,121` | Yes. |
| Home "Daily Milestone" card — hardcoded target of 10, no persistence; CTA duplicates the "Continue studying" CTA 30 lines above | `HomeDashboardView.swift:22,146-164` | Yes. |
| Home tip banner — hardcoded English tips rotated by day-of-year; code comment admits "Sample copy for the content team to replace" | `HomeDashboardView.swift:378-409` | Yes (or ship real tips). |
| Theme swatch + "Archive" capsule in Settings — display only | `AppearanceSection.swift:19,29-55` | Yes. |
| Dead accessors: `MockTestState.incorrectCount`/`skippedCount`, `HomeDashboardView.coveredCount` (computed, never rendered), `StudyProgressMetrics.coverageByTopic`/`TopicCoverage` (no view caller) | `MockTestState.swift:61-63,123-125`; `HomeDashboardView.swift:55-61`; `StudyProgressMetrics.swift:56-62,138-182` | Yes. |
| Written-never-read fields: `StudySession.startedAt`, `Bookmark.createdAt`, `QuestionAttempt.session` inverse, `FlashcardAttemptRecord.answerText` on resume | `StudySession.swift:8`; `Bookmark.swift:12`; `StudySession.swift:61` | Yes (keep only if a named feature will read them). |
| Stale localization keys: full sweep of all 297 catalog keys found **32 named keys + one literal `—` key with zero references** in app or test source (config* ×10, settings* ×8, studyFlashcard*/studyTargetedReview* ×7, progress* ×6, commonCancel) — leftovers of removed features (header-style picker, old Settings/Configuration sections); plus one **empty** entry (`progressTopicReviewHint`) that VoiceOver reads as a raw key | `Localizable.xcstrings` | Yes. |

Full scan completed directly (the delegated ponytail worker timed out twice on provider limits):

- **Dependencies**: zero external dependencies (no `Package.resolved`, no SPM references in the project). Nothing to remove.
- **Abstractions**: zero protocols in app source; the only conformance is `SpeechManager: AVSpeechSynthesizerDelegate` (required for TTS callbacks). No single-implementation interfaces, factories, or delegate wrappers exist.
- **Config surface**: exactly two UserDefaults keys — `appThemeName` (live) and `sessionFeedbackEnabled` (dead, see above).
- **Hand-rolled stdlib**: only `SeededShuffle` (`QuestionContent.swift:226`, justified — stdlib `.shuffled()` is not seedable and deterministic distractor order is a test requirement) and the manual ISO-week-start computation (documented SDK overload-resolution workaround). No other reinvented stdlib.
- **Debt comments**: none (no TODO/FIXME/HACK); six intentional `ponytail:` simplification markers.
- **Tests**: ~200 tests across 19 files + 9 UI tests, well distributed (StudyLogicTests 28, TargetedReviewTests 23, SelectionAnswerTests 18, …); includes regression and round-trip coverage; no trivially empty test file found.
- **`DemoSeeder`** (`App/DemoSeeder.swift`, wired at `SwiftyCitizenApp.swift:29-32`): inert in release builds — it sits behind the `#if FILL_USER_DATA` compile flag and seeds a demo 2008 configuration that bypasses onboarding. It is an **undocumented dev backdoor** (useful for reaching post-onboarding screens in UI tests, which currently require completing onboarding manually). Decision needed: keep + document it in AGENTS.md as the UI-test data path, or delete it and have tests build `OnboardingConfiguration` inline.
- **Out-of-scope notes** (correctness/accessibility, not ranked): the app root sets `.environment(\.font, .system(size: 16, design: .rounded))` (`SwiftyCitizenApp.swift:45`) — a fixed-size font that does not scale with Dynamic Type and is the likely systemic root cause of the known Dynamic Type audit failures on Home/Practice/Progress.

net: -~280 lines (app code) + catalog entries, -0 deps possible (already zero).

## 8. Documentation Drift

The docs themselves are part of the problem — they no longer describe the app, which is how features drift into "exist only to exist":

- `current-status.md:34` says "Bookmark has no model yet" in the same paragraph that marks bookmark ✅ done.
- `product-plan.md:170` unchecked but implemented (M8); Phase 2 "oral-style simulation by default" still open while a dead oral-practice entry point ships.
- Three Progress spec documents (`progress-spec.md`, `progress-ui-spec.md`, `progress-diagnostic-mirror-design.md`) all describe a hero built on `readinessPercentage + coveredCount`; the implementation uses an unlabeled heuristic instead (D2/D3).
- `data-and-persistence.md` documents a field type that doesn't exist and a write behavior that is false for `.again` (D16).

Recommendation: after the fixes below, do one docs-sync pass so `current-status.md`, `product-plan.md` checkboxes, and the architecture docs match reality.

## 9. Target Scope — What the App Should Be After Cleanup

**Purpose (one sentence):** help a learner prepare for the USCIS naturalization civics test offline, and tell them honestly when they're ready.

**Core loop (keep, it works):** Learn (flashcards + Leitner) → Drill (targeted review) → Simulate (mock test, official rules) → Know (one honest readiness answer).

**Metric single source of truth (decisions needed — recommendations in bold):**

1. **One "covered"**: distinct questions seen at least once in the active version. Used everywhere.
2. **One "due"**: scheduler-based (Leitner due). Home's "Due next" should use it, not bank − covered.
3. **Readiness hero**: **drop the 0.6/0.4 heuristic entirely** (the product plan forbids predicting pass probability). Hero = last mock test result (score + pass/fail) when one exists, plus coverage ("87 of 128 questions seen"). No invented percentage.
4. **"Standard met" badge**: **remove**, or redefine as a plain coverage statement ("You've seen at least 77 questions") — never as readiness.
5. **Accuracy**: **only mock-test `wasCorrect` counts as accuracy.** Self-assessment stays labeled "Got it" (Home already does this right). Progress's accuracy breakdown becomes mock-test-only or is cut.
6. **Retention widget**: **cut** (inverted, no action).
7. **Version scoping**: all Progress metrics computed for the active test version only.

**Keep:** flashcards + Leitner, targeted review (all 4 scopes), mock test setup/session/result, bookmarks, themes, TTS, onboarding config, reset.

**Cut:** everything in §7, plus the study-language picker (D13 — Spanish support was cancelled; a required setting that changes nothing) and the Home/Progress duplicate sections (Home keeps: Continue CTA, Due next, Today, Bookmarked; Progress owns readiness + history).

**Fix (value order):** D1 persist `.again` → D2/D3 honest hero → D9 persist skips → D5/D8 buckets + CTA honesty → D10 version scoping → M6 session summary weak topics/next action → M2 minimal "About this content" in Settings (version, source URL, verification date — cheap trust win) → D7 distinct-question counts → D14 bank caching.

## 10. Recommended Changes (prioritized backlog)

| # | Change | Value | Effort |
| --- | --- | --- | --- |
| 1 | Persist `.again` attempts (write a `QuestionAttempt` with assessment `.again`, box 1) so the scheduler, review decks, and buckets see real misses | Fixes D1 + D5 dead branches; repairs the learning engine's memory of failure | S |
| 2 | Rebuild Progress hero: last mock test result + coverage; remove heuristic % and back-computed "N of M" (D2/D3) | The tab finally answers "Am I ready?" honestly; removes the rules-doc contradiction | M |
| 3 | Cut dead/fake surfaces (§7 list): oral-practice entry, Streak Shield, Card Text Sizing, Daily Milestone, tip banner, `insight`, dead accessors/fields/keys, `sessionFeedbackEnabled` | Removes every "exists only to exist" surface; shrinks the app | S–M |
| 4 | One definition per metric: covered (distinct seen), due (scheduler), accuracy (mock-test only); align Home's Due next + readiness labels (D4/D6/M9/M10) | Learner sees one consistent story across tabs | M |
| 5 | Scope all Progress metrics to the active test version (D10) | No ghost numbers after a config change | S |
| 6 | Fix buckets to their labels: Needs Care includes unseen; In Review excludes unseen (D5) | Trust in the three-bucket row | S |
| 7 | Make weak spots honest: show question text not stable ID; queue button opens the weak set it counts; hide CTAs on empty decks (D8/D17) | The tab's best widgets stop lying | S |
| 8 | Persist mock-test skipped questions so "defer to review" survives exit (D9) | A deliberate learner action stops evaporating | S |
| 9 | Session Summary: add weak topics + next recommended action (M6) | Closes the loop after every study session | S |
| 10 | Minimal "About this content" section in Settings: version, source URL, verification date (M2) | Cheap trust win for a trust product | S |
| 11 | Study-language setting: remove or make honest (D13) — **product decision** | Onboarding stops collecting data it ignores | S |
| 12 | Cache the question-bank load (D14); fix empty `progressTopicReviewHint` + stale keys (D15) | Performance + VoiceOver correctness | S |
| 13 | Docs-sync pass: current-status, product-plan checkboxes, data-and-persistence, retire/merge the three Progress specs (§8) | Stops the drift that caused this audit | S |

Out of scope for this audit (known, already tracked): on-device VoiceOver/Dynamic Type review (hardware-dependent), Phase 4 speech input, Apple Intelligence features.
