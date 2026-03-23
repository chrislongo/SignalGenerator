import SwiftUI

struct VolumeButtonsView: View {
    @Binding var volume: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("VOL")
                .font(Theme.display(8))
                .kerning(2)
                .foregroundStyle(Theme.textFaint)

            HStack(spacing: 5) {
                Button {
                    if volume > 0 { volume -= 1 }
                } label: {
                    Text("−")
                        .font(Theme.monoBold(20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .chunkyButtonStyle()

                Button {
                    if volume < 10 { volume += 1 }
                } label: {
                    Text("+")
                        .font(Theme.monoBold(20))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .chunkyButtonStyle()
            }
        }
    }
}
