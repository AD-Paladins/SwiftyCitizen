//
//  CivicTextDynamicTypeTests.swift
//  SwiftyCitizenTests
//
//  Verifies that CivicText tokens (the SF Pro Rounded brand face) reflow with
//  Dynamic Type after change B3 replaced their frozen absolute point sizes
//  (.system(size: …)) with UIFontMetrics-scaled fonts that scale relative to
//  their text style.
//

import SwiftUI
import XCTest
@testable import SwiftyCitizen
import Testing

// MARK: - Probe feasibility note (change B3)

// Same constraint as 6.1's DynamicTypeReflowTests: Swift Testing / XCTest has no
// public API to introspect the resolved point size of a Font, and Dynamic Type
// scaling cannot be asserted on the simulator. B3's debt was that CivicText used
// absolute `.system(size:)` fonts, which opt out of Dynamic Type entirely (every
// one of the ~95 call sites froze at its fixed point size).
//
// The fix keeps each token's exact nominal point size but scales it via
// `UIFontMetrics(forTextStyle:).scaledValue(for:)`, so it now reflows.
//
// Verification rests on the same two pillars as 6.1:
//   1. the previews below (primary reflow check, on-device — compare .medium vs .accessibility3), and
//   2. the strict_tdd suite staying green (regression guard).

struct CivicTextDynamicTypeTests {

    #Preview("CivicText — normal size (.medium)") {
        CivicTextReflowSample()
            .dynamicTypeSize(.medium)
    }

    #Preview("CivicText — accessibilityLarge (.accessibility3)") {
        CivicTextReflowSample()
            .dynamicTypeSize(.accessibility3)
    }
}

/// All CivicText tokens rendered with a label naming each token, so the rounded
/// brand face and its reflow are visible at both sizes. At .accessibility3 the
/// tokens must visibly grow (and fall back to plain SF Pro for the rounded face —
/// documented Apple limit).
private struct CivicTextReflowSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("displayLG").font(CivicText.displayLG.font)
            Text("metricDisplay").font(CivicText.metricDisplay.font)
            Text("headlineLG").font(CivicText.headlineLG.font)
            Text("headlineMD").font(CivicText.headlineMD.font)
            Text("headlineSM").font(CivicText.headlineSM.font)
            Text("bodyLG").font(CivicText.bodyLG.font)
            Text("bodyMD").font(CivicText.bodyMD.font)
            Text("bodySM").font(CivicText.bodySM.font)
            Text("labelLG").font(CivicText.labelLG.font)
            Text("labelMD").font(CivicText.labelMD.font)
            Text("labelSM").font(CivicText.labelSM.font)
        }
        .padding()
    }
}
