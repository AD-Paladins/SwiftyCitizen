import SwiftUI

struct AppearanceSection: View {
    @Environment(ThemeManager.self) private var themeManager

    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        @Bindable var themeManager = themeManager

        SettingsCard {
            VStack(alignment: .leading, spacing: Space.lg.value) {
                Picker("settingsTheme", selection: $themeManager.themeName) {
                    ForEach(AppThemeName.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }

                ThemePaletteRow(palette: palette)

                SettingsKeyValueRow(label: "settingsCardTextSizing", value: "settingsCardTextSizingValue")

                SettingsKeyValueRow(label: "settingsStreakShield", value: "settingsStreakShieldValue")
            }
        }
    }
}

struct ThemePaletteRow: View {
    let palette: AppPalette

    var body: some View {
        HStack(alignment: .center, spacing: Space.md.value) {
            Text("settingsThemePalette")
                .font(CivicText.bodyMD.font)
                .foregroundStyle(.primary)

            Spacer(minLength: Space.sm.value)

            Circle()
                .fill(palette.primary)
                .frame(width: 24, height: 24)
                .accessibilityLabel(String(localized: "settingsThemePaletteSwatch"))

            Text("settingsArchiveTag")
                .font(CivicText.labelSM.font)
                .fontWeight(.bold)
                .foregroundStyle(palette.primary)
                .padding(.horizontal, Space.md.value)
                .padding(.vertical, Space.xs.value)
                .background(palette.primary.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        AppearanceSection()
    }
    .environment(ThemeManager())
}
