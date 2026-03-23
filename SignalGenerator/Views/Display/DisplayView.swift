import SwiftUI

struct DisplayView: View {
    let state: SignalState

    var body: some View {
        VStack(spacing: 0) {
            // Waveform canvas
            WaveformCanvasView(
                waveform: state.waveform,
                frequency: state.frequency,
                volume: state.volume,
                isPlaying: state.isPlaying
            )
            .frame(height: 118)

            // Divider
            Rectangle()
                .fill(Color(hex: "#1a1e14"))
                .frame(height: 1)

            // Readout
            ReadoutView(state: state)
        }
        .background(Theme.crtBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        // Bezel border + inner shadow
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Theme.bodyDark, lineWidth: 3)
        )
        // Screen curvature highlight
        .overlay(alignment: .topLeading) {
            RadialGradient(
                gradient: Gradient(colors: [.white.opacity(0.025), .clear]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 120
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .allowsHitTesting(false)
        }
        // Scanlines overlay
        .overlay(
            ScanlineOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Scanlines

struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineSpacing: CGFloat = 4
                var y: CGFloat = 0
                while y < size.height {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(.black.opacity(0.1)), lineWidth: 1.5)
                    y += lineSpacing
                }
            }
        }
    }
}
