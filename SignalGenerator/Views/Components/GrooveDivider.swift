import SwiftUI

/// Recessed panel groove — mimics injection-molded divider lines.
struct GrooveDivider: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.groove)
                .frame(height: 2)
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
    }
}
