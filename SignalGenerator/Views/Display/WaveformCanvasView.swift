import SwiftUI

struct WaveformCanvasView: View {
    let waveform: WaveformType
    let frequency: Double
    let volume: Int
    let isPlaying: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard isPlaying else { return }

                let t = timeline.date.timeIntervalSinceReferenceDate
                let mid = size.height / 2
                let amp = (size.height / 2 - 6) * CGFloat(volume) / 10.0

                // How many cycles to show — scales with frequency
                let cycles: Double
                if waveform.isNoise {
                    cycles = 1
                } else {
                    cycles = min(max(frequency / 80.0, 1.5), 12.0)
                }

                // Build waveform path
                let path = Path { p in
                    let steps = Int(size.width)
                    for x in 0...steps {
                        let xf = Double(x)
                        let phase = (xf / size.width) * cycles + t * 0.4
                        let y = mid - sampleY(phase: phase, t: t, x: xf, width: size.width) * amp

                        if x == 0 {
                            p.move(to: CGPoint(x: xf, y: y))
                        } else {
                            p.addLine(to: CGPoint(x: xf, y: y))
                        }
                    }
                }

                // Glow pass (wide, transparent)
                context.stroke(path, with: .color(Theme.crtTeal.opacity(0.12)), lineWidth: 8)

                // Main trace
                context.stroke(path, with: .color(Theme.crtTeal.opacity(0.88)), lineWidth: 2)

                // Draw grid
                drawGrid(context: context, size: size)
            }
        }
    }

    // MARK: - Waveform sample

    private func sampleY(phase: Double, t: Double, x: Double, width: Double) -> Double {
        // Fractional part of phase drives all waveforms
        let p = phase.truncatingRemainder(dividingBy: 1.0)
        let pPos = p < 0 ? p + 1 : p

        switch waveform {
        case .sine:
            return sin(2.0 * .pi * pPos)
        case .square:
            return pPos < 0.5 ? 1.0 : -1.0
        case .saw:
            return 2.0 * pPos - 1.0
        case .triangle:
            return 4.0 * abs(pPos - 0.5) - 1.0
        case .white:
            // Deterministic noise based on position + time
            return pseudoRandom(seed: x * 0.7 + t * 400)
        case .pink:
            // Smoother noise for pink approximation
            return (pseudoRandom(seed: x * 0.7 + t * 300) * 0.5
                  + pseudoRandom(seed: x * 0.3 + t * 150) * 0.3
                  + pseudoRandom(seed: x * 0.1 + t *  75) * 0.2)
        }
    }

    /// Fast deterministic hash → [-1, 1]
    private func pseudoRandom(seed: Double) -> Double {
        let x = sin(seed * 127.1 + 311.7) * 43758.5453
        return x - x.rounded(.towardZero)
    }

    // MARK: - Grid

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let color = Theme.crtTeal.opacity(0.06)
        let cols = 10
        let rows = 5

        // Vertical lines
        for i in 0...cols {
            let x = size.width / Double(cols) * Double(i)
            let path = Path { p in
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(path, with: .color(color), lineWidth: 0.5)
        }

        // Horizontal lines
        for i in 0...rows {
            let y = size.height / Double(rows) * Double(i)
            let dashColor = i == rows / 2
                ? Theme.crtTeal.opacity(0.1)
                : color
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(dashColor), lineWidth: 0.5)
        }
    }
}
