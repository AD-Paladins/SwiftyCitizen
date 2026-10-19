import SwiftUI
import Observation

@MainActor
@Observable
final class ThemeManager {
    var themeName: AppThemeName {
        didSet { UserDefaults.standard.set(themeName.rawValue, forKey: Self.storageKey) }
    }

    var palette: AppPalette { themeName.palette }

    private static let storageKey = "appThemeName"

    init() {
        let rawValue = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppThemeName.civicNavy.rawValue
        self.themeName = AppThemeName(rawValue: rawValue) ?? .civicNavy
    }
}

enum AppThemeName: String, CaseIterable, Identifiable {
    case civicNavy
    case paperEmerald
    case studyCalm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .civicNavy:
            "Civic Navy"
        case .paperEmerald:
            "Paper & Emerald"
        case .studyCalm:
            "Study Calm"
        }
    }

    var palette: AppPalette {
        switch self {
        case .civicNavy:
            .civicNavy
        case .paperEmerald:
            .paperEmerald
        case .studyCalm:
            .studyCalm
        }
    }
}

struct AppPalette {
    let ink: Color
    let primary: Color
    let heroBottom: Color
    let canvas: Color
    let surface: Color
    let success: Color
    let warning: Color
    let danger: Color
    let onPrimary: Color
    let dimmed: Color

    // MARK: - Derived container family (added by the theme audit)

    /// Precomputed light/dark RGB for every derived role. Kept as raw RGB (not `Color`) so the
    /// derivation lives in exactly one place (`ThemeTones`) and the SwiftUI conversion happens here.
    let derived: DerivedPalette

    /// Material-3-style emphasized fills and their readable labels, derived from seed hues. These
    /// back chips/badges/pills (e.g. the topic-coverage carousel). See `ThemeTones` for the model.
    // Flat saturated accents — back the topic badges (white initials).
    var secondary: Color { color(derived.secondary) }
    var onSecondary: Color { color(derived.onSecondary) }
    var tertiary: Color { color(derived.tertiary) }
    var onTertiary: Color { color(derived.onTertiary) }

    var primaryContainer: Color { color(derived.primaryContainer) }
    var onPrimaryContainer: Color { color(derived.onPrimaryContainer) }
    var secondaryContainer: Color { color(derived.secondaryContainer) }
    var onSecondaryContainer: Color { color(derived.onSecondaryContainer) }
    var tertiaryContainer: Color { color(derived.tertiaryContainer) }
    var onTertiaryContainer: Color { color(derived.onTertiaryContainer) }
    var errorContainer: Color { color(derived.errorContainer) }
    var onErrorContainer: Color { color(derived.onErrorContainer) }

    /// Extra neutral + border roles. `surfaceVariant` sits just above `surface`; `outline` /
    /// `outlineVariant` are the two border weights the app uses for cards and selections.
    var surfaceVariant: Color { color(derived.surfaceVariant) }
    var outline: Color { color(derived.outline) }
    var outlineVariant: Color { color(derived.outlineVariant) }

    func tint(for assessment: SelfAssessment) -> Color {
        switch assessment {
        case .again:
            danger
        case .hard:
            warning
        case .gotIt:
            success
        }
    }
}

extension AppPalette {
    static let civicNavy = AppPalette(
        ink: dynamic(light: 0.10, green: 0.14, blue: 0.20, dark: 0.91, darkGreen: 0.93, darkBlue: 0.95),
        primary: dynamic(light: 0.17, green: 0.30, blue: 0.49, dark: 0.42, darkGreen: 0.58, darkBlue: 0.75),
        heroBottom: dynamic(light: 0.07, green: 0.14, blue: 0.22, dark: 0.22, darkGreen: 0.36, darkBlue: 0.54),
        canvas: dynamic(light: 0.93, green: 0.94, blue: 0.96, dark: 0.07, darkGreen: 0.09, darkBlue: 0.12),
        surface: dynamic(light: 1.00, green: 1.00, blue: 1.00, dark: 0.13, darkGreen: 0.15, darkBlue: 0.19),
        success: dynamic(light: 0.18, green: 0.49, blue: 0.36, dark: 0.31, darkGreen: 0.69, darkBlue: 0.51),
        warning: dynamic(light: 0.73, green: 0.48, blue: 0.16, dark: 0.91, darkGreen: 0.63, darkBlue: 0.31),
        danger: dynamic(light: 0.66, green: 0.29, blue: 0.23, dark: 0.85, darkGreen: 0.48, darkBlue: 0.42),
        onPrimary: Color.white,
        dimmed: dynamic(light: 0.30, green: 0.30, blue: 0.30, dark: 0.70, darkGreen: 0.70, darkBlue: 0.70),
        derived: PaletteDerivation(
            seeds: .init(
                primary: rgb(0.17, 0.30, 0.49),   // navy
                secondary: rgb(0.34, 0.44, 0.56),  // muted slate-blue
                tertiary: rgb(0.10, 0.48, 0.52),   // teal
                error: rgb(0.66, 0.29, 0.23)       // shares the legacy `danger` seed
            ),
            neutrals: .init(
                backgroundLight: rgb(0.93, 0.94, 0.96),
                backgroundDark: rgb(0.07, 0.09, 0.12),
                surfaceLight: rgb(1.00, 1.00, 1.00),
                surfaceDark: rgb(0.13, 0.15, 0.19),
                textDark: rgb(0.10, 0.14, 0.20),
                textLight: rgb(0.91, 0.93, 0.95)
            )
        ).roles
    )

    static let paperEmerald = AppPalette(
        ink: dynamic(light: 0.10, green: 0.11, blue: 0.10, dark: 0.93, darkGreen: 0.91, darkBlue: 0.89),
        primary: dynamic(light: 0.04, green: 0.43, blue: 0.31, dark: 0.30, darkGreen: 0.73, darkBlue: 0.60),
        heroBottom: dynamic(light: 0.02, green: 0.16, blue: 0.12, dark: 0.16, darkGreen: 0.42, darkBlue: 0.31),
        canvas: dynamic(light: 0.99, green: 0.98, blue: 0.94, dark: 0.09, darkGreen: 0.08, darkBlue: 0.07),
        surface: dynamic(light: 1.00, green: 1.00, blue: 1.00, dark: 0.15, darkGreen: 0.14, darkBlue: 0.13),
        success: dynamic(light: 0.13, green: 0.77, blue: 0.37, dark: 0.30, darkGreen: 0.73, darkBlue: 0.60),
        warning: dynamic(light: 0.88, green: 0.53, blue: 0.08, dark: 0.91, darkGreen: 0.63, darkBlue: 0.31),
        danger: dynamic(light: 0.94, green: 0.27, blue: 0.27, dark: 0.85, darkGreen: 0.48, darkBlue: 0.42),
        onPrimary: Color.white,
        dimmed: dynamic(light: 0.22, green: 0.24, blue: 0.22, dark: 0.70, darkGreen: 0.70, darkBlue: 0.70),
        derived: PaletteDerivation(
            seeds: .init(
                primary: rgb(0.04, 0.43, 0.31),   // emerald
                secondary: rgb(0.90, 0.60, 0.15),  // amber
                tertiary: rgb(0.02, 0.42, 0.18),   // deep green
                error: rgb(0.94, 0.27, 0.27)       // shares the legacy `danger` seed
            ),
            neutrals: .init(
                backgroundLight: rgb(0.99, 0.98, 0.94),
                backgroundDark: rgb(0.09, 0.08, 0.07),
                surfaceLight: rgb(1.00, 1.00, 1.00),
                surfaceDark: rgb(0.15, 0.14, 0.13),
                textDark: rgb(0.10, 0.11, 0.10),
                textLight: rgb(0.93, 0.91, 0.89)
            )
        ).roles
    )

    static let studyCalm = AppPalette(
        ink: dynamic(light: 0.18, green: 0.20, blue: 0.27, dark: 0.89, darkGreen: 0.90, darkBlue: 0.93),
        primary: dynamic(light: 0.18, green: 0.20, blue: 0.27, dark: 0.60, darkGreen: 0.63, darkBlue: 0.75),
        heroBottom: dynamic(light: 0.08, green: 0.10, blue: 0.15, dark: 0.23, darkGreen: 0.26, darkBlue: 0.33),
        canvas: dynamic(light: 0.93, green: 0.93, blue: 0.94, dark: 0.08, darkGreen: 0.09, darkBlue: 0.11),
        surface: dynamic(light: 1.00, green: 1.00, blue: 1.00, dark: 0.14, darkGreen: 0.15, darkBlue: 0.17),
        success: dynamic(light: 0.18, green: 0.49, blue: 0.36, dark: 0.31, darkGreen: 0.69, darkBlue: 0.51),
        warning: dynamic(light: 0.73, green: 0.48, blue: 0.16, dark: 0.91, darkGreen: 0.63, darkBlue: 0.31),
        danger: dynamic(light: 0.66, green: 0.29, blue: 0.23, dark: 0.85, darkGreen: 0.48, darkBlue: 0.42),
        onPrimary: Color.white,
        dimmed: dynamic(light: 0.30, green: 0.30, blue: 0.30, dark: 0.70, darkGreen: 0.70, darkBlue: 0.70),
        derived: PaletteDerivation(
            seeds: .init(
                primary: rgb(0.18, 0.20, 0.27),   // slate
                secondary: rgb(0.74, 0.63, 0.44),  // warm amber-gray
                tertiary: rgb(0.30, 0.44, 0.38),   // muted sage
                error: rgb(0.66, 0.29, 0.23)       // shares the legacy `danger` seed
            ),
            neutrals: .init(
                backgroundLight: rgb(0.93, 0.93, 0.94),
                backgroundDark: rgb(0.08, 0.09, 0.11),
                surfaceLight: rgb(1.00, 1.00, 1.00),
                surfaceDark: rgb(0.14, 0.15, 0.17),
                textDark: rgb(0.18, 0.20, 0.27),
                textLight: rgb(0.89, 0.90, 0.93)
            )
        ).roles
    )

    private static func dynamic(
        light red: Double,
        green: Double,
        blue: Double,
        dark darkRed: Double,
        darkGreen: Double,
        darkBlue: Double
    ) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: darkRed, green: darkGreen, blue: darkBlue, alpha: 1)
                : UIColor(red: red, green: green, blue: blue, alpha: 1)
        })
    }

    /// Builds a light-mode `RGBColor` seed/anchor. Lives here (not in `ThemeTones`) so that file
    /// stays free of UIKit and the derivation math stays pure + unit-testable.
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> RGBColor {
        RGBColor(r: r, g: g, b: b)
    }

    /// Converts a derived light/dark `RGBColor` pair into the same style-switching `Color` the rest
    /// of the palette uses, so derived tokens behave identically to the hand-tuned ones.
    private func color(_ role: RoleColors) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? rgbColorToUIColor(role.dark)
                : rgbColorToUIColor(role.light)
        })
    }

    private func rgbColorToUIColor(_ c: RGBColor) -> UIColor {
        UIColor(red: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: 1)
    }
}