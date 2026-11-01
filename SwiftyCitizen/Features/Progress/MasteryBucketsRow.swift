import SwiftUI

/// The "Diagnostic Mirror" mastery row: three equal cards — Graduated / In Review / Needs Care.
/// Each card shows a large count, the localized bucket label, and its meaning. Self-contained and
/// reusable: it receives the three counts as data and owns its own theme + typography.
struct MasteryBucketsRow: View {
    let graduated: Int
    let inReview: Int
    let needsCare: Int

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        HStack(spacing: Space.sm.value) {
            bucketCell(
                count: graduated,
                label: "progressBucketGraduated",
                meaning: "progressBucketGraduatedMeaning",
                tint: palette.success
            )
            bucketCell(
                count: inReview,
                label: "progressBucketInReview",
                meaning: "progressBucketInReviewMeaning",
                tint: palette.warning
            )
            bucketCell(
                count: needsCare,
                label: "progressBucketNeedsCare",
                meaning: "progressBucketNeedsCareMeaning",
                tint: palette.danger
            )
        }
    }

    /// One mastery card: a tinted count, the bucket label, and its meaning. Shared so all three
    /// buckets stay pixel-identical; the tint is the only per-bucket variable.
    private func bucketCell(count: Int, label: LocalizedStringKey, meaning: LocalizedStringKey, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Space.xs.value) {
            Text("\(count)")
                .font(CivicText.headlineLG.font)
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(CivicText.labelSM.font.weight(.semibold))
                .foregroundStyle(palette.ink)
            Text(meaning)
                .font(CivicText.bodySM.font)
                .foregroundStyle(palette.dimmed)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Space.md.value)
        .cardStyle()
    }
}

#Preview {
    MasteryBucketsRow(graduated: 42, inReview: 11, needsCare: 7)
        .environment(ThemeManager())
        .padding(Space.md.value)
}
