# Design: Settings — Civic Scholar

## Technical Approach

Rebuild `SettingsView` as a composition of section subviews under `Features/Settings/`. The root keeps the SwiftData environment (`modelContext`, `@Query savedConfigurations`) and injected `OnboardingConfiguration`; it lays out section subviews in one `List`. No domain change: `OnboardingConfiguration`/`TestConfiguration` stay Foundation-only; the editor (`TestConfigurationView`) is reused as-is. The read-only Study Set summary derives from `OnboardingConfiguration.testConfiguration`. Reset is scoped to `QuestionAttempt`. Styling reuses existing `CardStyle`/`CivicText`/`Space`.

## Architecture Decisions

### Decision: compose SettingsView into section subviews
| Option | Tradeoff | Decision |
|---|---|---|
| Monolithic `body` (current) | ~78 lines, one Preview, hard to isolate Dynamic-Type regressions | **Rejected** |
| Section subviews under `Features/Settings/` | Each independently previewable/testable; root stays thin | **Chosen** |
| Full MVVM ViewModels | Overkill for presentation-only rows | **Rejected** |

Rationale: mirrors `HomeDashboardView`'s small-view split; per-section `#Preview`s isolate Dynamic-Type and palette regressions.

### Decision: passing-percentage derivation
| Option | Tradeoff | Decision |
|---|---|---|
| Hardcode "60%" in view | Breaks if a config changes; violates spec ("derived, never hardcoded") | **Rejected** |
| Computed property `TestConfiguration.passingPercentage` (Foundation) | Pure, testable, no SwiftUI; tracks active config automatically | **Chosen** |
| Static func in `StudyProgressMetrics` | Intrinsic to config, not an attempts metric | **Rejected** |

Rationale: value derives from `passingScore ÷ maximumQuestionsAsked`; all three configs yield 0.6; summary tracks the active version.

### Decision: scoped reset
| Option | Tradeoff | Decision |
|---|---|---|
| Current `resetProgress()` deletes `SavedOnboardingConfiguration` | **Bug** — wipes filing date + config | Rejected |
| Free function deleting only `QuestionAttempt` rows via `modelContext` | Config/filing untouched; zero-attempts is a no-op | **Chosen** |
| New reset-tracking model | Unnecessary schema change | **Rejected** |

Rationale: the current bug deletes the filing date. The fix queries `FetchDescriptor<QuestionAttempt>`, deletes those rows only, and leaves `SavedOnboardingConfiguration` untouched (confirmation copy never mentions bookmarks). Reset is a pure destructive action: a single red confirmation dialog (`.buttonRole(.destructive)`), matching the existing reset copy.

### Decision: restyle via existing helpers
| Option | Tradeoff | Decision |
|---|---|---|
| Define new Card/Space/font types | Duplication, drift from the Home recipe | **Rejected** |
| Reuse `CardStyle`, `CivicText` (SF Pro Rounded), `Space` | Consistent theme; no Info.plist/font-bundle change | **Chosen** |

Rationale: helpers already exist and are used by Phase 1 `HomeDashboardView`; `CivicText` is locked to SF Pro Rounded — never bundle Stitch's Plus Jakarta Sans or touch Info.plist.

## Data Flow

```
OnboardingConfiguration ──► SettingsView (root)
        │
        ├──► ConfigPreferencesSection ──► NavigationLink ─► TestConfigurationView (edit → persist SavedOnboardingConfiguration)
        │                                         │
        └──► testConfiguration ─► StudySetSummarySection ─► passingPercentage (0.6 / 60%)
        │
        └─(modelContext)─► reset button ─► resetSpacedRepetition ─► delete QuestionAttempt only
        │
        └─(themeManager.palette)─► AppearanceSection ─► ThemePaletteRow (swatch + "Archive")
```

## File Changes
| File | Action | Description |
|------|--------|-------------|
| `Features/Settings/SettingsView.swift` | Modify | Thin List of section subviews; wire reset button + confirmation |
| `Features/Settings/ConfigPreferencesSection.swift` | Create | "Test Configuration" row (version, filing date, language) → editor link |
| `Features/Settings/StudySetSummarySection.swift` | Create | Read-only Your Study Set / USCIS Standards + static gavel disclaimer |
| `Features/Settings/AppearanceSection.swift` | Create | Theme picker + presentation rows (swatch+Archive, Card Text Sizing, Streak Shield) |
| `Features/Settings/SettingsRow.swift` | Create | Shared styled row/section primitives |
| `Core/Domain/TestConfiguration.swift` | Modify | Add `passingPercentage: Double?` |
| `Core/Persistence/SettingsReset.swift` | Create | `resetSpacedRepetition(_:)` deletes only QuestionAttempt rows |
| `SwiftyCitizen/Localizable.xcstrings` | Modify | Add `settings*` keys; localize hardcoded "65/20" header |

## Interfaces / Contracts

```swift
extension TestConfiguration {
    var passingPercentage: Double? {
        guard maximumQuestionsAsked > 0 else { return nil }
        return Double(passingScore) / Double(maximumQuestionsAsked)
    }
}

func resetSpacedRepetition(_ context: ModelContext) {
    let attempts = (try? context.fetch(FetchDescriptor<QuestionAttempt>())) ?? []
    if !attempts.isEmpty {
        attempts.forEach(context.delete)
        try? context.save()
    }
}
```

## Testing Strategy
| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | All three configs → 0.6; nil when max = 0 | Call `passingPercentage`, assert equality |
| Unit | Reset deletes QuestionAttempt, keeps SavedOnboardingConfiguration + filing date | In-memory container: insert both, call `resetSpacedRepetition`, assert counts |
| Unit | Zero-attempts reset is a no-op, no error | In-memory container, empty attempts, call reset |
| UI | Summary reflects active version; re-renders after edit | Per-section `#Preview` with in-memory modelContainer |
| UI | No clip at largest Dynamic Type | Xcode preview at AX sizes; accessibility audit skill |

## Threat Matrix
N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary; this change is a SwiftUI view composition plus scoped SwiftData deletion.

## Migration / Rollout
No migration required.
## Decisions (resolved from product input)

- **65/20 placement:** Stays where the app already has it — inside the `TestConfigurationView` editor. Settings shows only the read-only "Test Configuration" summary row; the 65/20 toggle is edited in the editor, not a standalone Settings section.
- **Reset dialog style:** Pure destructive action — a single red confirmation dialog (`.buttonRole(.destructive)`), matching the existing reset copy.
- **Streak Shield "1 active":** Static placeholder copy for now; no live `StudyProgressMetrics.streak` binding, no domain dependency. Presentation-only.

## Deferred Features

Theme Palette "Archive" grouping, Card Text Sizing (real font scaling), and Streak Shield (milestone-protection logic) are presentation-only in this slice and DEFERRED. Their intended state management when promoted is documented in `deferred-features.md` so a later slice can promote them without re-specifying behavior.
