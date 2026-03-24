import SwiftUI

// MARK: - Readout shown inside the CRT display during input mode

struct FrequencyInputReadout: View {
    let inputText: String
    let state: SignalState

    var body: some View {
        HStack(alignment: .bottom) {
            // Left — input text + range hint
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(inputText.isEmpty ? "0" : inputText)
                        .font(Theme.monoBold(34))
                        .foregroundStyle(inputText.isEmpty ? Theme.amber.opacity(0.3) : Theme.amber)
                        .shadow(color: Theme.amber.opacity(0.4), radius: 10)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Blinking cursor
                    Rectangle()
                        .fill(Theme.amber)
                        .frame(width: 3, height: 30)
                        .shadow(color: Theme.amber.opacity(0.6), radius: 6)
                        .modifier(BlinkModifier())
                }

                Text("10 — 20000 Hz")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.crtTeal.opacity(0.5))
            }

            Spacer()

            // Right — waveform + volume (same as normal readout)
            VStack(alignment: .trailing, spacing: 2) {
                Text(state.waveform.shortLabel)
                    .font(Theme.monoBold(13))
                    .foregroundStyle(Theme.crtTeal)
                    .shadow(color: Theme.crtTeal.opacity(0.4), radius: 4)

                Text("VOL \(state.volumePercent)%")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.amberDim)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

// MARK: - Keypad overlay shown over the controls area

struct FrequencyKeypadView: View {
    @Binding var inputText: String
    @Binding var frequency: Double
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                keyButton("1") { append("1") }
                keyButton("2") { append("2") }
                keyButton("3") { append("3") }
                keyButton("\u{232B}", style: .dim) { backspace() }
            }
            HStack(spacing: 6) {
                keyButton("4") { append("4") }
                keyButton("5") { append("5") }
                keyButton("6") { append("6") }
                keyButton("Hz", style: .confirm) { confirm(multiplier: 1) }
            }
            HStack(spacing: 6) {
                keyButton("7") { append("7") }
                keyButton("8") { append("8") }
                keyButton("9") { append("9") }
                keyButton("kHz", style: .confirmDim) { confirm(multiplier: 1000) }
            }
            HStack(spacing: 6) {
                keyButton("ESC", style: .dim) { cancel() }
                keyButton("0") { append("0") }
                keyButton(".", style: .normal) { appendDecimal() }
                keyButton("C", style: .confirmDim) { inputText = "" }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(Theme.body)
    }

    // MARK: - Key styles

    enum KeyStyle {
        case normal, dim, confirm, confirmDim
    }

    @ViewBuilder
    private func keyButton(_ label: String, style: KeyStyle = .normal, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(style == .confirm || style == .confirmDim ? Theme.monoBold(16) : Theme.monoBold(20))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(KeypadButtonStyle(style: style))
    }

    // MARK: - Actions

    private func append(_ char: String) {
        guard inputText.count < 7 else { return }
        inputText += char
    }

    private func appendDecimal() {
        guard !inputText.contains("."), inputText.count < 7 else { return }
        inputText += inputText.isEmpty ? "0." : "."
    }

    private func backspace() {
        if !inputText.isEmpty {
            inputText.removeLast()
        }
    }

    private func confirm(multiplier: Double) {
        guard let value = Double(inputText) else { return }
        let freq = value * multiplier
        guard freq >= 10, freq <= 20000 else { return }
        frequency = freq
        isPresented = false
    }

    private func cancel() {
        isPresented = false
    }
}

// MARK: - Blink modifier

private struct BlinkModifier: ViewModifier {
    @State private var visible = true

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}

// MARK: - Keypad button style

private struct KeypadButtonStyle: ButtonStyle {
    let style: FrequencyKeypadView.KeyStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .offset(y: configuration.isPressed ? 2 : 0)
            .shadow(
                color: Color(hex: "#1a1a1c"),
                radius: 0, x: 0,
                y: configuration.isPressed ? 0 : 2
            )
            .animation(.easeOut(duration: 0.04), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch style {
        case .normal: return Color(hex: "#b8b4a8")
        case .dim: return Color(hex: "#6e6e68")
        case .confirm: return Theme.amber
        case .confirmDim: return Theme.amber.opacity(0.7)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .normal, .dim: return Color(hex: "#383838")
        case .confirm: return Theme.amber.opacity(0.15)
        case .confirmDim: return Theme.amber.opacity(0.08)
        }
    }

    private var borderColor: Color {
        switch style {
        case .confirm: return Theme.amber.opacity(0.2)
        case .confirmDim: return Theme.amber.opacity(0.1)
        default: return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .confirm, .confirmDim: return 1
        default: return 0
        }
    }
}
