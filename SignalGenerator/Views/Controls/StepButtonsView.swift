import SwiftUI

struct StepButtonsView: View {
    @Binding var stepIncrement: Double

    private let steps: [(value: Double, label: String)] = [
        (0.1, "0.1"),
        (1,   "1"),
        (10,  "10"),
        (100, "100"),
    ]

    var body: some View {
        VStack(spacing: 4) {
            Text("STEP")
                .font(Theme.display(8))
                .kerning(2)
                .foregroundStyle(Theme.textFaint)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 2), spacing: 5) {
                ForEach(steps, id: \.value) { step in
                    Button {
                        stepIncrement = step.value
                    } label: {
                        VStack(spacing: 1) {
                            Text(step.label)
                                .font(Theme.monoBold(13))
                            Text("Hz")
                                .font(Theme.display(7))
                                .opacity(0.6)
                        }
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                    }
                    .chunkyButtonStyle(isActive: stepIncrement == step.value)
                }
            }
        }
    }
}
