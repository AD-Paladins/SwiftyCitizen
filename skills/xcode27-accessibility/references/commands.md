# Commands — Xcode 27 / Device Hub accessibility (SwiftyCitizen)

Device Hub (Xcode 27) replaces `Simulator.app`. It is a GUI front-end over the CLI tools below; every GUI action has a scriptable counterpart.

## simctl (simulator only)

Apply settings live, no relaunch needed:

```bash
# Contrast — "Aumentar contraste"
xcrun simctl ui booted increase_contrast enabled
xcrun simctl ui booted increase_contrast disabled

# Dynamic Type size (extra-large .. extra-extra-extra-large)
xcrun simctl ui booted content_size extra-large

# Appearance
xcrun simctl ui booted appearance dark
xcrun simctl ui booted appearance light

# Screenshot after applying (compare visually)
xcrun simctl io booted screenshot contrast.png
```

Reduce Transparency / Reduce Motion write to the Accessibility plist and need a relaunch:

```bash
UDID=<booted-sim>
xcrun simctl spawn "$UDID" defaults write com.apple.Accessibility ReduceTransparencyEnabled -bool true
# then relaunch the app
```

## devicectl (physical devices + CI)

Built on the same core as Device Hub. List, install, change settings, capture diagnostics:

```bash
xcrun devicectl device list --json-output
xcrun devicectl device info --id <udid>
xcrun devicectl device apps launch --id <udid> --bundle-id com.example.App
xcrun devicectl device settings appearance set --mode dark --id <udid>
```

Before baking commands into CI, run `xcrun devicectl --help` on the Xcode actually in use; nouns shift between betas.

## performAccessibilityAudit() — automated screen audit

Available iOS 17+ / Xcode 15+. Runs the same checks as Accessibility Inspector inside a UI test. Auto-fails on findings, no assertions needed. Runs on simulator AND device.

```swift
final class AccessibilityAuditTests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = true
  }

  func testHomeScreen() throws {
    let app = XCUIApplication()
    app.launch()
    try app.performAccessibilityAudit()          // default: all categories
  }

  func testRecoveryScreen() throws {
    let app = XCUIApplication()
    app.launch()
    app.tables.buttons["Recovery"].tap()
    try app.performAccessibilityAudit(for: [.dynamicType, .contrast, .textClipped, .hitRegion]) { issue in
      // return true to ignore a known/accepted finding, false to report it
      false
    }
  }
}
```

Categories: `.contrast`, `.elementDetection`, `.hitRegion`, `.sufficientElementDescription`, `.dynamicType`, `.textClipped`, `.trait`.

One audit per distinct screen/state (the audit only sees the current screen). Navigate first, then audit. Never disable a whole audit type to reach green — filter accepted issues individually in the handler with a comment on why.
