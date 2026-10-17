# Exploration: 6.1 — Root font pin & app-wide Dynamic Type reflow

## Current State

**The root pin.** `SwiftyCitizen/App/SwiftyCitizenApp.swift:45` sets:

```swift
.environment(\.font, .system(size: 16, weight: .regular, design: .rounded))
```

This overrides the `\.font` environment value for the entire app subtree. Any view that renders text through the *inherited* environment font — a plain `Text("literal")`, `Label`, or `Button` with no explicit `.font()` modifier — freezes at an absolute **16 pt rounded** and does NOT scale with Dynamic Type. Views that apply their own `.font(.body)`, `.font(.headline)`, etc. use semantic fonts and DO scale (unaffected by the pin). So the pin silently caps every un-styled Text literal app-wide.

Historical note (`current-status.md:135`): the root was originally `.system(design: .rounded)` (no size → inherits a scaling semantic size). It was later changed to include `size: 16`, which is what introduced the absolute-size freeze. This is the systemic cause flagged in `product-value-audit.md:148` and `docs/plan/value-rebuild-plan.md:95`.

**Typography design system (`CivicText`).** `SwiftyCitizen/Shared/Theme/CivicText.swift` is the locked brand typographic token system (11 cases: display-lg → label-sm). Every case maps to `.system(size:weight:design:.rounded)` — i.e. **all CivicText fonts are hardcoded point sizes and do NOT scale with Dynamic Type.** It is used pervasively (ProgressTabView ~30 sites, Study, Practice, Settings, Configuration, Components, Progress). The design docs lock `CivicText = SF Pro Rounded` and explicitly forbid bundling an alternative font or touching `Info.plist` (`design-redesign-plan.md`, `Settings-Civic-Scholar/deferred-features.md`).

**Direct hardcoded `.system(size:)` calls outside CivicText** (12 call sites, 7 files):

| File | Line(s) | Size | Target |
|---|---|---|---|
| `App/ContentView.swift` | 43 | 56 | SF Symbol icon (decorative, AX-hidden) |
| `Features/Study/SessionSummaryView.swift` | 22 | 56 | SF Symbol icon (decorative) |
| `Shared/UI/Components.swift` | 210, 241 | 20, 13 | UI chrome |
| `Features/Settings/SettingsRow.swift` | 14 | 18 | section title |
| `Features/Configuration/TestConfigurationView.swift` | 67, 102, 134, 148 | 18 | section titles (×4) |
| `Features/Settings/SettingsView.swift` | 37, 78 | 13, 18 | titles |
| `Features/Settings/ConfigPreferencesSection.swift` | 24 | 13 | title |

**What scales today:** ~67 semantic `.font(.headline/.subheadline/.footnote/.caption/...)` call sites already reflow with Dynamic Type (`design-redesign-plan.md:85`). These are fine for scaling; they were deferred only for the *rounded-migration*, not for sizing.

## Affected Areas

- `SwiftyCitizen/App/SwiftyCitizenApp.swift` — the pin to remove/replace (root cause).
- `SwiftyCitizen/Shared/Theme/CivicText.swift` — design system; all 11 cases are fixed-size rounded (the broader, brand-locked concern).
- The 7 files above with direct `.system(size:)` calls.
- Inherited-font `Text`/`Label`/`Button` literals across every feature screen (Home, Practice, Progress, Settings, onboarding) — the population that the pin currently freezes.

## Approaches

1. **Surgical root-pin fix (recommended for 6.1)** — delete the `.environment(\.font, ...)` line (or replace it with a scaling semantic font such as `.body`).
   - Pros: minimal diff (~1 line), fixes the exact systemic cause named in the ticket, restores Dynamic Type for all inherited-font Text app-wide at once, lowest breakage risk, trivially testable.
   - Cons: does NOT change CivicText or the direct `.system(size:)` calls — those stay fixed by the brand lock. So design-system labels still won't scale until a separate fix.
   - Effort: Low.

2. **Broad refactor to semantic fonts** — replace every hardcoded size (CivicText + 12 call sites) with SwiftUI semantic styles (`.body`, `.headline`, …).
   - Pros: everything scales uniformly.
   - Cons: SF Pro Rounded has **no semantic equivalent in SwiftUI** — converting CivicText loses the locked brand rounded design, violating an explicit design constraint. ~13+ files touched, high breakage risk on fixed layouts, large review surface (>400-line budget). This is a brand decision, not a scope for 6.1.
   - Effort: High.

3. **Centralized Dynamic-Type-aware CivicText (the real systemic fix)** — make `CivicText` scale by deriving sizes from a reference Dynamic Type size (e.g. multiply base point by `currentSize / referenceSize`), keeping rounded design while reflowing. This is already tracked as task **B3** (`docs/plan/tasks.md:56`) and described in `Settings-Civic-Scholar/deferred-features.md:29` ("global relative scale factor … NOT an absolute point size").
   - Pros: resolves Home/Practice/Progress typography at once, keeps brand lock, centralized (one file).
   - Cons: needs a reference-size strategy and per-token scaling math; must be verified at `.accessibility5`; separate change from the root pin.
   - Effort: Medium.

## Recommendation

Scope **6.1 surgically**: remove/replace the root pin at `SwiftyCitizenApp.swift:45` so inherited-font Text reflows again. This is the systemic cause in the value-rebuild-plan and is a 1-line, low-risk change. Do NOT fold the CivicText refactor into 6.1 — that is brand-locked (SF Pro Rounded has no SwiftUI semantic equivalent) and already tracked as the separate, centralized **B3** task. Propose 6.1 as the root-pin fix; recommend B3 as the follow-up that makes `CivicText` Dynamic-Type-aware so design-system labels also reflow.

## Risks

- **Fixed layouts / icons:** the two `size: 56` sites are SF Symbol icons (decorative, `.accessibilityHidden(true)`), NOT text — leave them as `.system(size:)`. Do not convert icon sizing to semantic fonts.
- **CivicText still frozen after 6.1:** removing the root pin does not scale CivicText or the 12 direct calls; users on large accessibility sizes will still see fixed design-system labels until B3 lands. State this explicitly in the proposal so it is an accepted known limitation, not a regression claim.
- **No clipping guarantee for pinned titles:** the 13–18 pt section titles (SettingsRow, TestConfigurationView, SettingsView, ConfigPreferencesSection) are fixed; at `.accessibility5` they may wrap/clip. Containers should remain scrollable (they mostly are per `phase-0.5-design-spec.md`).
- **Accessibility coverage:** simulator `performAccessibilityAudit` is unreliable for Dynamic Type (`code-and-architecture-audit.md:33`, `tasks.md:56`); the on-device Dynamic Type review is deferred to hardware. Verify largest-size reflow with the `xcode27-accessibility` skill / Dynamic Type preview (`@Environment(\.dynamicTypeSize)`) but treat simulator as indicative only.
- **Scope creep:** converting CivicText risks violating the locked SF Pro Rounded constraint and blows past the 400-line review budget — keep it out of 6.1.

## Ready for Proposal

Yes. 6.1 is a small, well-scoped root-pin change. The proposal should (a) remove/replace the pin, (b) add a test/preview verifying inherited-font Text scales at an accessibility size, and (c) explicitly defer the CivicText scaling to B3 with the brand-lock rationale.
