import SwiftUI

struct PillButtonStyle: ButtonStyle {
    var background: Color
    var paddingVertical: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, paddingVertical)
            .padding(.horizontal, 20)
            .background(Capsule().fill(background.opacity(configuration.isPressed ? 0.85 : 1)))
    }
}

extension View {
    func pillButton(background: Color, paddingVertical: CGFloat = 16) -> some View {
        self.buttonStyle(PillButtonStyle(background: background, paddingVertical: paddingVertical))
    }
}
