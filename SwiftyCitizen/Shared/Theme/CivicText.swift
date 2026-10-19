import SwiftUI
import UIKit

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
        // Preserve the brand's exact point size while opting into Dynamic Type:
        // UIFontMetrics scales the fixed size relative to the token's text style,
        // and design: .rounded keeps the SF Pro Rounded face at standard sizes.
        // (AX/augmented sizes fall back to plain SF Pro — documented Apple limit.)
        switch self {
        case .displayLG:
            return scaled(32, weight: .black, relativeTo: .title1)
        case .metricDisplay:
            return scaled(28, weight: .black, relativeTo: .title1)
        case .headlineLG:
            return scaled(22, weight: .bold, relativeTo: .headline)
        case .headlineMD:
            return scaled(18, weight: .semibold, relativeTo: .headline)
        case .headlineSM:
            return scaled(16, weight: .medium, relativeTo: .subheadline)
        case .bodyLG:
            return scaled(16, weight: .regular, relativeTo: .body)
        case .bodyMD:
            return scaled(14, weight: .regular, relativeTo: .callout)
        case .bodySM:
            return scaled(12, weight: .regular, relativeTo: .footnote)
        case .labelLG:
            return scaled(14, weight: .medium, relativeTo: .subheadline)
        case .labelMD:
            return scaled(12, weight: .regular, relativeTo: .footnote)
        case .labelSM:
            return scaled(11, weight: .regular, relativeTo: .footnote)
        }
    }

    private func scaled(_ size: CGFloat, weight: Font.Weight, relativeTo style: UIFont.TextStyle) -> Font {
        let scaledSize = UIFontMetrics(forTextStyle: style).scaledValue(for: size)
        return .system(size: scaledSize, weight: weight, design: .rounded)
    }
}
