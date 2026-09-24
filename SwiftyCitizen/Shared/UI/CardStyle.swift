import SwiftUI

struct CardStyle: ViewModifier {
    var radius: CGFloat = 18

    @Environment(ThemeManager.self) private var themeManager

    func body(content: Content) -> some View {
        let palette = themeManager.palette
        content
            .background(palette.surface, in: RoundedRectangle(cornerRadius: radius, style: .circular))
            .shadow(color: Color(uiColor: UIColor(red: 34 / 255, green: 38 / 255, blue: 34 / 255, alpha: 0.05)), radius: 8, x: 0, y: 2)
            .shadow(color: Color(uiColor: UIColor(red: 34 / 255, green: 38 / 255, blue: 34 / 255, alpha: 0.03)), radius: 3, x: 0, y: 1)
    }
}

extension View {
    func cardStyle(radius: CGFloat = 18) -> some View {
        modifier(CardStyle(radius: radius))
    }
}
