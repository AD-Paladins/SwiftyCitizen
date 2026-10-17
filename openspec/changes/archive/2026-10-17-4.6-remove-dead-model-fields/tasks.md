# Tasks: 4.6 — Remove dead fields from SwiftData models + migration strategy

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~70–120 (model removal ~7, new migration test ~50–100, doc ~6) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR — well under the 400-line review budget |
| Delivery strategy | auto-chain |
| Chain strategy | pending (single PR; size does not warrant a chain) |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Remove three dead `@Model` fields (model code only) | PR 1 | strict_tdd suite below | In-memory `ModelContainer` round-trips still pass; proves zero readers | `StudySession.swift`, `Bookmark.swift` — revert is schema-neutral for users who never installed the build |
| 2 | Add persistent-store migration guard + update docs | PR 1 | strict_tdd suite below (incl. new migration test) | Persistent on-disk store close/reopen (see runtime harness note) | `MigrationTests.swift`, `data-and-persistence.md` — revert removes only the test/doc |

Both units are small and interdependent (the test's "new schema" only lacks the fields after unit 1). A single PR is appropriate; no chain needed.

**Focused test command (all verification):**
```
xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests
```

**Runtime harness note:** the migration test needs a PERSISTENT store on disk (`ModelContainer` with `isStoredInMemoryOnly: false` + temp URL, close, reopen). In-memory containers cannot exercise migration. See the Design Tension below for how old-schema rows are produced.

## Design Tension — migration test must produce OLD-schema rows without the removed init signatures

The spec scenario "Old-schema rows reopen under the new schema" requires writing `StudySession`/`Bookmark`/`QuestionAttempt` rows that **include** `startedAt`, `createdAt`, and `session`, then reopening with a schema where those fields are gone.

This is impossible via normal model init once the fields are removed: SwiftData infers the container schema from the *current* compiled `@Model` definitions, so `ModelContainer(for: StudySession.self, …)` always builds the NEW schema. After removal there is no `StudySession(mode:testVersion:startedAt:)` to call. The apply phase MUST pick one mechanism to produce old-schema rows and document it in the PR:

- **Path A — Hand-craft an old-schema SQLite store (strong, brittle).** Create a `.sqlite` file at the temp URL with the column layout SwiftData generated for the *old* models (`ZSTARTEDAT`, `ZCREATEDAT`, inverse columns, etc.), then open it with the new `ModelContainer`. Genuinely exercises on-device lightweight migration. Risk: fragile across Xcode/SwiftData versions; requires reverse-engineering SwiftData's internal schema.
- **Path B — Separate old-model module/target (correct, heavy).** Compile the pre-removal models in a second test target to produce a real old-schema store, then open with the new models. Adds a target/module — conflicts with the tight ~10-line scope. Generally out of scope here.
- **Path C — Persistent round-trip with NEW models only (weak, compiles cleanly).** Write rows with the post-removal models to a persistent store, close, reopen, assert load + no `NSCocoaErrorDomain 134110`. This proves the clean schema persists and does not throw 134110 on reopen, but it does **not** migrate real old rows (both opens use the new schema). If chosen, the PR MUST label it as a round-trip guard (not a migration proof) and rely on the 5.3 `studyLanguageRawValue` precedent + an on-device smoke test for the actual upgrade path.

**Recommendation:** attempt Path A; if hand-crafting SwiftData's SQLite schema proves too brittle for this store, fall back to Path C and document the downgrade honestly with the 5.3 precedent as supporting evidence. The apply phase records the chosen path in the PR description.

## Phase 1 — Migration test (RED → GREEN, strict TDD)

> Strict TDD is active. This test is the PRIMARY regression guard for the on-device upgrade path. Observe a real RED before any GREEN.

- [x] **1.1 [RED]** Add `SwiftyCitizenTests/Domain/MigrationTests.swift` implementing the persistent-store migration guard for spec scenario *Old-schema rows reopen under the new schema*. The test MUST: create a `ModelContainer` on a temp URL with `isStoredInMemoryOnly: false` and a named `ModelConfiguration`, persist `StudySession`, `Bookmark`, and `QuestionAttempt` rows written against the OLD schema (with `startedAt`, `createdAt`, and `session` values present), `close` the container, reopen a new `ModelContainer` on the same URL with the NEW schema, then assert every surviving row loads and the open does **not** raise `NSCocoaErrorDomain 134110`. Before writing it, resolve the Design Tension (Path A/B/C) and record the chosen mechanism + rationale. RED state: file absent → target fails to build with `-only-testing:SwiftyCitizenTests`, or the assertion fails because old rows are not produced / migration is not exercised.
- [x] **1.2 [GREEN]** Implement the chosen old-row mechanism so `MigrationTests.swift` compiles and passes; run the focused test command above and confirm the migration test reports green (rows load, no `134110`).

## Phase 2 — Remove dead model fields (core implementation)

> Domain-first: `StudySession.swift` and `Bookmark.swift` stay `import Foundation` + `import SwiftData` only. Never add SwiftUI/SwiftUI-only imports to these pure domain files.

- [x] **2.1** In `SwiftyCitizen/Core/Persistence/Models/StudySession.swift`: delete `var startedAt: Date` (line 8), remove `startedAt: Date = .now,` from the init parameter list (line 18), and delete `self.startedAt = startedAt` (line 23).
- [x] **2.2** In `SwiftyCitizen/Core/Persistence/Models/Bookmark.swift`: delete `var createdAt: Date` (line 12), remove `createdAt: Date = .now` from the init parameter list (line 14), and delete `self.createdAt = createdAt` (line 17).
- [x] **2.3** In `SwiftyCitizen/Core/Persistence/Models/StudySession.swift`: delete `var session: StudySession?` (the `QuestionAttempt.session` inverse, line 63). Not `@Relationship`-annotated; `StudySession.attempts` remains the single canonical relationship side.
- [x] **2.4** Grep `SwiftyCitizen/` and `SwiftyCitizenTests/` for any remaining reference to `startedAt`, `createdAt`, or `QuestionAttempt.session`; resolve every hit (call sites already omit these args per the proposal, so none are expected).

## Phase 3 — Documentation

- [x] **3.1** Update `docs/architecture/data-and-persistence.md`: drop `startedAt` from the `StudySession` table (and its `startedAt / endedAt?` row note), drop `createdAt` from the `Bookmark` table + its migration note, and drop `session` from the `QuestionAttempt` table; keep `endedAt`, `attempts`, and all other columns. Note that the **migration policy is unchanged** (automatic lightweight migration for property/relationship drops; no `VersionedSchema`/`MigrationPlan`).

## Phase 4 — Verification & acceptance

- [x] **4.1** Run the focused test command; the full `SwiftyCitizenTests` suite is green, including `MigrationTests`.
- [x] **4.2** Confirm zero remaining references to the three fields across `SwiftyCitizen/` and `SwiftyCitizenTests/` (task 2.4).
- [x] **4.3** Confirm no `VersionedSchema`/`MigrationPlan`/custom `SchemaMigration` was added; migration relies on automatic lightweight migration only.
- [x] **4.4** Confirm the model diff stays ~10 lines and the doc change is limited to the three rows + migration note.
- [x] **4.5** Record the migration-test mechanism decision (Design Tension) in the PR description; if Path C was used, label it a round-trip guard and cite the 5.3 `studyLanguageRawValue` precedent as supporting evidence.

### Acceptance criteria (maps to proposal Success Criteria)

- [x] `StudySession.startedAt`, `Bookmark.createdAt`, and `QuestionAttempt.session` removed from model source (tasks 2.1–2.3).
- [x] No remaining references anywhere in `SwiftyCitizen/` or `SwiftyCitizenTests/` (task 2.4 / 4.2).
- [x] strict_tdd suite green (task 4.1).
- [x] Automated persistent-store migration test passes: OLD-schema rows reopen under NEW schema, rows load, no `NSCocoaErrorDomain 134110` (tasks 1.1–1.2 / 4.1).
- [x] `docs/architecture/data-and-persistence.md` updated to reflect the removed columns; migration policy noted unchanged (task 3.1).
- [x] Diff ~10 lines of model code; no `VersionedSchema`/`MigrationPlan` added (tasks 4.3–4.4).
