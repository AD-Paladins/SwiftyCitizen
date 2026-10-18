//
//  ThemeTonesTests.swift
//  SwiftyCitizenTests
//

import Testing
import Foundation
@testable import SwiftyCitizen

/// Unit tests for the pure color derivation in `ThemeTones`. These lock the readability contracts
/// (WCAG AA contrast) and determinism so the derived family can be extended with new themes without
/// hand-checking every hex. They exercise `PaletteDerivation` directly — no SwiftUI/UIKit involved.
struct ThemeTonesTests {

    // paperEmerald: amber secondary is the tightest contrast case (its bright seed keeps the dark
    // container relatively light). Seeds/neutrals mirror AppTheme.paperEmerald exactly.
    private func paperEmerald() -> PaletteDerivation {
        PaletteDerivation(
            seeds: .init(
                primary: RGBColor(r: 0.04, g: 0.43, b: 0.31),
                secondary: RGBColor(r: 0.90, g: 0.60, b: 0.15),
                tertiary: RGBColor(r: 0.02, g: 0.42, b: 0.18),
                error: RGBColor(r: 0.94, g: 0.27, b: 0.27)
            ),
            neutrals: .init(
                backgroundLight: RGBColor(r: 0.99, g: 0.98, b: 0.94),
                backgroundDark: RGBColor(r: 0.09, g: 0.08, b: 0.07),
                surfaceLight: RGBColor(r: 1.00, g: 1.00, b: 1.00),
                surfaceDark: RGBColor(r: 0.15, g: 0.14, b: 0.13),
                textDark: RGBColor(r: 0.10, g: 0.11, b: 0.10),
                textLight: RGBColor(r: 0.93, g: 0.91, b: 0.89)
            )
        )
    }

    private let emeraldSeed = RGBColor(r: 0.04, g: 0.43, b: 0.31)

    // MARK: - Determinism

    @Test
    func sameSeedsYieldIdenticalPalette() {
        #expect(paperEmerald().roles == paperEmerald().roles)
    }

    @Test
    func freshDerivationEqualsStoredRoles() {
        let roles = paperEmerald().roles
        // A rebuilt derivation from the same inputs must equal every stored copy.
        let rebuilt = PaletteDerivation(
            seeds: .init(
                primary: emeraldSeed,
                secondary: RGBColor(r: 0.90, g: 0.60, b: 0.15),
                tertiary: RGBColor(r: 0.02, g: 0.42, b: 0.18),
                error: RGBColor(r: 0.94, g: 0.27, b: 0.27)
            ),
            neutrals: .init(
                backgroundLight: RGBColor(r: 0.99, g: 0.98, b: 0.94),
                backgroundDark: RGBColor(r: 0.09, g: 0.08, b: 0.07),
                surfaceLight: RGBColor(r: 1.00, g: 1.00, b: 1.00),
                surfaceDark: RGBColor(r: 0.15, g: 0.14, b: 0.13),
                textDark: RGBColor(r: 0.10, g: 0.11, b: 0.10),
                textLight: RGBColor(r: 0.93, g: 0.91, b: 0.89)
            )
        )
        #expect(rebuilt.roles == roles)
    }

    // MARK: - Flat accents (saturated seeds for badges)

    @Test
    func flatAccentLightEqualsSeed() {
        // The light-mode flat accent is the saturated seed itself — white initials read on it.
        let roles = paperEmerald().roles
        #expect(roles.secondary.light == RGBColor(r: 0.90, g: 0.60, b: 0.15))
        #expect(roles.tertiary.light == RGBColor(r: 0.02, g: 0.42, b: 0.18))
    }

    @Test
    func flatAccentDarkensInDarkMode() {
        // Dark-mode accent is pulled toward light text so it stays vivid (not washed out) on dark.
        let roles = paperEmerald().roles
        #expect(roles.secondary.dark.luminance < roles.secondary.light.luminance)
        #expect(roles.tertiary.dark.luminance < roles.tertiary.light.luminance)
    }

    // MARK: - Container ordering

    @Test
    func containerIsLighterInLightModeThanItsSeed() {
        // Light container = seed pulled toward the near-white canvas → soft, desaturated fill.
        let roles = paperEmerald().roles
        #expect(roles.primaryContainer.light.luminance > emeraldSeed.luminance + 0.4)
    }

    @Test
    func containerIsDarkerInDarkModeThanLightMode() {
        // Dark container = seed pulled toward near-black → raised dark surface.
        let roles = paperEmerald().roles
        #expect(roles.primaryContainer.dark.luminance < roles.primaryContainer.light.luminance)
    }

    @Test
    func onContainerContrastsWithContainerInBothModes() {
        // Dark text on a light container; light text on a dark container.
        let roles = paperEmerald().roles
        #expect(roles.onPrimaryContainer.light.luminance < roles.primaryContainer.light.luminance)
        #expect(roles.onPrimaryContainer.dark.luminance > roles.primaryContainer.dark.luminance)
    }

    // MARK: - WCAG AA contrast (the hard contract)

    @Test
    func containerLabelsMeetWCAGAAInLightMode() {
        // Every on-container label must clear 4.5:1 against its fill in light mode.
        for pair in containerPairs(paperEmerald().roles) {
            #expect(pair.contrast >= 4.5, "contrast \(String(format: "%.2f", pair.contrast)):1 below 4.5:1")
        }
    }

    @Test
    func containerLabelsMeetWCAGAAInDarkMode() {
        // Dark mode is tighter (bright seeds keep containers light); still must clear 4.5:1.
        for pair in containerPairs(paperEmerald().roles) {
            #expect(pair.contrast >= 4.5, "dark contrast \(String(format: "%.2f", pair.contrast)):1 below 4.5:1")
        }
    }

    // MARK: - Neutrals + borders

    @Test
    func surfaceVariantSitsAboveSurfaceInLightMode() {
        // surfaceVariant must read just above the pure surface so cards sit on the page.
        let roles = paperEmerald().roles
        #expect(roles.surfaceVariant.light.luminance < 1.0)          // darker than white surface
        #expect(roles.surfaceVariant.dark.luminance > 0.06)          // clearly above the near-black surface
    }

    @Test
    func outlineRolesAreSubtleMidTones() {
        // Borders sit between surface and text — never pure black or white.
        let roles = paperEmerald().roles
        #expect(roles.outlineVariant.light.luminance > 0.25)
        #expect(roles.outlineVariant.light.luminance < 0.85)
    }

    // MARK: - Helpers

    private struct ContrastPair { let contrast: Double }

    private func containerPairs(_ roles: DerivedPalette) -> [ContrastPair] {
        let pairs: [(RoleColors, RoleColors)] = [
            (roles.primaryContainer, roles.onPrimaryContainer),
            (roles.secondaryContainer, roles.onSecondaryContainer),
            (roles.tertiaryContainer, roles.onTertiaryContainer),
            (roles.errorContainer, roles.onErrorContainer)
        ]
        return pairs.flatMap { container, label in
            [
                ContrastPair(contrast: container.light.contrastRatio(to: label.light)),
                ContrastPair(contrast: container.dark.contrastRatio(to: label.dark))
            ]
        }
    }
}
