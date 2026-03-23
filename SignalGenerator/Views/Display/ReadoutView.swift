import SwiftUI

struct ReadoutView: View {
    let state: SignalState

    var body: some View {
        HStack(alignment: .bottom) {
            // Left — frequency + note
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(state.formattedFrequency)
                        .font(Theme.monoBold(34))
                        .foregroundStyle(Theme.amber)
                        .shadow(color: Theme.amber.opacity(0.4), radius: 8)

                    Text(state.frequencyUnit)
                        .font(Theme.monoBold(14))
                        .foregroundStyle(Theme.amberDim)
                }

                Text(state.musicalNote)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.crtTeal.opacity(0.75))
                    .shadow(color: Theme.crtTeal.opacity(0.3), radius: 4)
            }

            Spacer()

            // Right — waveform + volume
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
