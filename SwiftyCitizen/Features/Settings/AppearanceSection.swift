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
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSection()
    }
    .environment(ThemeManager())
}
