# Apply Progress — Settings: Civic Scholar

## Goal
Implement the REMAINING phases (2, 3, 4) of the Settings-Civic-Scholar change. Phase 1
(foundation: `passingPercentage`, `resetSpacedRepetition`, `SettingsRow` primitives) was
already done and building cleanly; it was not touched.

## Instructions
- Finish and verify all tasks; end with a clean `xcodebuild build`.
- No simulator runtime available — verify with build only (tests deferred).
- Domain/persistence stay `import Foundation` only; restyle reuses existing `CivicText`
  (SF Pro Rounded), `Space`, `.cardStyle()`, `AppPalette`, `ThemeManager`.
- All new user-facing copy uses `settings*` keys via `LocalizedStringKey`.
- 65/20 toggle stays in the editor, not in Settings.

## Completed Tasks

### Phase 2 — Section subviews
- **2.1** `Features/Settings/ConfigPreferencesSection.swift` — `SettingsCard` with header
  "Study & Exam Preferences" + a `NavigationLink(destination:)` to `TestConfigurationView`
  whose label is a `SettingsKeyValueRow` showing version + filing date + study language.
- **2.2** `Features/Settings/StudySetSummarySection.swift` — `SettingsCard` with read-only
  rows deriving `maximumQuestionsAsked`, `passingScore`, and `passingPercentage` from
  `configuration.testConfiguration`, plus the static gavel disclaimer. The "Your Study Set"
  title is an icon-led `SettingsSectionTitle` placed OUTSIDE the card by `SettingsView`.
  Three `#Preview`s (2025, 2008/Spanish) show the summary per active version.
- **2.3** `Features/Settings/AppearanceSection.swift` — theme `Picker` (bound to
  `ThemeManager.themeName`) + presentation-only rows: `ThemePaletteRow` (swatch + "Archive"
  tag), "Card Text Sizing", "Streak Shield" ("1 active"). No navigation/logic.

### Phase 3 — Integration / wiring
- **3.1** `Features/Settings/SettingsView.swift` rewritten as a thin `ScrollView` composing
  four section subviews (config, study-set, appearance, danger zone) with icon-led
  `SettingsSectionTitle`s between them; retains `modelContext`, `@Query savedConfigurations`,
  injected `OnboardingConfiguration`, `ThemeManager`.
- **3.2** Buggy `resetProgress()` (which deleted `SavedOnboardingConfiguration`) replaced
  with a card-based danger zone (`SettingsResetCard`) that presents a single red
  `.confirmationDialog` calling `resetSpacedRepetition(modelContext)`. Copy never mentions
  bookmarks.
- **3.3** Removed the old inline `settingsTestConfiguration` section, the
  `isSixtyFiveTwentyEligible` "65/20" block, and `settingsPrivacy`.
- **3.4** Populated the `settings*` keys in `SwiftyCitizen/Localizable.xcstrings` (English
  source) and populated the previously-empty `"65/20"` key.

### Phase 4 — Testing / verification
- **4.1** Per-section `#Preview`s with in-memory model container (SettingsView preview
  includes both `SavedOnboardingConfiguration` and `QuestionAttempt`).
- **4.2** Summary derivation confirmed by inspection: 2008 (6/10), 2025 (12/20), 65/20
  (6/10) all yield `passingPercentage == 0.6` → "60%". (Unit tests already exist in Phase 1;
  execution deferred to a simulator env.)
- **4.3** No fixed-width clipping: every row constrains to `.frame(maxWidth: .infinity,
  alignment: .leading)` and the gavel disclaimer wraps (`.multilineTextAlignment(.leading)`).
  Typography follows the project's locked `CivicText` = SF Pro Rounded (design decision).
- **4.4** `xcodebuild build` → **BUILD SUCCEEDED**, no warnings.

## Files Changed
| File | Action | What |
|------|--------|------|
| `Features/Settings/ConfigPreferencesSection.swift` | Create | Study & Exam Preferences section + editor link; per-version Preview |
| `Features/Settings/StudySetSummarySection.swift` | Create | Your Study Set summary (derived) + gavel disclaimer; 3 Previews |
| `Features/Settings/AppearanceSection.swift` | Create | Theme picker + presentation-only rows; `ThemePaletteRow` helper; Preview |
| `Features/Settings/SettingsView.swift` | Modify | Thin ScrollView composing four section subviews + danger-zone card; icon-led titles; scoped reset; removed inline sections |
| `SwiftyCitizen/Localizable.xcstrings` | Modify | `settings*` keys + localized `"65/20"` header |
| `docs/sdd/Settings-Civic-Scholar/tasks.md` | Modify | Marked Phases 2–4 tasks `[x]` |

## Build Result
```
** BUILD SUCCEEDED **
```

## Deviations from design
- **Reset button API:** the design notes `.buttonRole(.destructive)`; in this SDK that
  modifier is not available on `Button`, so the destructive role is set via the
  `Button(_:role:label:)` initializer (equivalent, and the form the pre-change code used).
  The single red `.confirmationDialog` matches the design.
- **`@Query savedConfigurations` retained** even though the scoped reset no longer reads it
  (task 3.1 explicitly asked to keep the saved-config query at the root). No unused-property
  warning is emitted.
- **Dynamic Type:** the spec asks for no fixed point sizes, but the design deliberately locked
  `CivicText` = SF Pro Rounded (fixed sizes) for brand consistency with `HomeDashboardView`.
  Implementation follows `CivicText` and guarantees no clipping/overflow via maxWidth
  constraints and multiline wrapping on the disclaimer.

## Issues Found
- `NavigationLink(_:destination:label:)` is ambiguous against `isActive:` in this SDK; used
  the unambiguous `NavigationLink(destination:label:)` trailing-closure form instead.
- `.buttonRole(.destructive)` modifier unavailable; used the `role:` initializer.

## Remaining Tasks
None.

## Note
Test execution (`xcodebuild test`) is deferred to a simulator environment. Verification here
is the build, which succeeds cleanly. Phase 1 unit tests (`TestConfigurationTests`,
`SettingsResetTests`) cover the 60% derivation and scoped-reset semantics and should be run
there.

## Status
All tasks complete; ready for `sdd-verify`.
