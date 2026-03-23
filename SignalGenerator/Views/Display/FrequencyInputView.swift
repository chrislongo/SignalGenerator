import SwiftUI

struct FrequencyInputView: View {
    @Binding var frequency: Double
    @Binding var isPresented: Bool

    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Input field
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(inputText.isEmpty ? "0" : inputText)
                        .font(Theme.monoBold(38))
                        .foregroundStyle(inputText.isEmpty ? Theme.amber.opacity(0.3) : Theme.amber)
                        .shadow(color: Theme.amber.opacity(0.4), radius: 10)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Blinking cursor
                    Rectangle()
                        .fill(Theme.amber)
                        .frame(width: 3, height: 34)
                        .shadow(color: Theme.amber.opacity(0.6), radius: 6)
                        .modifier(BlinkModifier())
                }

                Text("10 — 20000 Hz")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.crtTeal.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Rectangle()
                .fill(Color(hex: "#1a1e14"))
                .frame(height: 1)

            // Keypad
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    keyButton("1") { append("1") }
                    keyButton("2") { append("2") }
                    keyButton("3") { append("3") }
                    keyButton("\u{232B}", style: .dim) { backspace() }
                }
                HStack(spacing: 5) {
                    keyButton("4") { append("4") }
                    keyButton("5") { append("5") }
                    keyButton("6") { append("6") }
                    keyButton("Hz", style: .confirm) { confirm(multiplier: 1) }
                }
                HStack(spacing: 5) {
                    keyButton("7") { append("7") }
                    keyButton("8") { append("8") }
                    keyButton("9") { append("9") }
                    keyButton("kHz", style: .confirmDim) { confirm(multiplier: 1000) }
                }
                HStack(spacing: 5) {
                    keyButton("ESC", style: .dim) { cancel() }
                    keyButton("0") { append("0") }
                    keyButton(".", style: .normal) { appendDecimal() }
                    Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Key styles

    enum KeyStyle {
        case normal, dim, confirm, confirmDim
    }

    @ViewBuilder
    private func keyButton(_ label: String, style: KeyStyle = .normal, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(style == .confirm || style == .confirmDim ? Theme.monoBold(13) : Theme.monoBold(16))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeypadButtonStyle(style: style))
        .aspectRatio(1.4, contentMode: .fit)
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
    let style: FrequencyInputView.KeyStyle

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
