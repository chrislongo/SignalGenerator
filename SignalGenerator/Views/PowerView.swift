import SwiftUI

struct PowerView: View {
    @Binding var isPlaying: Bool

    var body: some View {
        HStack {
            // Power button group
            Button {
                isPlaying.toggle()
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? Theme.red : Theme.bodyLighter)
                            .shadow(
                                color: isPlaying ? Theme.red.opacity(0.25) : .clear,
                                radius: 6
                            )

                        // Power icon
                        PowerIcon()
                            .stroke(
                                isPlaying ? Color.white : Theme.textFaint,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 20, height: 20)
                    }
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.25), radius: 0, y: isPlaying ? 2 : 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("OUTPUT")
                            .font(Theme.display(9))
                            .kerning(2)
                            .foregroundStyle(Theme.textFaint)

                        Text(isPlaying ? "ACTIVE" : "OFF")
                            .font(Theme.monoBold(10))
                            .foregroundStyle(isPlaying ? Theme.red : Theme.textFaint)
                            .shadow(color: isPlaying ? Theme.red.opacity(0.3) : .clear, radius: 4)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Power icon shape (circle with gap + vertical line)

struct PowerIcon: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let cx = rect.midX
            let cy = rect.midY
            let r  = rect.width * 0.42

            // Vertical line at top
            p.move(to: CGPoint(x: cx, y: cy - r * 1.1))
            p.addLine(to: CGPoint(x: cx, y: cy - r * 0.3))

            // Arc with gap at top (separate subpath)
            p.move(to: CGPoint(
                x: cx + r * cos(.pi * -60 / 180),
                y: cy + r * sin(.pi * -60 / 180)
            ))
            p.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: r,
                startAngle: .degrees(-60),
                endAngle:   .degrees(240),
                clockwise: false
            )
        }
    }
}
