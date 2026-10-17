# Proposal: 4.6 — Remove dead fields from SwiftData models + migration strategy

## Intent

Three SwiftData model properties are written but never read anywhere in production code or tests. They bloat the persisted schema, inflate the inferred schema version, and carry misleading documentation (`data-and-persistence.md` still lists them as live columns). Removing them is a low-risk cleanup that also removes the migration surface those columns would otherwise require (e.g. defaulted/optional handling for future stores). The change pairs the removal with an explicit migration strategy so the on-device upgrade path is understood, not assumed.

## Scope

### In Scope
- Remove `StudySession.startedAt: Date` — declaration (`StudySession.swift:8`), init parameter (`:18`), and write (`:23`). Zero readers.
- Remove `Bookmark.createdAt: Date` — declaration (`Bookmark.swift:12`), init parameter (`:14`), and write (`:17`). Zero readers.
- Remove `QuestionAttempt.session: StudySession?` — declaration only (`StudySession.swift:63`). Not `@Relationship`-annotated; the canonical to-many side is `StudySession.attempts`. Zero readers.
- Rely on automatic SwiftData **lightweight migration** (property/relationship drop) — no `VersionedSchema`/`MigrationPlan` added. Same class of change as 5.3's `studyLanguageRawValue` removal (Engram obs #173, sync_id obs-ff774ab9352d544f).
- Update `docs/architecture/data-and-persistence.md` in the same work unit (repo convention).

### Out of Scope
- `SavedOnboardingConfiguration.shuffleQuestions` — LIVE (mock-test + flashcard shuffling; read in `MockTestSessionView.swift:29`, `FlashcardSessionView.swift:679`, asserted in `ExamTests.swift:246`). Do NOT remove.
- Any field flowing through `QuestionAttempt.snapshot` (`wasCorrect`, `answeredAt`, `questionStableID`, `assessmentRawValue`, `boxLevel`) or used for resume/metrics (`StudySession.modeRawValue`, `deckStableIDs`, `currentIndex`, `skippedStableIDs`, `endedAt`, `attempts`, `testVersionRawValue`).
- `FlashcardAttemptRecord.answerText` — pure domain struct (Foundation-only), not a `@Model`, and live anyway.
- Adding a `VersionedSchema`/`MigrationPlan` — over-engineering vs. the proven inferred-versioning approach; automatic lightweight migration is sufficient.

## Capabilities

> Pure refactor / config change. No spec-level behavior changes.

### New Capabilities
- None

### Modified Capabilities
- None

## Approach

All three removals are property/relationship **drops**. SwiftData infers a new schema version when an `@Model` changes and performs automatic lightweight migration for additive/drop changes — no custom `SchemaMigration`/`MigrationPlan`. This matches the app's existing inferred-versioning design (zero explicit plan in the source tree) and the 5.3 precedent.

Concrete edits (~10 lines of model code, one change):

**`Core/Persistence/Models/StudySession.swift`**
- Delete `var startedAt: Date` (line 8).
- Delete `startedAt: Date = .now,` from the init parameter list (line 18).
- Delete `self.startedAt = startedAt` (line 23).
- Delete `var session: StudySession?` (line 63).

**`Core/Persistence/Models/Bookmark.swift`**
- Delete `var createdAt: Date` (line 12).
- Delete `createdAt: Date = .now` from the init parameter list (line 14).
- Delete `self.createdAt = createdAt` (line 17).

Caller safety verified: both `StudySession(...)` call sites (`MockTestSessionView.swift:232`, `FlashcardSessionView.swift:693`) and the `Bookmark(...)` call (`FlashcardSessionView.swift:649`) omit these arguments and rely on defaults, so removing the init parameters does not break any caller.

On-disk behavior for existing users (v1.0.0): other columns preserved, dropped column removed, no `NSCocoaErrorDomain 134110`. The `session` inverse removal is safe because `StudySession.attempts` remains the single canonical relationship side and `session` was never read.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `SwiftyCitizen/Core/Persistence/Models/StudySession.swift` | Modified | Remove `startedAt` (property + init param + write) and `QuestionAttempt.session` (declaration). |
| `SwiftyCitizen/Core/Persistence/Models/Bookmark.swift` | Modified | Remove `createdAt` (property + init param + write). |
| `docs/architecture/data-and-persistence.md` | Modified | Drop `startedAt`, `createdAt`, and `session` from the model tables/notes; note migration policy unchanged. |

## Verification Strategy (user-resolved: mix of automated harness + 5.3 precedent)

Unit tests with an in-memory `ModelContainer` do **not** exercise migration — in-memory stores are recreated from the current schema every launch, so a field drop is invisible to them. The strict_tdd suite will pass after removal (removed fields are unreferenced) but proves nothing about the on-device migration path.

The user chose a **mix of the automated harness and the 5.3 precedent** — accepting slightly more scope for regression protection rather than relying solely on another feature's success:

- **(b) Automated persistent-store migration test** in `SwiftyCitizenTests` — a small harness that persists rows with the OLD schema (including `startedAt`, `createdAt`, `session`) and reopens with the NEW schema, asserting load succeeds with no `NSCocoaErrorDomain 134110`. This is the regression guard for the on-device upgrade path.
- **(c) 5.3 precedent + full suite green** — the strict_tdd suite stays green; the 5.3 `studyLanguageRawValue` removal (Engram obs #173, sync_id obs-ff774ab9352d544f) documents that this exact change class migrates automatically on this app/store.

> **Decision recorded (2026-10-17):** adopt (b) + (c). The automated harness is the primary guard; the 5.3 precedent is documentation, not the sole basis for correctness.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Migration path untested by unit tests (in-memory `ModelContainer` hides the drop) | High (test-wise) / Low (actual) | Device smoke test (option a) or 5.3 precedent + documented caveat (option c). |
| `session` inverse removal triggers a SwiftData inverse-cascade surprise | Low | `attempts` stays canonical; `session` was never read; grep confirmed zero readers. |
| Docs drift — `data-and-persistence.md` still lists the removed columns as live | Med | Update docs in the same work unit per repo convention. |
| Accidental removal of a live field (e.g. `shuffleQuestions`) | Low | Scope table enumerates exactly what to keep; every kept field verified read. |

## Rollback Plan

- **Pre-ship:** revert the commit (`git revert` / checkout) — no data impact, schema unchanged for users who never installed the build.
- **Post-ship (already migrated on-device):** the removal is forward-only at the schema level; dropped columns are gone from existing rows. Re-adding a field later is itself an automatic additive migration and will not crash. No destructive on-migration step exists, so there is no data-loss window to roll back from.

## Dependencies

- None. Pure in-repo change; no new dependencies, no `project.pbxproj` edits (PBXFileSystemSynchronizedRootGroup picks up `.swift` files automatically).

## Success Criteria

- [ ] `StudySession.startedAt`, `Bookmark.createdAt`, and `QuestionAttempt.session` removed from the model source.
- [ ] No remaining references to the three fields anywhere in `SwiftyCitizen/` or `SwiftyCitizenTests/`.
- [ ] strict_tdd suite green: `xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests`.
- [ ] Automated persistent-store migration test passes: persist OLD-schema rows, reopen with NEW schema, assert load + no `NSCocoaErrorDomain 134110`.
- [ ] strict_tdd suite green; 5.3 precedent (automatic lightweight migration on this store) documented as supporting evidence.
- [ ] `docs/architecture/data-and-persistence.md` updated to reflect the removed columns.
- [ ] Diff stays ~10 lines of model code; no `VersionedSchema`/`MigrationPlan` added.

## Delivery Forecast (400-line review guard)

- Decision needed before apply: **No** (pending only the verification-option choice).
- Chained PRs recommended: **No**.
- 400-line budget risk: **Low** (~10 lines of model code + doc edits).
