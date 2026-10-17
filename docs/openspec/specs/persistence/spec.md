# Delta for Persistence

> Pure refactor / config change. **No user-facing behavior changes.** This delta removes three dead `@Model` properties, relies on automatic SwiftData lightweight migration, and adds a verification requirement for the on-device upgrade path.

These three properties were never user-facing spec requirements — they are persistence implementation details documented only in `docs/architecture/data-and-persistence.md`. There is no existing main-spec requirement to modify, so this delta contains no ADDED or MODIFIED user-facing requirements. It records the schema removal (for traceability/audit), the migration strategy, and the verification contract.

## REMOVED Requirements

### Requirement: `StudySession.startedAt` property

(Reason: written but never read in production code or tests — zero readers. Removing it cleans the persisted schema and the inferred schema version.)
(Migration: automatic SwiftData lightweight migration. The `started_at` column is dropped from existing stores; no custom plan. Existing rows preserve every other column.)

#### Scenario: Existing store upgrades to the new schema

- GIVEN an on-disk store created with the old `StudySession` schema (a non-null `started_at` column)
- WHEN the app is upgraded and opens the store with the new schema (no `startedAt`)
- THEN the migration completes automatically, other columns are preserved, and no `NSCocoaErrorDomain 134110` is raised
- AND newly created sessions no longer carry a `startedAt` value

#### Scenario: Construction without `startedAt`

- GIVEN any code that constructs a `StudySession`
- WHEN it calls `StudySession(mode:testVersion:)` (with or without the remaining optional arguments)
- THEN construction succeeds; there is no `startedAt` parameter to pass

### Requirement: `Bookmark.createdAt` property

(Reason: written but never read — zero readers. Removes a persisted column and its init surface.)
(Migration: automatic lightweight migration. The `created_at` column is dropped; stores created before it existed already migrated in place via the default, and this drop migrates automatically.)

#### Scenario: Existing store upgrades to the new schema

- GIVEN an on-disk store with a non-null `Bookmark.created_at` column
- WHEN the app opens the store with the new schema (no `createdAt`)
- THEN the migration completes automatically, other columns are preserved, and no `NSCocoaErrorDomain 134110` is raised

#### Scenario: Construction without `createdAt`

- GIVEN any code that constructs a `Bookmark`
- WHEN it calls `Bookmark(questionStableID:testVersion:)`
- THEN construction succeeds; there is no `createdAt` parameter to pass

### Requirement: `QuestionAttempt.session` inverse property

(Reason: declared but never read — zero readers. Not even `@Relationship`-annotated; the canonical to-many side is `StudySession.attempts`. Removing it removes a misleading inverse.)
(Migration: automatic lightweight migration. The inverse relationship column is dropped. Safe because `StudySession.attempts` remains the single canonical relationship side and `session` was never read.)

#### Scenario: Existing store upgrades to the new schema

- GIVEN an on-disk store with the `QuestionAttempt.session` inverse column
- WHEN the app opens the store with the new schema (no `session`)
- THEN the migration completes automatically, `StudySession.attempts` remains intact, and no `NSCocoaErrorDomain 134110` is raised

## Migration Strategy

### Requirement: Automatic lightweight migration only

The removal of all three properties SHALL rely on SwiftData's automatic lightweight migration (property/relationship drop). The system SHALL NOT introduce a `VersionedSchema`, `MigrationPlan`, or any custom `SchemaMigration`. This matches the app's existing inferred-schema-versioning design (zero explicit plan in the source tree) and the 5.3 `studyLanguageRawValue` removal.

#### Scenario: Inferred schema versioning handles the drop

- GIVEN an `@Model` change that drops one or more properties/relationships
- WHEN the inferred schema version is recomputed on next launch
- THEN SwiftData performs a lightweight migration in place, preserving other columns and raising no `NSCocoaErrorDomain 134110`

## Verification Requirements

### Requirement: Automated persistent-store migration test

Because an in-memory `ModelContainer` is recreated from the current schema on every launch and cannot exercise migration, the change SHALL include an automated test in `SwiftyCitizenTests` that persists rows written with the OLD schema (including `startedAt`, `createdAt`, and `session`) and reopens them with the NEW schema. This is the primary regression guard for the on-device upgrade path.

#### Scenario: Old-schema rows reopen under the new schema

- GIVEN a persistent store populated with `StudySession`, `Bookmark`, and `QuestionAttempt` rows written against the old schema (with `startedAt`, `createdAt`, and `session` values present)
- WHEN the store is reopened with the new schema (the three fields removed)
- THEN all surviving rows load successfully
- AND the open does not raise `NSCocoaErrorDomain 134110`

### Requirement: strict_tdd suite green

The full unit suite SHALL remain green after removal:

```
xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests
```

This proves the removed fields are unreferenced; it does not by itself prove the on-device migration path (see the automated persistent-store migration test above).

### Requirement: 5.3 precedent as supporting evidence

The 5.3 `studyLanguageRawValue` removal — an automatic lightweight migration on this app/store — SHALL be cited as supporting documentation that this change class migrates automatically. It is not the sole basis for correctness; the automated persistent-store test is the primary guard.
