# Delta Spec — Settings: Civic Scholar

## Purpose

Rebuild the Settings tab into a branded "Civic Scholar" experience: a re-skinned Study & Exam Preferences section, a read-only Your Study Set summary, an existing theme palette row, and three presentation-only rows (Card Text Sizing, Streak Shield, Data/reset). USCIS derivation, content source, SwiftData architecture, and the `TestConfigurationView` editor are UNCHANGED.

## config-editor

### Requirement: study-and-exam-preferences section

The Settings screen SHALL present the Study & Exam Preferences section reusing the existing `OnboardingConfiguration` domain. It SHALL expose a "Test Configuration" row whose derived summary shows the selected test version and filing date; tapping it SHALL navigate to the existing `TestConfigurationView` editor. Edits SHALL persist via the existing `SavedOnboardingConfiguration`. The screen MUST NOT alter `OnboardingConfiguration` derivation or validation.

#### Scenario: section shows derived summary
- GIVEN a valid configuration with version 2025 and a filing date
- WHEN the Settings screen renders
- THEN the Test Configuration row shows "2025 civics test" and the filing date
- AND both are read-only values, not editable inline

#### Scenario: tap opens editor, edit persists
- GIVEN the user is on Settings
- WHEN the user taps the Test Configuration row, edits the config, and saves
- THEN `TestConfigurationView` opens and the change persists to `SavedOnboardingConfiguration`
- AND Settings re-renders with the updated version and filing date

## study-set-summary

### Requirement: your-study-set summary

The Settings screen SHALL show a read-only "Your Study Set / USCIS Standards" section that derives `maximumQuestionsAsked` and `passingScore` from the active `TestConfiguration` (via `OnboardingConfiguration.testConfiguration`) and displays a passing-percentage label computed as `passingScore ÷ maximumQuestionsAsked`. It SHALL show the static gavel disclaimer. The percentage MUST be derived, never hardcoded.

#### Scenario: all three versions show 60%
- GIVEN the active configuration is 2008, 2025, or 65/20
- WHEN the summary renders
- THEN `maximumQuestionsAsked` and `passingScore` match the active `TestConfiguration`
- AND the percentage label reads 60% for every version

#### Scenario: summary tracks active config
- GIVEN the user changes the version inside the editor
- WHEN Settings re-renders
- THEN the summary reflects the newly selected configuration's values

## reset-progress

### Requirement: scoped spaced-repetition reset

The Settings screen SHALL offer a "Reset Spaced Repetition" action that deletes only `QuestionAttempt` rows and MUST preserve `SavedOnboardingConfiguration` (including the filing date) and all other data. The action SHALL require confirmation via a dialog before deleting. The confirmation copy MUST NOT reference bookmarks, as no bookmarks feature exists.

#### Scenario: reset clears attempts, keeps config
- GIVEN `QuestionAttempt` rows exist alongside a saved configuration with a filing date
- WHEN the user confirms the reset
- THEN all `QuestionAttempt` rows are deleted
- AND the configuration and its filing date remain intact

#### Scenario: zero-attempts reset is a no-op
- GIVEN no `QuestionAttempt` rows exist
- WHEN the user confirms the reset
- THEN no configuration or filing data is affected
- AND no error is raised

## settings-restyle

### Requirement: civic restyle

The Settings screen SHALL be composed of section subviews rendered with the redesign style: `CardStyle` radius and shadow, the `Space` scale for spacing, and `CivicText` (SF Pro Rounded) for typography. All user-facing copy SHALL be localized via `settings*`-prefixed keys in the String Catalog (English source). The restyle MUST NOT alter any USCIS config derivation and SHALL be Dynamic-Type-safe: no fixed point sizes that clip text at the largest accessibility sizes.

#### Scenario: placeholder rows render labels
- GIVEN the Settings screen
- WHEN rendered
- THEN Theme Palette shows a swatch with an "Archive" tag, Card Text Sizing and Streak Shield show their labels (e.g. "1 active")
- AND these rows are presentation-only and need not navigate anywhere

#### Scenario: no fixed text clips at max Dynamic Type
- GIVEN the largest accessibility font size
- WHEN the screen renders with long localized strings
- THEN text does not clip or overflow its container
