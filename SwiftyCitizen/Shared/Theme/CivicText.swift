import SwiftUI

enum CivicText {
    case displayLG
    case metricDisplay
    case headlineLG
    case headlineMD
    case headlineSM
    case bodyLG
    case bodyMD
    case bodySM
    case labelLG
    case labelMD
    case labelSM

    var font: Font {
        switch self {
        case .displayLG:
            return .system(size: 32, weight: .black, design: .rounded)
        case .metricDisplay:
            return .system(size: 28, weight: .black, design: .rounded)
        case .headlineLG:
            return .system(size: 22, weight: .bold, design: .rounded)
        case .headlineMD:
            return .system(size: 18, weight: .semibold, design: .rounded)
        case .headlineSM:
            return .system(size: 16, weight: .medium, design: .rounded)
        case .bodyLG:
            return .system(size: 16, weight: .regular, design: .rounded)
        case .bodyMD:
            return .system(size: 14, weight: .regular, design: .rounded)
        case .bodySM:
            return .system(size: 12, weight: .regular, design: .rounded)
        case .labelLG:
            return .system(size: 14, weight: .medium, design: .rounded)
        case .labelMD:
            return .system(size: 12, weight: .regular, design: .rounded)
        case .labelSM:
            return .system(size: 11, weight: .regular, design: .rounded)
        }
    }
}
