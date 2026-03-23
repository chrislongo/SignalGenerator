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
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(isActive ? 0 : 1)
            )
            .offset(y: isActive || configuration.isPressed ? 2 : 0)
            .shadow(
                color: Theme.bodyDarkest.opacity(isActive ? 0 : 0.6),
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
