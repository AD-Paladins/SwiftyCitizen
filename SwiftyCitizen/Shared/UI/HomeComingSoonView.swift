import SwiftUI

/// Placeholder presented when a Quick Mode has no implementation yet. Both the Oral Simulator and
/// Listening Mode route here until their logic exists.
struct HomeComingSoonView: View {
    let systemImage: String

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    init(systemImage: String = "hourglass.tophalf.fill") {
        self.systemImage = systemImage
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Space.md.value) {
                Image(systemName: systemImage)
                    .font(CivicText.headlineLG.font)
                    .foregroundStyle(palette.primary)
                    .accessibilityHidden(true)
                Text("homeComingSoonTitle")
                    .font(CivicText.headlineMD.font)
                    .foregroundStyle(palette.ink)
                Text("homeComingSoonMessage")
                    .font(CivicText.bodyMD.font)
                    .foregroundStyle(palette.dimmed)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Space.xl.value)
            .navigationTitle("homeComingSoonTitle")
            .background(palette.canvas.ignoresSafeArea())
        }
    }
}

#Preview {
    NavigationStack {
        HomeComingSoonView(systemImage: "mic.fill")
    }
    .environment(ThemeManager())
}
