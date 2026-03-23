import SwiftUI

struct WaveformButtonsView: View {
    @Binding var selectedWaveform: WaveformType

    private let waveforms = WaveformType.allCases

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 7) {
            ForEach(waveforms) { waveform in
                Button {
                    selectedWaveform = waveform
                } label: {
                    VStack(spacing: 3) {
                        waveformIcon(waveform)
                            .aspectRatio(2.5, contentMode: .fit)
                            .frame(height: 18)

                        Text(waveform.label)
                            .font(Theme.display(8))
                            .kerning(0.5)
                            .textCase(.uppercase)
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                }
                .chunkyButtonStyle(isActive: selectedWaveform == waveform)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Waveform icons

    @ViewBuilder
    private func waveformIcon(_ waveform: WaveformType) -> some View {
        let isActive = selectedWaveform == waveform
        let stroke = isActive ? Theme.textDark : Theme.textCream

        Canvas { context, size in
            let mid = size.height / 2
            let w = size.width
            let path: Path

            switch waveform {
            case .sine:
                path = Path { p in
                    p.move(to: CGPoint(x: 0, y: mid))
                    for i in 0...Int(w) {
                        let x = Double(i)
                        let y = mid - sin(x / w * 2 * .pi) * (mid - 2)
                        i == 0 ? p.move(to: CGPoint(x: x, y: y))
                               : p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            case .square:
                path = Path { p in
                    p.move(to:      CGPoint(x: 0,     y: size.height - 2))
                    p.addLine(to:   CGPoint(x: 0,     y: 2))
                    p.addLine(to:   CGPoint(x: w/2,   y: 2))
                    p.addLine(to:   CGPoint(x: w/2,   y: size.height - 2))
                    p.addLine(to:   CGPoint(x: w,     y: size.height - 2))
                }
            case .saw:
                path = Path { p in
                    p.move(to:    CGPoint(x: 0,   y: size.height - 2))
                    p.addLine(to: CGPoint(x: w/2, y: 2))
                    p.addLine(to: CGPoint(x: w/2, y: size.height - 2))
                    p.addLine(to: CGPoint(x: w,   y: 2))
                }
            case .triangle:
                path = Path { p in
                    p.move(to:    CGPoint(x: 0,    y: size.height - 2))
                    p.addLine(to: CGPoint(x: w/4,  y: 2))
                    p.addLine(to: CGPoint(x: w*3/4,y: size.height - 2))
                    p.addLine(to: CGPoint(x: w,    y: 2))
                }
            case .white:
                path = Path { p in
                    let pts: [CGFloat] = [0,4,8,2,11,5,3,10,6,1,9,7,4,8,3,11,2,7,5,9,4]
                    let step = w / CGFloat(pts.count - 1)
                    for (i, v) in pts.enumerated() {
                        let x = CGFloat(i) * step
                        let y = v / 11.0 * (size.height - 4) + 2
                        i == 0 ? p.move(to: CGPoint(x: x, y: y))
                               : p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            case .pink:
                path = Path { p in
                    let pts: [CGFloat] = [5,3,6,2,7,4,6,5,3,6,4,5,6,4,5,3,6,5,4,6,5]
                    let step = w / CGFloat(pts.count - 1)
                    for (i, v) in pts.enumerated() {
                        let x = CGFloat(i) * step
                        let y = v / 7.0 * (size.height - 4) + 2
                        i == 0 ? p.move(to: CGPoint(x: x, y: y))
                               : p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }

            context.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}
