# Inherited Font Dynamic Type Specification

## Purpose

Define the user-facing behavior for Dynamic Type scaling of inherited-font text in
the app. An *inherited-font* view is a `Text`, `Label`, or `Button` that renders
through the environment font and declares **no** explicit `.font()` modifier. This
spec requires that such views reflow with Dynamic Type because the app-root font
environment is a scaling semantic font, not an absolute frozen size.

This capability is introduced by change 6.1, which removes/replaces the root font
pin at `SwiftyCitizen/App/SwiftyCitizenApp.swift:45`. It is a NEW capability; there
is no existing main-spec requirement to modify.

## Requirements

### Requirement: App-root font environment is a scaling semantic font

The app root (`SwiftyCitizenApp`) SHALL set the `\.font` environment value to a
scaling semantic font (for example `.body`), OR omit the modifier entirely so
SwiftUI falls back to its default scaling base font. The system SHALL NOT pin an
absolute frozen size at the app root.

#### Scenario: Root uses a scaling semantic font

- GIVEN the app root sets `.environment(\.font, .body)` (or omits the modifier)
- WHEN any inherited-font `Text`/`Label`/`Button` is rendered
- THEN its resolved font is a scaling semantic font that changes point size as the
  user's Dynamic Type accessibility level changes

#### Scenario: Root does not pin an absolute size

- GIVEN the app root previously pinned `.environment(\.font, .system(size: 16, weight: .regular, design: .rounded))`
- WHEN that line is removed or replaced with a scaling semantic font
- THEN the frozen absolute 16 pt value no longer overrides Dynamic Type for inherited-font views

### Requirement: Inherited-font text reflows with Dynamic Type

The system SHALL ensure that every inherited-font `Text`/`Label`/`Button` scales
its point size in response to the accessibility Dynamic Type level. The scaling is
inherited from the app-root environment font, so it applies app-wide at once without
per-view changes.

#### Scenario: Inherited-font Text scales at accessibility sizes

- GIVEN a view that renders a plain `Text` with no explicit `.font()` modifier
- WHEN the accessibility Dynamic Type level is raised (for example to
  `.dynamicTypeSize(.accessibilityLarge)` or higher)
- THEN the rendered text increases its point size and reflows to fit the larger line
  height

#### Scenario: Inherited-font Label and Button scale

- GIVEN a `Label` or `Button` with no explicit `.font()` modifier
- WHEN the Dynamic Type level is raised
- THEN both the label/button content increase their point size and reflow

### Requirement: Views with explicit semantic fonts are unaffected

The system SHALL NOT change the behavior of views that already apply their own
semantic font (`.body`, `.headline`, etc.). Those views already scale and remain
unchanged by this capability.

#### Scenario: Explicit semantic font view keeps its own scaling

- GIVEN a view that applies an explicit semantic font modifier (for example `.font(.headline)`)
- WHEN the Dynamic Type level is raised
- THEN the view scales according to its own explicit font, exactly as before this change

### Requirement: Brand-rounded and direct-size text are unchanged (deferred)

The system SHALL NOT convert `CivicText` brand tokens or the 12 direct
`.system(size:)` calls outside `CivicText` to semantic fonts in this capability.
Those remain at their fixed rounded/fixed sizes and are tracked separately as task
B3. This requirement documents the boundary, not a regression claim.

#### Scenario: CivicText stays brand-locked

- GIVEN a `CivicText`-styled label (SF Pro Rounded, fixed point size)
- WHEN the Dynamic Type level is raised
- THEN its point size is unchanged; scaling for these tokens is deferred to B3

#### Scenario: Decorative direct-size icon sites are untouched

- GIVEN the two `.system(size: 56)` SF Symbol icon sites (decorative,
  `.accessibilityHidden(true)`)
- WHEN the Dynamic Type level is raised
- THEN they are unchanged; they are not text and are not converted

## Verification Requirements

### Requirement: Dynamic Type preview for inherited-font reflow (primary, on-device)

The change SHALL include a Dynamic Type preview (`#Preview`) in `SwiftyCitizenTests`
that renders an inherited-font `Text`/`Label`/`Button` across accessibility sizes
(for example `.dynamicTypeSize(.accessibilityLarge)` and the default size). The
preview is the primary reflow check and is verified on device. Simulator output is
indicative only.

#### Scenario: Preview renders inherited-font text at multiple sizes

- GIVEN a `#Preview` in `SwiftyCitizenTests` that hosts an inherited-font `Text`
- WHEN the preview is evaluated at `.dynamicTypeSize(.default)` and
  `.dynamicTypeSize(.accessibilityLarge)`
- THEN both render without error and the larger size shows visibly reflowed text

### Requirement: strict_tdd suite green (regression guard)

The full unit suite SHALL remain green after the change:

```
xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests
```

This proves no existing behavior regressed. It does not by itself prove the
on-device Dynamic Type reflow (see the Dynamic Type preview above).

### Requirement: Inherited-font scaling probe test (feasibility-dependent)

The change SHALL include a focused probe test asserting that the resolved inherited
font is a scaling semantic font rather than the frozen absolute size. The exact
assertion mechanism for font-resolution introspection in XCTest is an
implementation decision. If font-resolution introspection proves infeasible in
XCTest, the Dynamic Type preview plus strict_tdd suite green remain the guard and
the probe test is omitted with a documented reason.

#### Scenario: Probe resolves the inherited font to a scaling semantic font

- GIVEN a view hierarchy rooted at the app-root environment font
- WHEN the inherited font resolved for an inherited-font `Text` is inspected
- THEN the resolved font is a scaling semantic font (not `.system(size: 16, ...)`)

#### Scenario: Probe infeasibility falls back to preview + suite green

- GIVEN that XCTest cannot introspect the resolved environment font for the target OS
- WHEN the probe test cannot be written
- THEN the probe test is omitted, the omission is documented, and the Dynamic Type
  preview plus strict_tdd suite green remain the verification guard
