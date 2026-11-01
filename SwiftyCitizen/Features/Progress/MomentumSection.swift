import SwiftUI

/// The "Study momentum" card: a single line showing the current study streak. Self-contained and
/// reusable — it receives only the streak count and owns its own theme + typography.
struct MomentumSection: View {
    let streak: Int

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        HStack(spacing: Space.md.value) {
            VStack(alignment: .leading, spacing: Space.xs.value) {
                Text("progressMomentumStreak")
                    .font(CivicText.labelMD.font)
                    .foregroundStyle(palette.dimmed)
                Text("\(streak)")
                    .font(CivicText.headlineLG.font)
                    .foregroundStyle(palette.ink)
                    .monospacedDigit()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.lg.value)
        .cardStyle()
    }
}

#Preview {
    MomentumSection(streak: 12)
        .environment(ThemeManager())
        .padding(Space.md.value)
}
