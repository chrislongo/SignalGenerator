import SwiftUI

// MARK: - Chunky Button Style
// Produces a 3D press effect: shadow depth on rest, flattens on press.

struct ChunkyButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isActive ? Theme.buttonActive : Theme.buttonFace)
            .foregroundStyle(isActive ? Theme.textDark : Theme.textCream)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isActive ? 0.12 : 0.06))
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(
                color: Theme.bodyDarkest.opacity(0.6),
                radius: 0,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
            .animation(.easeOut(duration: 0.06), value: configuration.isPressed)
    }
}

// MARK: - Convenience modifier
extension View {
    func chunkyButtonStyle(isActive: Bool = false) -> some View {
        self.buttonStyle(ChunkyButtonStyle(isActive: isActive))
    }
}
