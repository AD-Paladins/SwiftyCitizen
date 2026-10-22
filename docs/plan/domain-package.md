# Domain Package — SwiftyCitizenCore

**Status:** package built and verified standalone; **not yet wired into the app.**
`Core/Domain` remains the authoritative domain source until integration completes.

## Pending — next session

Continue and close this work in a future session as one combined effort:

- [ ] **Integrate `SwiftyCitizenCore` into the app.** Wire the local package into `SwiftyCitizen.xcodeproj` via the Xcode GUI (File ▸ Add Package Dependencies ▸ Add Local Package) — manual pbxproj wiring fails with "Unable to resolve module dependency". Then make the domain types `public`, add `import SwiftyCitizenCore` to the ~24 app files that reference domain types, remove the moved files from `Core/Domain`, and verify the full suite (279 tests).
- [ ] **Evaluate the Swift packages vision (independent logic/components) and report.** Assess which other layers (UI components, content, persistence helpers) could be extracted as independent packages, with tradeoffs (build complexity, Xcode version sensitivity, module boundaries), and report a recommendation.

Current state: package built and verified standalone; app reverted to original (279 tests passing); changes not yet committed.

## Decision

The pure domain layer is extracted into an SPM library, `SwiftyCitizenCore`, so the
domain logic can be reused independently (unit-tested in isolation, potentially shared
across apps/targets). UI and SwiftData models stay in the app target.

## What was proven (Phase 1)

- All 17 files under `SwiftyCitizen/Core/Domain` are **Foundation-only** — no `SwiftUI`,
  no `SwiftData` imports. They compile cleanly as an SPM package.
- Package location: `Packages/SwiftyCitizenCore/` (`Package.swift`, `Sources/`, `Tests/`).
- Verified standalone:
  - `swift build` → Build complete (only pre-existing warnings).
  - `swift test` → runs the package test target (Swift Testing).

## Package boundary

| Moves into `SwiftyCitizenCore` | Stays in the app |
|--------------------------------|------------------|
| All 16 pure domain files (`AnswerEvaluator`, `ContentProvenance`, `ExamEngine`, `FlashcardState`, `LeitnerScheduler`, `MockTestResult`, `MockTestState`, `OnboardingConfiguration`, `ProgressAnalytics`, `QuestionContent`, `ReviewDeckBuilder`, `SessionWeakTopics`, `SpacedRepetitionScheduler`, `StudyDomain`, `TestConfiguration`, `USCISDateEstimates`) | `extension QuestionAttempt { var snapshot }` (in `StudyProgressMetrics.swift`) |
| `StudyAttemptSnapshot`, `MasteryBreakdown`, `TopicCoverage`, `enum StudyProgressMetrics` (the pure part of `StudyProgressMetrics.swift`) | the SwiftData model bridge that reads `QuestionAttempt` properties |

The single app-tie is the `QuestionAttempt.snapshot` extension: `QuestionAttempt` is a
SwiftData model that lives outside the package, so the extension stays in the app and
imports `SwiftyCitizenCore`. `SelfAssessment` (`StudyDomain.swift`) and `USCISTestVersion`
(`TestConfiguration.swift`) are Foundation-only and move with the package.

## Integration requirements (not yet done)

1. **Wire the local package into `SwiftyCitizen.xcodeproj`.** Add an
   `XCLocalSwiftPackageReference` (`relativePath = "Packages/SwiftyCitizenCore"`), a
   `PBXLocalDependency`, a `PackageDependency`, and list it on the app target's
   `packageDependencies`.
2. **Make domain types `public`.** They are currently `internal`; Swift does not expose
   internal symbols across module boundaries, so the app cannot see them without this.
3. **Add `import SwiftyCitizenCore`** to the ~24 app files that reference domain types
   (`App/`, `Core/Content/`, `Core/Persistence/Models/`, `Features/**`, `Shared/UI/`).
4. Remove the moved files from `Core/Domain` once the app consumes the package, then
   verify the full suite.

## Blocker (why integration is deferred)

Hand-writing the local-package wiring in `project.pbxproj` makes Xcode **parse** it but
fail at build time with:

```
error: Unable to resolve module dependency: 'SwiftyCitizenCore' (in target 'SwiftyCitizen' from project 'SwiftyCitizen')
```

The correct pbxproj structure for a local package in this Xcode version could not be
verified headlessly (no reference project, no Xcode GUI). **Recommended path: add the
package through the Xcode GUI** — *File ▸ Add Package Dependencies ▸ Add Local Package* —
which writes a known-good `XCLocalSwiftPackageReference`. Re-attempting the manual pbxproj
edit is possible but risky and unverified.

## Verified commands

- Package build: `cd Packages/SwiftyCitizenCore && swift build`
- Package tests: `cd Packages/SwiftyCitizenCore && swift test`
- App suite (after integration): see `AGENTS.md` "Validation".
