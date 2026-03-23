import SwiftUI

struct HeaderBar: View {
    var body: some View {
        HStack {
            Text("SIGNAL GEN")
                .font(Theme.displayHeavy(13))
                .kerning(4)
                .foregroundStyle(.white)

            Spacer()

            Text("SG-2400")
                .font(Theme.monoBold(10))
                .foregroundStyle(.white.opacity(0.6))
                .kerning(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Theme.teal)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.tealDark)
                .frame(height: 2)
        }
    }
}
