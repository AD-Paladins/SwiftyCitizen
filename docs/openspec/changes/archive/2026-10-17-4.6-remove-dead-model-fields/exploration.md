# Exploration: 4.6 — Remove dead fields from SwiftData models + migration strategy

## Current State

Four SwiftData @Model classes in `Core/Persistence/Models/`: `SavedOnboardingConfiguration`, `StudySession` (also declares `QuestionAttempt`), and `Bookmark`. The app ships a persistent store (`SwiftyCitizenApp.swift:25`, `isStoredInMemoryOnly: false`) using an **inferred schema** — there is **zero** `VersionedSchema`/`MigrationPlan`/`SchemaMigration` anywhere in the target source. Existing users are on v1.0.0 and have on-disk data.

The 5.3 precedent (Engram obs #173, sync_id obs-ff774ab9352d544f): removing `studyLanguageRawValue` was an **automatic SwiftData lightweight migration** (property drop = column dropped, no custom plan). Inferred schema versioning handled it; existing configs preserved, other fields intact, no NSCocoaErrorDomain 134110.

## Dead Fields (confirmed unused — every reader grepped)

1. **`StudySession.startedAt`** (`Date`) — declared + written only (`StudySession.swift:8`, init params :18/:23). **Zero readers** in production or tests. Grep for `\bstartedAt\b` returns only the declaration, the init parameter, and docs.
2. **`Bookmark.createdAt`** (`Date`) — declared + written only (`Bookmark.swift:12`, init :17). **Zero readers**. Grep returns only declaration + init param.
3. **`QuestionAttempt.session`** (`StudySession?` inverse) — declared only (`StudySession.swift:63`). **Zero readers**. Grep returns only the declaration line. It is not even `@Relationship`-annotated; the canonical to-many side is `StudySession.attempts`.

## Fields that LOOK dead but ARE used (do NOT remove)

- **`SavedOnboardingConfiguration.shuffleQuestions`** (the prompt's headline candidate) — LIVE. Read in `MockTestSessionView.swift:29`, `FlashcardSessionView.swift:679`, and via `.configuration` in `TestConfigurationView.swift:20`; asserted in `ExamTests.swift:246`. Drives question shuffling for mock test + flashcards.
- **`StudySession.modeRawValue`** — read via the `mode` computed property (`:32`); used in `ProgressTabView.swift:113`, `TargetedReviewView.swift:58`, `FlashcardSessionView.swift:685`, `StudyLogicTests.swift:145`.
- **`QuestionAttempt.wasCorrect`** — read via `QuestionAttempt.snapshot` (`StudyProgressMetrics.swift:238`), which feeds metrics in ProgressTabView:21 / StudyView:26 / TargetedReviewView:30 / HomeDashboardView:15.
- **`QuestionAttempt.answeredAt`** — read via `snapshot` (`:239`).
- **`QuestionAttempt.questionStableID`** — read via `snapshot` (`:235`).
- **`QuestionAttempt.assessmentRawValue`** — read via the `assessment` computed property (`:101`) and `snapshot` (`:237`).
- **`QuestionAttempt.boxLevel`** — read via `flashcardAttemptRecord` (`:115`) and `snapshot` (`:240`).
- **`StudySession.deckStableIDs`, `currentIndex`, `skippedStableIDs`, `endedAt`, `attempts`, `testVersionRawValue`** — all live (resume, progress display, mock-test skip tracking, completion, version scoping).

Out of scope entirely: **`FlashcardAttemptRecord.answerText`** is a pure domain struct (Foundation-only), not a @Model; and it is live anyway. Do not touch it under 4.6.

## Migration Strategy per Removal

All three removals are **property/relationship DROPS → automatic lightweight migration**, same class of change as the 5.3 `studyLanguageRawValue` removal. Rationale:

- SwiftData infers a new schema version when an @Model changes and performs automatic lightweight migration for additive/drop changes (property add/remove, optionality change with default, relationship remove). No custom `SchemaMigration`/`MigrationPlan` required — consistent with the app's existing inferred-versioning approach.
- Existing on-disk rows: other columns preserved, dropped column removed, no 134110. The `session` inverse removal is safe because `StudySession.attempts` remains the single canonical relationship side.

**Critical testing caveat (scope-critical):** unit tests that use an in-memory `ModelContainer` do **not** exercise migration — in-memory stores are recreated from the current schema every launch, so a field drop is invisible to them. The existing strict_tdd suite will pass after removal (removed fields are unreferenced) but proves nothing about the on-device migration path. To truly validate automatic lightweight migration you need a persistent-store test: persist rows with the OLD schema, reopen with the NEW schema, confirm load + no 134110. That requires either a dedicated old-schema model in the test target or a versioned-schema test harness — itself a non-trivial change. Given 5.3 already proved this exact app/store pattern migrates automatically, the pragmatic gate is: (a) full suite green, and (b) a manual/CI smoke test on a booted simulator with a pre-populated persistent store.

## Scope Recommendation

- **Remove exactly three fields**, in ONE change (total diff ~10 lines of model code): `StudySession.startedAt`, `Bookmark.createdAt`, `QuestionAttempt.session`.
- Order is immaterial — all three are automatic migrations; do them together for a single clean migration pass and one review slice.
- **Do NOT remove** `shuffleQuestions` (live) or any other listed candidate.
- **Do NOT add** a VersionedSchema/MigrationPlan — that would be over-engineering vs. the proven 5.3 approach; automatic lightweight migration is sufficient and matches existing architecture.
- Verification: keep strict_tdd suite green + add a manual on-device migration smoke test (or defer automated migration coverage, documenting the in-memory caveat).

## Risks

- **Migration untested by unit tests**: in-memory `ModelContainer` hides the drop; real users hit the persistent path. Mitigate with device smoke test or 5.3 precedent.
- **`session` inverse removal**: verify no SwiftData inverse-cascade surprise — low risk because `attempts` stays canonical and `session` was never read.
- **Docs drift**: `data-and-persistence.md` documents `startedAt`/`createdAt`-style columns; update in the same work unit per repo convention.

## Ready for Proposal

Yes. Scope is tight (3 fields, ~10 lines, automatic migration only). Recommend sdd-propose next with the migration-verification approach locked (manual device smoke test vs. automated persistent-store harness — a decision point for the user).

## Key Learnings

1. StudySession.startedAt, Bookmark.createdAt, and QuestionAttempt.session are written but never read anywhere in code or tests.
2. SavedOnboardingConfiguration.shuffleQuestions is live despite being the prompt's headline dead-field candidate.
3. QuestionAttempt.wasCorrect, answeredAt, questionStableID, assessmentRawValue, and boxLevel all flow through the snapshot computed property into metrics.
4. The app relies entirely on inferred SwiftData schema versioning with zero explicit VersionedSchema or MigrationPlan in the source tree.
5. In-memory ModelContainer unit tests cannot validate field-drop migration because in-memory stores are recreated from the current schema each launch.
