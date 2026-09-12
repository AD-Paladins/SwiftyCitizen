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

@MainActor
@Observable
final class SessionFeedbackManager {
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.storageKey) }
    }

    private static let storageKey = "sessionFeedbackEnabled"

    init() {
        self.isEnabled = UserDefaults.standard.object(forKey: Self.storageKey) as? Bool ?? true
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
    let canvas: Color
    let surface: Color
    let success: Color
    let warning: Color
    let danger: Color
    let onPrimary: Color

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
        canvas: dynamic(light: 0.93, green: 0.94, blue: 0.96, dark: 0.07, darkGreen: 0.09, darkBlue: 0.12),
        surface: dynamic(light: 1.00, green: 1.00, blue: 1.00, dark: 0.13, darkGreen: 0.15, darkBlue: 0.19),
        success: dynamic(light: 0.18, green: 0.49, blue: 0.36, dark: 0.31, darkGreen: 0.69, darkBlue: 0.51),
        warning: dynamic(light: 0.73, green: 0.48, blue: 0.16, dark: 0.91, darkGreen: 0.63, darkBlue: 0.31),
        danger: dynamic(light: 0.66, green: 0.29, blue: 0.23, dark: 0.85, darkGreen: 0.48, darkBlue: 0.42),
        onPrimary: Color.white
    )

    static let paperEmerald = AppPalette(
        ink: dynamic(light: 0.15, green: 0.16, blue: 0.17, dark: 0.93, darkGreen: 0.91, darkBlue: 0.89),
        primary: dynamic(light: 0.12, green: 0.56, blue: 0.43, dark: 0.30, darkGreen: 0.73, darkBlue: 0.60),
        canvas: dynamic(light: 0.96, green: 0.95, blue: 0.92, dark: 0.09, darkGreen: 0.08, darkBlue: 0.07),
        surface: dynamic(light: 1.00, green: 1.00, blue: 1.00, dark: 0.15, darkGreen: 0.14, darkBlue: 0.13),
        success: dynamic(light: 0.12, green: 0.56, blue: 0.43, dark: 0.30, darkGreen: 0.73, darkBlue: 0.60),
        warning: dynamic(light: 0.73, green: 0.48, blue: 0.16, dark: 0.91, darkGreen: 0.63, darkBlue: 0.31),
        danger: dynamic(light: 0.66, green: 0.29, blue: 0.23, dark: 0.85, darkGreen: 0.48, darkBlue: 0.42),
        onPrimary: Color.white
    )

    static let studyCalm = AppPalette(
        ink: dynamic(light: 0.18, green: 0.20, blue: 0.27, dark: 0.89, darkGreen: 0.90, darkBlue: 0.93),
        primary: dynamic(light: 0.18, green: 0.20, blue: 0.27, dark: 0.60, darkGreen: 0.63, darkBlue: 0.75),
        canvas: dynamic(light: 0.93, green: 0.93, blue: 0.94, dark: 0.08, darkGreen: 0.09, darkBlue: 0.11),
        surface: dynamic(light: 1.00, green: 1.00, blue: 1.00, dark: 0.14, darkGreen: 0.15, darkBlue: 0.17),
        success: dynamic(light: 0.18, green: 0.49, blue: 0.36, dark: 0.31, darkGreen: 0.69, darkBlue: 0.51),
        warning: dynamic(light: 0.73, green: 0.48, blue: 0.16, dark: 0.91, darkGreen: 0.63, darkBlue: 0.31),
        danger: dynamic(light: 0.66, green: 0.29, blue: 0.23, dark: 0.85, darkGreen: 0.48, darkBlue: 0.42),
        onPrimary: Color.white
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
}