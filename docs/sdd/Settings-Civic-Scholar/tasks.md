# Tasks: Settings — Civic Scholar

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~320 |
| 400-line budget risk | Medium |
| Chained PRs recommended | Yes |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: size-exception
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Foundation: `passingPercentage`, scoped reset, primitives | PR 1 | `test ... -only-testing:.../TestConfigurationTests + SettingsResetTests` | In-memory unit tests | domain/reset/primitive files |
| 2 | Section subviews (config, study-set, appearance) | PR 2 | `build ...` | Section previews | new section files |
| 3 | Thin root + localization keys | PR 3 | `build ...` | SettingsView + reset preview | SettingsView.swift + xcstrings |
| 4 | Verification: Dynamic-Type, spec scenarios | PR 4 | `test ... -only-testing:SwiftyCitizenTests` | AX previews + audit skill | test-only additions |

## Phase 1: Foundation

- [x] 1.1 RED test in `SwiftyCitizenTests/Domain/TestConfigurationTests.swift`: `passingPercentage == 0.6` for all three versions and `nil` when max = 0.
- [x] 1.2 Add `passingPercentage: Double?` to `Core/Domain/TestConfiguration.swift`; keep `import Foundation`; run GREEN.
- [x] 1.3 RED test in new `SwiftyCitizenTests/Domain/SettingsResetTests.swift`: in-memory container with saved config + two attempts; after reset attempts == 0 and config + filing date remain.
- [x] 1.4 Create `Core/Persistence/SettingsReset.swift` free function deleting only QuestionAttempt rows (no-op when none); run GREEN; add zero-attempts no-op assertion.
- [x] 1.5 Create `Features/Settings/SettingsRow.swift`: shared section header, key-value row, card modifier on existing `.cardStyle()`, `Space`, `CivicText`.

## Phase 2: Core Implementation

- [x] 2.1 Create `Features/Settings/ConfigPreferencesSection.swift`: read-only Test Configuration row (version, filing date, study language) in a `NavigationLink` to the editor.
- [x] 2.2 Create `Features/Settings/StudySetSummarySection.swift`: "Your Study Set / USCIS Standards" deriving maxQuestionsAsked, passingScore, `passingPercentage` from config + static gavel disclaimer.
- [x] 2.3 Create `Features/Settings/AppearanceSection.swift`: theme `Picker` + presentation-only rows — Theme Palette swatch + "Archive" tag, Card Text Sizing label, Streak Shield "1 active"; no navigation/logic.

## Phase 3: Integration / Wiring

- [x] 3.1 Rewrite `Features/Settings/SettingsView.swift` as a thin `List` composing the three sections; keep modelContext, saved-config query, ThemeManager, injected configuration.
- [x] 3.2 Replace buggy `resetProgress()` with scoped reset: single RED dialog (`.buttonRole(.destructive)` → `resetSpacedRepetition(modelContext)`); no bookmark mentions.
- [x] 3.3 Remove old inline sections (settingsTestConfiguration, the `isSixtyFiveTwentyEligible` "65/20" block, settingsPrivacy).
- [x] 3.4 Add `settings*` keys to `SwiftyCitizen/Localizable.xcstrings` (English): section headers, gavel disclaimer, reset dialog copy; localize hardcoded `"65/20"` header.

## Phase 4: Testing / Verification

- [x] 4.1 Per-section `#Preview`s with in-memory model container; summary reflects active version (spec "summary tracks active config").
- [x] 4.2 Preview summary per version; confirm 60% label for 2008, 2025, 65/20 (spec "all three versions show 60%").
- [x] 4.3 Dynamic-Type: preview all sections at largest accessibility font; no clip; run audit skill if available.
- [x] 4.4 Run full build + test commands from `AGENTS.md`; confirm reset preserves filing date.
