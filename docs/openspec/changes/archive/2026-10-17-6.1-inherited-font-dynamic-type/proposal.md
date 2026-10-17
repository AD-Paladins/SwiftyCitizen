# Proposal: 6.1 — Remove root font pin, restore app-wide Dynamic Type for inherited fonts

## Intent

The app root pins an absolute font that freezes Dynamic Type scaling for every
inherited-font `Text`/`Label`/`Button`:

```swift
// SwiftyCitizen/App/SwiftyCitizenApp.swift:45
.environment(\.font, .system(size: 16, weight: .regular, design: .rounded))
```

This overrides the `\.font` environment value for the whole app subtree. Any view
that renders text through the *inherited* environment font — a plain `Text`,
`Label`, or `Button` with no explicit `.font()` modifier — is frozen at an
absolute **16 pt rounded** and does NOT scale with Dynamic Type. Views that apply
their own semantic font (`.body`, `.headline`, …) already scale and are unaffected.

This is the systemic cause flagged in `product-value-audit.md:148` and
`docs/plan/value-rebuild-plan.md:95` (task 6.1). Historical note: the root was
originally `.system(design: .rounded)` (no size → scaling); someone added
`size: 16`, which introduced the absolute freeze. Removing/replacing it restores
scaling for the entire inherited-font population at once.

## Scope

### In Scope
- Remove or replace the root font pin at `SwiftyCitizen/App/SwiftyCitizenApp.swift:45`
  with a scaling semantic font so inherited-font Text reflows app-wide.
- Add a Dynamic Type preview (and, if feasible in XCTest, a probe test) verifying
  that inherited-font `Text`/`Label`/`Button` scale at an accessibility size.
- Explicitly defer the `CivicText` scaling work to the separate centralized task
  **B3** (`docs/plan/tasks.md:56`) with the brand-lock rationale.

### Out of Scope
- Converting `CivicText` tokens (11 cases, `SwiftyCitizen/Shared/Theme/CivicText.swift`)
  to semantic fonts. SF Pro Rounded has **no SwiftUI semantic equivalent**; doing so
  loses the locked brand rounded design and violates an explicit design constraint.
  Tracked as B3.
- The 12 direct `.system(size:)` calls outside `CivicText` (7 files). The two
  `size: 56` sites are decorative, AX-hidden SF Symbol icons — leave them alone.
- Bundling an alternative font or touching `Info.plist` (brand-locked).

## Capabilities

> Contract between proposal and spec phases. The only existing spec is
> `persistence` (a pure-refactor delta with no parent main spec); this change adds
> a new user-facing behavior capability. There is no existing spec-level requirement
> to modify, so Modified Capabilities is "None".

### New Capabilities
- `inherited-font-dynamic-type`: inherited-font `Text`/`Label`/`Button` (views with
  no explicit `.font()`) SHALL reflow with Dynamic Type because the app-root font
  environment is a scaling semantic font, not an absolute frozen size.

### Modified Capabilities
- None. `CivicText` scaling is deferred to B3 and does not change any existing
  spec-level requirement.

## Approach

Recommended surgical fix — replace the pin with a scaling semantic font (one line):

```swift
.environment(\.font, .body)
```

Rationale: `.body` is an explicit, self-documenting, Dynamic-Type-aware base font,
so inherited fonts scale again while the intent (a single root base font) stays
clear. Deleting the line entirely is behaviorally equivalent (SwiftUI falls back to
its default scaling body font) and is an acceptable minimal alternative; `.body` is
preferred for clarity.

Tradeoff accepted: plain inherited-font literals lose the rounded look (SF Pro
Rounded → SF Pro body). Scaling wins over rounded for accessibility; the rounded
brand system lives in `CivicText`, which is deferred to B3, not silently converted here.

Verification:
- **Dynamic Type preview** (`#Preview`) in `SwiftyCitizenTests` rendering an
  inherited-font `Text`/`Label`/`Button` across accessibility sizes (e.g.
  `.dynamicTypeSize(.accessibilityLarge)` and up) — the primary reflow check,
  verified on device. Simulator is indicative only.
- **Automated guard**: strict_tdd suite green (proves nothing regressed). A focused
  probe test asserting the resolved inherited font is a scaling semantic font rather
  than the frozen absolute size is proposed; the exact assertion mechanism is a
  spec-phase decision, and if font-resolution introspection proves infeasible in
  XCTest the preview + suite-green remains the guard.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `SwiftyCitizen/App/SwiftyCitizenApp.swift:45` | Modified | Remove/replace root font pin with `.body` |
| `SwiftyCitizenTests/` (New file) | New | Dynamic Type preview + inherited-font scaling probe test |
| `SwiftyCitizen/Shared/Theme/CivicText.swift` | Unchanged (deferred) | All 11 cases stay fixed-size rounded; deferred to B3 |
| 7 files / 12 `.system(size:)` calls | Unchanged | Left alone (icons decorative; titles fixed by brand lock) |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `CivicText` + direct calls still frozen after 6.1 (accepted known limitation) | High (expected) | Explicitly deferred to B3 with brand-lock rationale; documented as a known limitation, not a regression claim |
| Fixed section titles (13–18 pt) wrap/clip at `.accessibility5` | Low-Med | Containers remain scrollable per `phase-0.5-design-spec.md`; not in scope to fix |
| Icon sites misread as text and converted | Low | The two `size: 56` sites are decorative, `.accessibilityHidden(true)` SF Symbols — explicitly left as `.system(size:)` |
| Simulator `performAccessibilityAudit` unreliable for Dynamic Type | High | On-device Dynamic Type review deferred to hardware (per audit); simulator indicative only |
| Scope creep into `CivicText` semantic conversion | Low | Explicit out-of-scope + B3 tracking; stays under 400-line review budget |

## Rollback Plan

Re-add the original line at `SwiftyCitizen/App/SwiftyCitizenApp.swift:45`:

```swift
.environment(\.font, .system(size: 16, weight: .regular, design: .rounded))
```

One-line revert; no schema, data, or other-file impact. The change is isolated to a
single environment modifier.

## Dependencies

- None external. Related deferred task **B3** (`docs/plan/tasks.md:56`, described in
  `Settings-Civic-Scholar/deferred-features.md:29`) makes `CivicText` Dynamic-Type-aware
  via a relative scale-from-reference-size approach — the follow-up that also reflows
  design-system labels.

## Success Criteria

- [ ] Root font pin removed/replaced with scaling semantic `.body` at `SwiftyCitizenApp.swift:45`
- [ ] Inherited-font `Text`/`Label`/`Button` reflow with Dynamic Type (verified via Dynamic Type preview on device)
- [ ] Full unit suite green under strict_tdd:
      `xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests`
- [ ] `CivicText` and the 12 direct `.system(size:)` calls unchanged; deferral to B3 documented
