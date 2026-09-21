# SwiftyCitizen

## Repository Status

- The project is an iOS app built with Swift and SwiftUI.
- The repository now includes the product and engineering plan, design docs, and the current implementation status under `docs/plan/`.
- Do not assume a build scheme, simulator destination, deployment target, dependency manager, or test command without checking the active project files and current docs.
- `.atl/skill-registry.md` is generated metadata; do not edit it manually.

## Project Skills

- `skills/xcode27-accessibility/SKILL.md` — accessibility testing with Xcode 27 / Device Hub (terminal + simulator). Load before any build/test/simulator/device work, or when the user mentions VoiceOver, Dynamic Type, contrast, `simctl`, `devicectl`, `performAccessibilityAudit`, or "testar accesibilidad por terminal/simulador". Details: `references/commands.md` and `references/gotchas.md`.

## Start Here for the Next Session

Before writing code, review the working plan and the current state of the project in this order:

1. `docs/plan/current-status.md` — current implementation status and the next slice.
2. `docs/plan/product-plan.md` — product phases, scope, and transition rules.
3. `docs/plan/uscis-test-rules.md` — authoritative USCIS rules and configuration boundaries.
4. `docs/plan/screen-inventory.md` — screen responsibilities and the first-release scope.
5. `docs/plan/phase-0.5-design-spec.md` — design intent and interaction rules.
6. `docs/plan/phase-0.5-user-checklist.md` — pending design handoff items.
7. `docs/plan/design-tools.md` — selected design tooling and constraints.
8. `docs/audit/code-and-architecture-audit.md` — active engineering-hygiene audit and its roadmap (items 1–4 below). This is a working note; delete it once all four items are done.

Use these documents as the default source of truth. Do not start from a blank slate or from assumptions about the product direction. Follow the current phase boundary and continue from the latest documented slice.

## Active Engineering-Hygiene Roadmap

`docs/audit/code-and-architecture-audit.md` tracks four cross-cutting items (accessibility device review, moving `StudySession.resumeState()` out of the `@Model`, thin tests for the untested core, deferred mock-test findings). Work these in order and delete the audit file once all four are complete.

## Architecture Documentation

`docs/architecture/` is the implementation documentation library: how flows, persistence, content, and dependencies actually work in the code. Read `docs/architecture/README.md` first for the map and reading order.

When a task changes behavior in a covered area, update the matching architecture document in the same work unit as the code:

- Screen flow, navigation, or interaction changes → the relevant `flow-*.md`.
- SwiftData models, schema, or migration → `data-and-persistence.md`.
- Question banks, loader, or validation → `content-pipeline.md`.
- New files, new dependencies, or new layer rules → `dependencies.md` (including the file-level dependency table).
- Root/entry/tab changes → `app-overview.md`.

Never let a pure domain file (which must stay `import Foundation` only) import SwiftUI or SwiftData; that is a design-review trigger, not a documentation update.

## Working Rules

- Inspect the repository before making implementation decisions. Follow the conventions established by the first Xcode or Swift package files added here.
- Keep changes focused and avoid introducing dependencies or architecture until the project structure and product requirements are known.
- When adding the Xcode project, document the verified build and test commands here and add a concise project README if one does not exist.
- Prefer SwiftUI-native patterns and the project’s established state-management approach once those are defined.
- Place tests in the project’s established test target and run the narrowest relevant test command before broader validation.
- Preserve user changes and do not remove generated or local configuration without confirming its purpose.

### Phase Transition Review

- At the end of every phase, review the next planned phase before starting it.
- Use the completed phase's results, discoveries, risks, and implementation changes to update the next phase's scope, acceptance criteria, dependencies, and checklist.
- Add any missing requirements, edge cases, tests, documentation, or design decisions discovered during the completed phase.
- Do not begin the next phase until this review is recorded in the relevant plan or phase artifact.

## Validation

Verified commands (Xcode 27, deployment target iOS 27.0, simulator iPhone 17e):

- Build: `xcodebuild build -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=11E7E98A-D558-4E53-B211-CB4ACD1FBB38'`
- Tests: `xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=11E7E98A-D558-4E53-B211-CB4ACD1FBB38' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests`

The app uses `PBXFileSystemSynchronizedRootGroup`, so new `.swift` files under `SwiftyCitizen/` and `SwiftyCitizenTests/` are picked up automatically; do not edit `project.pbxproj` manually.