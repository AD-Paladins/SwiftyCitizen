import SwiftUI

struct SettingsSectionTitle: View {
    let icon: String
    let title: LocalizedStringKey

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        HStack(alignment: .center, spacing: Space.sm.value) {
            Image(systemName: icon)
                .foregroundStyle(palette.primary)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(title)
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.dimmed)
        }
    }
}

struct SettingsKeyValueRow: View {
    let label: LocalizedStringKey
    let value: LocalizedStringKey

    @Environment(ThemeManager.self) private var themeManager
    private var palette: AppPalette { themeManager.palette }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.md.value) {
            Text(label)
                .font(CivicText.bodyMD.font)
                .foregroundStyle(palette.ink)
            Spacer(minLength: Space.sm.value)
            Text(value)
                .font(CivicText.labelMD.font)
                .foregroundStyle(palette.dimmed)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.lg.value)
            .cardStyle()
    }
}
