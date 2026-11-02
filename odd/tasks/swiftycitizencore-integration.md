# SwiftyCitizenCore SPM integration into the app

Integrate the local Swift package `Packages/SwiftyCitizenCore` into the `SwiftyCitizen`
app target so the pure domain layer lives in one reusable module. Per
`docs/plan/domain-package.md`, task #1 on the Task board (`docs/plan/current-status.md`).

## Specs

S1. User request (verbatim): continue task #1 — integrate `SwiftyCitizenCore` into the app.
    Source of truth: `docs/plan/domain-package.md`.

S2. Package boundary (verbatim from domain-package.md):
    - Moves into `SwiftyCitizenCore`: all 16 pure-domain files
      (`AnswerEvaluator`, `ContentProvenance`, `ExamEngine`, `FlashcardState`,
      `LeitnerScheduler`, `MockTestResult`, `MockTestState`, `OnboardingConfiguration`,
      `ProgressAnalytics`, `QuestionContent`, `ReviewDeckBuilder`, `SessionWeakTopics`,
      `SpacedRepetitionScheduler`, `StudyDomain`, `TestConfiguration`, `USCISDateEstimates`)
      plus the pure part of `StudyProgressMetrics.swift`
      (`StudyAttemptSnapshot`, `MasteryBreakdown`, `TopicCoverage`, `enum StudyProgressMetrics`).
    - Stays in the app: `extension QuestionAttempt { var snapshot }` (SwiftData bridge).
      `QuestionAttempt` is a SwiftData model outside the package, so this extension stays
      in the app and imports `SwiftyCitizenCore`.

S3. All 17 files under `SwiftyCitizen/Core/Domain` are Foundation-only — no `SwiftUI`,
    no `SwiftData` imports. (Confirmed: `QuestionAttempt` is a plain `final class` in
    `Core/Persistence/Models/StudySession.swift`, visible to the domain via same-module,
    not via SwiftData.)

S4. Integration requirements (verbatim from domain-package.md):
    1. Wire the local package into `SwiftyCitizen.xcodeproj`: add an
       `XCLocalSwiftPackageReference` (`relativePath = "Packages/SwiftyCitizenCore"`), a
       `PBXLocalDependency`, a `PackageDependency`, and list it on the app target's
       `packageDependencies`.
    2. Make domain types `public` (currently `internal`; Swift does not expose internal
       symbols across module boundaries).
    3. Add `import SwiftyCitizenCore` to the ~24 app files that reference domain types
       (`App/`, `Core/Content/`, `Core/Persistence/Models/`, `Features/**`, `Shared/UI/`).
    4. Remove the moved files from `Core/Domain` once the app consumes the package, then
       verify the full suite.

S5. Acceptance: `swift build` in the package succeeds; the app builds with
    `xcodebuild build ... -destination 'platform=iOS Simulator,name=iPhone 17e'`; the full
    app suite passes (282 tests, `SwiftyCitizenTests`).

## Tasks

- T1 Populate `Packages/SwiftyCitizenCore/Sources/SwiftyCitizenCore/` with all 16 pure-domain
  files + the pure part of `StudyProgressMetrics.swift`; make every referenced type `public`;
  keep the `QuestionAttempt.snapshot` extension out of the package. Verify `swift build`.
- T2 Wire the local package into `SwiftyCitizen.xcodeproj` (manual pbxproj wiring; verify with
  a real `xcodebuild build`, not the LSP). Spike on a copy of the project first.
- T3 Add `import SwiftyCitizenCore` to the ~24 app files that reference domain types; add a
  small app-side file defining `extension QuestionAttempt { var snapshot }` importing the
  package; remove the moved files from `SwiftyCitizen/Core/Domain`.
- T4 Verify: app builds and the full `SwiftyCitizenTests` suite passes (282 tests).

## Log

L1. User request (verbatim): "continúa por favor" — continue task #1 (SwiftyCitizenCore SPM
    integration).
L2. Reality vs spec: domain-package.md §"Current state" claims all 16 files already extracted;
    false. Only `StudyProgressMetrics.swift` was ever moved (commit a562855), and it is a
    STALE subset — it references `USCISTestVersion`, so the package does NOT build standalone
    right now (`swift build` fails: cannot find type 'USCISTestVersion'). The other 16 files
    still live in `SwiftyCitizen/Core/Domain`. Integration therefore requires fully populating
    the package, not just wiring.

L3. Applied & committed (branch `feat/swiftycitizencore-integration`, from `origin/main`):
    - T1 committed `8d93671`: package populated with 17 files (16 pure-domain + StudyProgressMetrics),
      all types public. `swift build` and smoke tests pass (verified earlier).
    - T2 committed `41a844f`: pbxproj wired (PBXLocalDependency + PBXPackageGroup +
      PBXLocalSwiftPackageReference + project-level `packages` entry on target SwiftyCitizen).
    - T3 committed `b2c6318`: `import SwiftyCitizenCore` added to app files, bridge
      `SwiftyCitizen/Core/Domain/QuestionAttempt+Snapshot.swift` kept, 16 moved originals deleted
      from Core/Domain (only the bridge remains).
    - The spec's "~24 files" was an underestimate: ~30 app files import the package.
    - T4 BLOCKED on environment: `xcodebuild` cannot resolve a LOCAL package headlessly
      ("Unable to resolve module dependency: 'SwiftyCitizenCore'" — resolution, not a type error;
      imports/bridge/removal are correct). Requires opening the project in Xcode once to trust the
      local package, then `xcodebuild test -only-testing:SwiftyCitizenTests`.

L4. Pushed & opened as PR (branch `feat/swiftycitizencore-integration`, now tracking
    `origin/feat/swiftycitizencore-integration`):
    - Pushed to origin; branch created from `origin/main` with 4 commits (T1-T3 + docs).
    - Opened PR #30: "refactor: integrate pure-domain types into SwiftyCitizenCore package",
      base `main`, label `type:refactor`. Link: https://github.com/AD-Paladins/SwiftyCitizen/pull/30
    - The repo has no workflows (no GitHub Actions to block a blank PR) and no open issues, so
      the PR carries no linked issue (documented in the body).
    - T4 still BLOCKED on environment: needs Xcode to trust the local package once, then run
      `xcodebuild test -only-testing:SwiftyCitizenTests` (282 tests). Not yet verified.
