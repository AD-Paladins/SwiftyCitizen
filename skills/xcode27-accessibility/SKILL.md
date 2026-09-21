---
name: xcode27-accessibility
description: "Trigger: Xcode 27, Device Hub, accessibility test, simulator, VoiceOver, Dynamic Type, contrast. Remembers terminal/simulator commands and performAccessibilityAudit for this iOS project."
license: Apache-2.0
metadata:
  author: AD-Paladins
  version: "1.0"
---

## Activation Contract

Load before any build/test/simulator/device work in this repo, or when the user mentions Xcode 27, Device Hub, accessibility, VoiceOver, Dynamic Type, contrast, `simctl`, `devicectl`, `performAccessibilityAudit`, or "testar accesibilidad por terminal/simulador".

## Hard Rules

- VoiceOver is NOT reliable on simulator. A real iPhone is the source of truth; never assert a VoiceOver pass from the simulator alone.
- Contrast, Dynamic Type and appearance ARE scriptable on the simulator — prefer them over manual device checks when the category allows.
- Xcode 26.1/26.2 broke UI tests and Accessibility Inspector on iOS 26+ (simulator and device). This project targets Xcode 27; still run before trusting results.
- Automate where possible: add `XCUIApplication.performAccessibilityAudit()` to a UI test instead of eyeballing contrast or clipping.

## Decision Gates

| Need | Tool |
| --- | --- |
| Contrast / Dynamic Type / appearance | `xcrun simctl ui booted …` (live, no relaunch) |
| Automated screen audit | `XCUIApplication.performAccessibilityAudit()` in a UI test (simulator + device) |
| Physical-device / CI automation | `xcrun devicectl` |
| VoiceOver | Real iPhone only; simulator untrustworthy yet |

## Execution Steps

1. Pick the tool from the Decision Gates.
2. Read `references/commands.md` for exact commands and the test snippet.
3. Read `references/gotchas.md` before trusting a result.
4. Run the narrowest check, then report findings.

## Output Contract

Return which category each check fell into, the command/test used, pass/fail per screen, and any issue that needs a real-device follow-up (VoiceOver).

## References

- `references/commands.md` — terminal commands (`simctl`, `devicectl`) and the `performAccessibilityAudit()` test snippet.
- `references/gotchas.md` — VoiceOver caveats, Xcode 26.x breakage, Device Hub quirks.
