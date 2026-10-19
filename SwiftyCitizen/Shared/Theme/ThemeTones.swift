import Foundation

/// A 0...1 RGB triple. Pure value type (no SwiftUI / UIKit) so every color relationship is
/// unit-testable in isolation. All palette math lives here; the SwiftUI `Color` conversion happens
/// one step removed in `AppTheme`.
struct RGBColor: Equatable {
    var r: Double
    var g: Double
    var b: Double

    /// Linear interpolation between two colors. `t = 0` returns `a`, `t = 1` returns `b`, and any
    /// value outside `0...1` is clamped so callers never produce an out-of-range channel.
    static func lerp(_ a: RGBColor, _ b: RGBColor, _ t: Double) -> RGBColor {
        let t = min(max(t, 0), 1)
        return RGBColor(
            r: a.r + (b.r - a.r) * t,
            g: a.g + (b.g - a.g) * t,
            b: a.b + (b.b - a.b) * t
        )
    }

    /// Perceptual-ish average of two colors. Used to tint neutrals with a hint of the theme hue.
    static func mix(_ a: RGBColor, _ b: RGBColor, _ t: Double) -> RGBColor {
        lerp(a, b, t)
    }

    /// Relative luminance (ITU-R BT.601, sRGB gamma-corrected). Only used to assert contrast
    /// relationships in tests and to sanity-check a derived color at runtime.
    var luminance: Double {
        // Gamma-expand each channel, then weight by the standard luma coefficients.
        func expand(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * expand(r) + 0.7152 * expand(g) + 0.0722 * expand(b)
    }

    /// Contrast ratio (WCAG) between this color and `other`. `21.0` is black-on-white; `4.5` is
    /// the minimum for readable body text. Exposed so tests can assert contrast contracts.
    func contrastRatio(to other: RGBColor) -> Double {
        let a = luminance
        let b = other.luminance
        let lighter = max(a, b)
        let darker = min(a, b)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// A semantic color role expressed as its light-mode and dark-mode RGB. The SwiftUI `Color` that
/// switches between them is built in `AppTheme`, keeping this file free of UI frameworks.
struct RoleColors: Equatable {
    let light: RGBColor
    let dark: RGBColor
}

/// The complete Material-3-style color family derived from seed colors. Every entry is a
/// `RoleColors` pair (light + dark). Tokens the app already owns (`primary`, `ink`, `surface`, …)
/// are intentionally absent — this covers only the roles added by the theme audit.
///
/// Two flavors exist per family:
/// - **Flat accent** (`secondary`/`tertiary`): the saturated seed itself, used for filled badges.
/// - **Container** (`*Container`): a soft, desaturated fill with a readable `on-*` label, used for
///   pills and (future) ghost/outlined surfaces.
struct DerivedPalette: Equatable {
    // Flat accents (saturated seeds) — back the topic badges with white initials.
    let secondary: RoleColors
    let onSecondary: RoleColors
    let tertiary: RoleColors
    let onTertiary: RoleColors

    // Soft container family.
    let primaryContainer: RoleColors
    let onPrimaryContainer: RoleColors
    let secondaryContainer: RoleColors
    let onSecondaryContainer: RoleColors
    let tertiaryContainer: RoleColors
    let onTertiaryContainer: RoleColors
    let errorContainer: RoleColors
    let onErrorContainer: RoleColors

    // Neutrals + borders.
    let surfaceVariant: RoleColors
    let outline: RoleColors
    let outlineVariant: RoleColors
}

/// Derives a `DerivedPalette` from seed colors and neutral anchors. Pure + deterministic: the same
/// seeds always yield the same colors, so it is unit-tested once and safe to extend with new
/// themes — adding a theme means adding seeds and anchors, not hand-tuning ~30 hex values.
///
/// Derivation model (all blends are `lerp(seed or anchor, target, t)`):
/// - **Container** = seed pulled toward the mode background: light → toward near-white (soft fill),
///   dark → toward near-black (raised dark surface). Keeps containers visually anchored to the bg.
/// - **On-container** = seed pulled toward readable text: dark text on a light container, light
///   text on a dark container. A small seed hint keeps it tonal instead of flat gray.
/// - **Neutrals** (surfaceVariant / outline / outlineVariant) derive from the existing surface and
///   canvas anchors with fixed ratios, so new borders always harmonize with the tuned neutrals.
struct PaletteDerivation {
    /// Seed hues for the four emphasized families. Seeds are light-mode RGBs (the same space the
    /// existing `primary`/`danger` tokens already live in).
    struct Seeds: Equatable {
        let primary: RGBColor
        let secondary: RGBColor
        let tertiary: RGBColor
        let error: RGBColor
    }

    /// Neutral anchors reused from the tuned neutrals. Text anchors double as the readable-contrast
    /// target for on-container roles.
    struct Neutrals: Equatable {
        let backgroundLight: RGBColor   // canvas, light mode
        let backgroundDark: RGBColor    // canvas, dark mode
        let surfaceLight: RGBColor      // surface, light mode
        let surfaceDark: RGBColor       // surface, dark mode
        let textDark: RGBColor          // ink, light mode (readable text on a light surface)
        let textLight: RGBColor         // ink, dark mode (readable text on a dark surface)
    }

    let seeds: Seeds
    let neutrals: Neutrals

    // Tuning constants. Each is documented with the role it feeds so a future change is intentional
    // rather than a guess. Contrast targets are WCAG: >=4.5 for readable labels.
    private struct K {
        // Flat accent = the saturated seed. In dark mode it is pulled slightly toward dark ink so
        // the white initials stay >=4.5:1 (a lightened accent would wash out against white text).
        // `onFlat` pulls toward readable text for a tonal (not gray) label.
        static let flatDarkT = 0.30         // accent dark: darken toward ink for white-text contrast
        static let onFlatLightT = 0.78      // on-accent light: darken toward readable text
        static let onFlatDarkT = 0.72       // on-accent dark: lighten toward readable text
        // Container = seed pulled toward the mode background. containerDarkT is high enough that even
        // bright seeds (amber) yield a dark-ish surface, so light on-container text stays >=4.5:1.
        static let containerLightT = 0.72   // light: mostly background → soft, desaturated fill
        static let containerDarkT = 0.50    // dark: pull toward black for contrast
        static let onContainerLightT = 0.88 // light: mostly dark text → dark, tonal label
        static let onContainerDarkT = 0.82  // dark: mostly light text → light, tonal label
        // Neutrals derive from the tuned surface/canvas anchors. outline is the stronger weight
        // (selected states); outlineVariant is subtler (cards), close to the surface.
        static let surfaceVariantLightT = 0.30
        // Lift the dark surfaceVariant clearly above the near-black surface so it reads as a raised
        // tile, but keep it <= ~0.168 so on-surface (ink) text still clears WCAG AA (>=4.5:1).
        static let surfaceVariantDarkT = 0.24
        static let outlineLightT = 0.45
        static let outlineDarkT = 0.25
        static let outlineVariantLightT = 0.15
        static let outlineVariantDarkT = 0.08
    }

    var roles: DerivedPalette {
        DerivedPalette(
            secondary: flat(seeds.secondary),
            onSecondary: onFlat(seeds.secondary),
            tertiary: flat(seeds.tertiary),
            onTertiary: onFlat(seeds.tertiary),
            primaryContainer: container(seeds.primary),
            onPrimaryContainer: onContainer(seeds.primary),
            secondaryContainer: container(seeds.secondary),
            onSecondaryContainer: onContainer(seeds.secondary),
            tertiaryContainer: container(seeds.tertiary),
            onTertiaryContainer: onContainer(seeds.tertiary),
            errorContainer: container(seeds.error),
            onErrorContainer: onContainer(seeds.error),
            surfaceVariant: surfaceVariant(),
            outline: outline(K.outlineLightT, K.outlineDarkT),
            outlineVariant: outline(K.outlineVariantLightT, K.outlineVariantDarkT)
        )
    }

    // MARK: - Derivation helpers

    private func flat(_ seed: RGBColor) -> RoleColors {
        RoleColors(
            light: seed,
            dark: RGBColor.lerp(seed, neutrals.textDark, K.flatDarkT)
        )
    }

    private func onFlat(_ seed: RGBColor) -> RoleColors {
        RoleColors(
            light: RGBColor.lerp(seed, neutrals.textDark, K.onFlatLightT),
            dark: RGBColor.lerp(seed, neutrals.textLight, K.onFlatDarkT)
        )
    }

    private func container(_ seed: RGBColor) -> RoleColors {
        RoleColors(
            light: RGBColor.lerp(seed, neutrals.backgroundLight, K.containerLightT),
            dark: RGBColor.lerp(seed, neutrals.backgroundDark, K.containerDarkT)
        )
    }

    private func onContainer(_ seed: RGBColor) -> RoleColors {
        RoleColors(
            light: RGBColor.lerp(seed, neutrals.textDark, K.onContainerLightT),
            dark: RGBColor.lerp(seed, neutrals.textLight, K.onContainerDarkT)
        )
    }

    private func surfaceVariant() -> RoleColors {
        RoleColors(
            light: RGBColor.lerp(neutrals.surfaceLight, neutrals.backgroundLight, K.surfaceVariantLightT),
            dark: RGBColor.lerp(neutrals.surfaceDark, neutrals.textLight, K.surfaceVariantDarkT)
        )
    }

    private func outline(_ lightT: Double, _ darkT: Double) -> RoleColors {
        RoleColors(
            light: RGBColor.lerp(neutrals.surfaceLight, neutrals.textDark, lightT),
            dark: RGBColor.lerp(neutrals.surfaceDark, neutrals.textLight, darkT)
        )
    }
}
