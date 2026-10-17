//
//  DynamicTypeReflowTests.swift
//  SwiftyCitizenTests
//
//  Verifies that inherited-font text (Text/Label/Button with no explicit `.font()`)
//  reflows with Dynamic Type after change 6.1 replaced the frozen root font pin
//  (`SwiftyCitizenApp.swift:45`) with a scaling semantic font (`.body`).
//

import SwiftUI
import Testing

// MARK: - Probe feasibility note (change 6.1, task 1.3 / 1.5)

// The spec offered a focused probe test asserting that the *resolved* inherited
// font is a scaling semantic font rather than the frozen absolute size. That probe
// is OMITTED on purpose: XCTest / Swift Testing has no public API to introspect the
// resolved SwiftUI environment font of a running hierarchy, nor to distinguish a
// scaling semantic `Font` from an absolute `.system(size:)`. Dynamic Type scaling
// cannot be asserted on the simulator either. Per spec scenario "Probe infeasibility
// falls back to preview + suite green", verification rests on:
//   1. the Dynamic Type previews below (primary reflow check, on-device), and
//   2. the strict_tdd suite staying green (regression guard).

struct DynamicTypeReflowTests {

    // NOTE: the spec/tasks referenced `.dynamicTypeSize(.default)` and
    // `.accessibilityLarge`, which are not real `DynamicTypeSize` members. The
    // actual API exposes `.small`, `.medium`, `.large`, and `.accessibility1`…
    // `.accessibility5`. Using `.medium` (normal) vs `.accessibility3` (visibly
    // large) for the on-device reflow contrast.
    #Preview("Inherited font — normal size") {
        InheritedFontReflowSample()
            .dynamicTypeSize(.medium)
    }

    #Preview("Inherited font — accessibilityLarge") {
        InheritedFontReflowSample()
            .dynamicTypeSize(.accessibility3)
    }
}

/// Text, Label, and Button with NO explicit `.font()` modifier, so each renders
/// through the inherited environment font. At `.accessibilityLarge` the content
/// must visibly increase in point size and reflow to fit the larger line height.
private struct InheritedFontReflowSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The Constitution protects your rights.")
            Label("File your application online", systemImage: "doc.badge.plus")
            Button("Get Started") {}
        }
        .padding()
    }
}
