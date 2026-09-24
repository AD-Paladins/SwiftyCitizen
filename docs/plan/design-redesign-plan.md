# Plan de Rediseño Visual (Civic Scholar)

Last updated: September 24, 2026

## Goal

Redesign the SwiftyCitizen UI to match the high-fidelity designs created in Google
Stitch ("App Ciudadanía USA"), moving from the current flat, hardcoded look to a
tactile editorial aesthetic (cream paper, emerald primary, white cards, warm shadows,
Plus Jakarta Sans scale). This is a **visual redesign** of the existing app; it does not
change the content source, the USCIS rules, or the underlying architecture.

## Locked Decisions

| Decision | Choice | Rationale |
| --- | --- | --- |
| Scope | Restyle the current app; keep the existing architecture and official content. | The study flows, persistence, and rules are solid; only the visual layer changes. |
| Typography family | **SF Pro Rounded (native)** via `.design(.rounded)`. | Stitch uses Plus Jakarta Sans, but a custom font requires creating `Info.plist` + bundling `.ttf` + a font helper. SF Rounded needs no new files, stays native, and reads very close to the design. The *scale* (sizes/weights) still comes from Stitch. |
| Design source of truth | Google Stitch project "App Ciudadanía USA" (`13329010267888174190`), read via the `stitch` MCP. | The designs live there; tokens are summarized below so the app can be built from docs without the AI tool (see `design-tools.md`). |
| Theme system | Keep the 3-theme selector (`AppTheme` + `ThemeManager`). Align `paperEmerald` to the Stitch tokens first; other themes follow later if at all. | `paperEmerald` is already closest to the Stitch aesthetic; changing only values keeps every view in sync automatically. |

## Design System Summary (from Stitch)

Stitch is authoritative for exact values. Key tokens captured here so implementation can
proceed without the MCP:

- **Colors**
  - Paper background / canvas: `#FDF9F1`
  - Card surface: `#FFFFFF` (with a `1px solid rgba(22,28,24,0.04)` rim)
  - Primary (deep forest emerald): `#0B6E4F`; primary-container: `#0B6E4F`; on-primary: `#FFFFFF`
  - Ink / primary text: `#1A1C19`; muted sage (metadata): `#566158`; border hairline: `#E6E1D6`
  - Secondary (heritage amber — streaks, review queues): `#E08714`
  - Tertiary (mint green — mastered): `#22C55E`
  - Critical / due (soft coral): `#EF4444`
  - SRS rating washes: Again `#FEE2E2` bg / `#DC2626` text; Hard `#FEF3C7` bg / `#D97706` text; Mastered `#DCFCE7` bg / `#16A34A` text
- **Typography scale** (family = SF Pro Rounded per decision above)
  - `display-lg` 32/800 (mobile 26/800), `metric-display` 28/800, `headline-lg` 22/700,
    `headline-md` 18/700, `headline-sm` 16/600, `body-lg` 16/500, `body-md` 14/400,
    `body-sm` 12/400, `label-lg` 14/600, `label-md` 12/600, `label-sm` 11/600
- **Shapes**: cards 16–20px (`rounded-2xl`); buttons, pills, rating controls and progress
  tracks fully rounded (`9999px`)
- **Elevation**: paper cards use a dual warm drop
  `0 2px 8px -2px rgba(34,38,34,0.05), 0 1px 3px 0 rgba(34,38,34,0.03)`; floating controls
  use `0 12px 32px -8px rgba(27,36,28,0.08), 0 4px 12px -2px rgba(27,36,28,0.04)`
- **Spacing** (rem → px): `space-xs` 4, `space-sm` 8, `space-md` 16, `space-lg` 20,
  `space-xl` 28, `space-2xl` 40; card internal padding = `space-lg` (20)

## Accessing the Designs

The `stitch` MCP exposes the project even though `list_mcp_resources` returns nothing.
Read it directly:

1. `tools.stitch.list_projects()` → find "App Ciudadanía USA" (`13329010267888174190`).
2. `tools.stitch.list_screens({ projectId })` → titles + screenshot/HTML references.
3. Screens with interactive HTML (Home "Exam Readiness", Flashcards "Active Study Session")
   expose full markup; the rest are PNG screenshots.

The app must remain implementable from this Markdown + the documented tokens without the AI
tool, per `design-tools.md`.

## Phased Breakdown

Each phase is a reviewable slice. Start each phase by analyzing every new component
(functionality → logic → design-in-code) before writing UI.

### Phase 0 — Design System Base (prerequisite for everything)

1. **Colors** — align `paperEmerald` to the Stitch tokens above. Lowest risk: only token
   values change; names stay the same and every view re-renders.
2. **Typography** — a `CivicText` helper mapping the Stitch scale to SF Rounded text styles.
3. **Cards + buttons** — a `CardStyle` view modifier (16–20px radius, warm dual shadow) and
   pill button styles for CTAs and SRS ratings. Today the radius is hardcoded to 12 and no
   views use shadows.
4. **Spacing** — map `space-xs…2xl` to SwiftUI spacing.

Exit: a learner can theme the whole app through `paperEmerald` and every screen uses
`CardStyle`, the typography helper, and the spacing scale instead of hardcoded values.

#### Typography migration backlog (deferred — resolve as screens are restyled)

`CivicText` (the Stitch scale → SF Rounded) was created in the `phase-0/typography` slice, and
SF Rounded is applied globally at the app root via `.environment(\.font, .system(design: .rounded))`.
That global application only rounds views that do **not** set an explicit font style; SwiftUI
resolves explicit styles like `.headline`/`.subheadline`/`.footnote`/`.caption` to their own
non-rounded font. The app currently has **67** such `.font(` call sites (all semantic styles, no
custom fonts registered). They are intentionally left untouched so each slice stays small; they
get rounded/migrated as each screen is restyled in later phases:

- **Phase 1 (Home)** — restyle `HomeDashboardView` and its components using `CivicText` by name.
- **Phase 3 (Flashcards)** — `FlashcardSessionView` has the densest typography (headline, footnote,
  caption, caption2, the `size: 56` score). Migrate it to `CivicText` here; replace the two raw
  `.system(size: 56)` score displays with a rounded metric style.
- **Phase 4 (Targeted Review)** — `TargetedReviewView`, `SessionSummaryView` (note the
  `.monospacedDigit()` numeric readouts).
- **Phase 5 (Settings + Config)** — `TestConfigurationView`, `SettingsView`.
- **Practice** — `MockTestSetupView`, `MockTestSessionView`, `MockTestResultView`.
- **Shared** — `Components.swift` (verdict/label styles) is the highest-leverage shared file;
  migrate it early so reused pieces pick up the scale.

Priority: shared components and Home first, then the dense flashcard screen, then the rest. Each
migration is a per-screen slice, not a repo-wide find-and-replace.

#### Cards + buttons migration backlog (deferred — resolve as screens are restyled)

`CardStyle` (surface + radius 16–20px + warm dual shadow) and `PillButtonStyle` (fully-rounded CTA)
were created in the `phase-0/cards-buttons` slice. `CardStyle` was applied to the shared cards in
`Components.swift`; `PillButtonStyle` was applied to `PrimaryActionButton`. The rest is deferred:

- **Cards:** every screen builds its surface with the old recipe
  `.background(palette.surface, in: RoundedRectangle(cornerRadius: 12))`. Replace it with
  `.cardStyle()` (radius 16–20) as each screen is restyled. Sites outside `Components.swift`:
  `FlashcardSessionView` (QuestionCard, AnswerCard, SelfAssessmentControl), `MockTestSessionView`,
  `SessionSummaryView`, `HomeDashboardView`. Leave tint-filled chips like `SessionFeedbackIndicator`
  untouched — they are colored pills, not cards.
- **Buttons:** the SRS rating tiles (`Again`/`Hard`/`Got it`) and the raw `.bordered`/`.borderedProminent`
  CTAs scattered across screens pick up `PillButtonStyle` as they are restyled. Priority: shared
  `Components.swift` first, then flashcards (densest), then the rest.

> **iOS 27 API gotcha:** `ButtonStyle`'s requirement changed — it is now
> `func makeBody(configuration:)`, not the older `func body(configuration:)`. A custom style using
> the old name silently fails to conform. `configuration.label` and `configuration.isPressed` still
> apply. Reuse `PillButtonStyle` as the template for any future button style.

#### Spacing migration backlog (deferred — resolve as screens are restyled)

`Space` (`Shared/Theme/Space.swift`, enum with `xs=4, sm=8, md=16, lg=20, xl=28, 2xl=40` + a
`.padding(_:)` extension) was created in the `phase-0/spacing` slice and applied to the shared
`Components.swift`: `spacing: 8` → `Space.sm.value`, `.padding(.vertical, 20)` → `Space.lg.value`,
`.padding(16)` → `.padding(.md)`.

Two edges of the Stitch scale do **not** map cleanly and are intentionally left hardcoded (do not
invent new tokens for them now):

- **`24`** — the most common page-level padding (~7 sites across the app), but it is not in the
  Stitch scale (which jumps `20 → 28`). It sits between `lg` and `xl`; mapping it is a design
  decision, not a token one.
- **`12`** — the single most common *stack* gap, also not a Stitch token.
- Minor tight gaps (`2`, `6`, `10`) and the no-arg `.padding()` default are left as-is.
- `space-2xl = 40` is not used anywhere yet.

These get mapped per-screen as each phase restyles its screen; whether `24`/`12` earn new tokens is
a Phase 1 design decision. Each migration is a per-screen slice, not a repo-wide find-and-replace.

### Phase 1 — Home / Exam Readiness (biggest change)

The Home has ~13 components; roughly seven require logic or data that does not exist yet.
See the component breakdown below. Prioritize components backed by existing data and defer
speech/retention/reading until their data layer exists.

Exit: the Home renders the prioritized components from real persisted data, styled with the
Phase 0 base; deferred components show as placeholders or remain on the backlog.

#### Phase 1 progress

- **Slice 1 (Home restyled with the Phase 0 base):** `HomeDashboardView` now uses `Space`,
  `CivicText`, and `.cardStyle()` instead of hardcoded radii/semantic fonts. It renders the
  data-backed sections that already have persisted input — a time-based greeting, the version pill
  (`ConfigurationSummaryView`), "Continue studying" (Start review CTA), "Today" (reviewed-today +
  "Got it" rate), and "Due next" (due-count card → Study). The shared `SummaryMetricView`,
  `ConfigurationSummaryView`, and `EmptyStateView` were restyled to `CivicText`/`Space` too.
- **Slice 2 (Exam Readiness hero):** Added a coverage-based `readinessPercentage` metric to
  `StudyProgressMetrics` (`coveredCount / questionBankCount`) and rendered an "Exam Readiness" hero
  card at the top of the Home — a metric-display percentage plus "X of N questions covered" on a
  primary-filled card. This is the data-backed readiness component from the backlog; it counts
  distinct answered question IDs for the active version (no new persistence).
- **Deferred until their data layer exists** (backlog, resolved in later Phase 1 slices or moved to
  the product backlog): Readiness Score mastery buckets + 6/10 threshold (coverage % now exists),
  Mastery breakdown buckets, Streak card, Tip banner, Daily Milestone
  (target + today's progress), Focused Practice carousel, Oral Mock Interview (speech → Phase 4),
  Weak Spots, Weekly Memory Retention, Reading card, and the personalized "Good morning, Alex"
  header (no user-name field exists). Each is a separate slice; none are built as empty placeholders.

### Phase 2 — Study Hub

Redesign the Study tab landing and its entry points to match the new designs.

### Phase 3 — Flashcards (active session + answered state)

The design shows an explicit "Leitner box N" indicator and Again/Hard/Mastered ratings with
spaced-repetition intervals (`Again <1m`, `Hard In 2d`, `Mastered In 6d`). Decide whether to
adopt the Leitner box model (boxes 1–5) or keep the current self-assessment SRS; naming
shifts `Got it` → `Mastered`.

### Phase 4 — Targeted Review

Redesign Targeted Review to match the new visual language.

### Phase 5 — Settings + Edit Configuration

Redesign Settings and the test-configuration editor.

### Out of scope for now

The new designs do not show a Progress screen or a mock-test screen. The existing Progress
and Practice (mock test) tabs are kept as-is or tackled in a later redesign pass.

## Home — Component Breakdown

For each component: what it shows, the logic/data it requires, and whether that already
exists in the app.

| Component | Shows | Logic / data required | Already exists? |
| --- | --- | --- | --- |
| Header | "Good morning, Alex", avatar, settings, verified badge | Persisted user name; badge reflects active config | Partial (badge is new) |
| Streak card | "5-day streak" 🔥 | Current streak from study history | No |
| Version pill | "2008 / 100 official bank / Spanish audio active" + edit | Reads active `TestConfiguration` | Yes (data) |
| Readiness Score | 68% circular, "Naturalization Exam Ready", pass mark 6/10 | Coverage % from distinct answered IDs (built as hero in Slice 2); mastery buckets + 6/10 threshold | Partial |
| Mastery breakdown | Mastered 68 / Due 21 / Unseen 11 | Buckets from attempt history | Partial |
| Tip banner | Statistical tip | Static/rotating tips content | No |
| Daily Milestone | ~4 min, daily target 10 cards, progress bar 8/10, "Continue Daily Review", "12 due" | Persisted daily target + today's progress | No |
| Focused Practice carousel | "View all (5)" | **Undefined** — what are the 5 items? | No |
| Oral Mock Interview | "Start simulation" (speech) | Speech recognition → Phase 4 | No (defer) |
| Weak Spots | "3 items", weak area, "Drill tricky cards" | Algorithm for weak categories/questions | No |
| Weekly Memory Retention | Calendar M–S, "142 total answered" | Per-day answered aggregation | No |
| Reading card | "Recommended reading before today's test" | New content type (source undefined) | No |
| Bottom nav | Home / Study / Practice / Progress | Same as current | Yes |

## Open Decisions (resolve when each phase starts)

- **Home scope**: build all ~13 components, or prioritize the data-backed ones (Readiness,
  mastery breakdown, Daily Milestone) and defer speech, weekly retention, weak spots, and the
  reading card?
- **Leitner model**: adopt the explicit Leitner box (1–5) model shown in the Flashcards
  design, or keep the current self-assessment SRS? Naming shifts `Got it` → `Mastered`.
- **Other themes**: after aligning `paperEmerald`, keep the "Civic Navy" and "Study Calm"
  pickers, or converge the app to one look?

## References

- Stitch project "App Ciudadanía USA" (`13329010267888174190`) — authoritative design source.
- `docs/plan/design-tools.md` — tool decision and the "buildable without AI" principle.
- `docs/plan/current-status.md` — current implementation status.
