# Gotchas — Xcode 27 / Device Hub accessibility

## VoiceOver on simulator is not trustworthy

- Device Hub ships a "VoiceOver" toggle in the beta that reports doing nothing.
- New XCTest API to drive VoiceOver from a Mac (WWDC26 8005) works in Simulator seed 1 but is buggy in the betas.
- macOS VoiceOver can drive the iOS app on the simulator, but macOS navigation is hierarchical and differs from iOS — not a source of truth.
- **Real iPhone is required to confirm VoiceOver.** Do not claim a VoiceOver pass from simulator alone.

## Xcode 26.x broke UI tests + Accessibility Inspector on iOS 26+

- Xcode 26.1 (#1209) and 26.2 (#1246/#1247) made almost all UI tests fail and the Accessibility Inspector unable to read the hierarchy, on both simulator and device for iOS 26+.
- Workaround that was used: run on iOS < 26 or pin Xcode 26.0.
- This project targets **Xcode 27**. Assume fixed, but still run before trusting results — betas shift.

## Device Hub quirks (Xcode 27)

- Quitting Device Hub does not always kill CoreSimulator processes; use right-click → "Shut Down" on a device to reclaim memory.
- `killall -9 Simulator` kills nothing on Xcode 27 (the app was renamed).
- Some features moved or are missing vs the old Simulator app (e.g. memory-warning trigger, file drag-and-drop). Fall back to `simctl`/`devicectl` for those.

## Read-only accessibility environment values

- `colorSchemeContrast`, `accessibilityReduceMotion`, `accessibilityReduceTransparency`, `accessibilityDifferentiateWithoutColor` are read-only in SwiftUI; `.environment(...)` calls compile but are silently ignored at runtime. Drive them through the simulator/device setting, not `.environment()`.

## Contrast ratio reference

- Body text: 4.5:1 minimum. Large text: 3:1. Use the Accessibility Inspector Color Contrast Calculator to check pairs.
