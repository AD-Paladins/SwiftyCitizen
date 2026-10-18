# Progress Hero Redesign — Task Tracker

Feature: progress-hero-redesign
Source of intent: Stitch design "Progress - Diagnostic & Mastery" (`new-progress-screen`, project `13329010267888174190`), reviewed 2026-10-17.
Route: direct inline (ODD). Faithful reproduction of the "Latest mock test" hero in SwiftUI.
Engram mirror: `odd/progress-hero-redesign/tasks`

## Context

The shipped `readinessHero` renders an honest last-mock result on a flat `palette.primary` card.
The Stitch design shows a **dark-emerald gradient** card with a big score, a status pill (amber when
failed / green when passed), a progress bar filled to the score, the passing mark shown as text, and
a Retake action returning to the Practice tab. This change reproduces that hero. The `docs/plan/progress-*.md`
design docs are stale vs Stitch and are updated **after** code (user choice: code first).

## Fidelity notes (concessions, documented)

- **Card background**: 3-stop dark emerald gradient `#0B4D3C → #094233 → #04281E` (design hex). Not an
  app palette token — `palette.primary` (`#0A6D4F`) is brighter. ponytail: promote to palette tokens if this
  card pattern repeats.
- **Typography**: the app locks `CivicText` = SF Pro Rounded; Stitch uses Plus Jakarta Sans (bundling is
  forbidden per `Info.plist`). Score maps to `CivicText.displayLG` (32px, closest to the design's 38px);
  labels/metadata to `labelMD`/`bodySM`. Colors / gradient / shadow / shapes ARE faithful; typography is
  the one unavoidable concession.
- **Status color**: `palette.warning` (amber) when failed, `palette.success` (green) when passed — for both
  the pill and the progress-bar fill.

## Tasks

- [ ] H1. Rebuild `readinessHero` → dark-gradient "Latest mock test" card (score, status pill, progress
        bar, passing-mark + coverage metadata, Retake → Practice tab).
- [ ] H2. Add localization keys: `progressHeroMockLabel`, `progressMockNotPassed`, `progressMockPassed`,
        `progressPassingMarkPrefix`, `progressMockSeen`, `progressRetakeMockExam`.
- [ ] H3. Build + run SwiftyCitizenTests.

## Progress

- [x] H1. Rebuilt `readinessHero` → dark-gradient "Latest mock test" card (score, status pill, progress
        bar, passing-mark + coverage metadata, Retake → Practice tab, Mistakes → placeholder).
- [x] H2. Added localization keys: `progressHeroMockLabel`, `progressMockNotPassed`, `progressMockPassed`,
        `progressPassingMarkPrefix`, `progressMockSeen`, `progressRetakeMockExam`.
- [x] H3. Build + run SwiftyCitizenTests.

## Verification

- Build: `xcodebuild build ... SwiftyCitizen` → **BUILD SUCCEEDED**.
- Tests: 253 tests in 23 suites — **all passed** (0.250s).
- Commits on `feat/design-aligned-redesign`:
  - `ef23784 feat(progress): faithful Latest mock test hero in Progress screen`
  - `4d111c0 feat(progress): add Mistakes action to hero (placeholder destination)`
  - `696daff feat(progress): stack Retake and Mistakes buttons in a 2:1 row`

Buttons sit in one `HStack`: Retake fills (`frame(maxWidth: .infinity)`) and Mistakes takes its
natural content width — no rigid fractions, so the proportion and alignment come out naturally.

## Reusability (2026-10-17)

Extracted the hero into a standalone `LatestMockTestHero` view (`Features/Progress/LatestMockTestHero.swift`).
Contract: data in (`result`, `coverage`, `date`), callbacks out (`onRetake`, `onMistakes`). It does
NOT own navigation — `ProgressTabView` still wires Mistakes to its own `mistakesRoute` + placeholder.
No SwiftData/SwiftUI-navigation coupling, so it can be reused elsewhere. Added 3 previews (Passed /
Failed / Empty). ProgressTabView now only derives the data and instantiates the view.

Mistakes button: secondary outlined capsule below Retake, wired via `@State mistakesRoute` +
`.navigationDestination(item:)` to `mistakesComingSoon` (placeholder). The real mistakes window is
not built yet — the button exists and is functional/testable now.

## Next

Update `docs/plan/progress-ui-spec.md`, `progress-spec.md`, and
`progress-diagnostic-mirror-design.md` hero sections to match Stitch (deferred — code first).
