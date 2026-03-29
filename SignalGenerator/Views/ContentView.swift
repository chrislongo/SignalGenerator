import SwiftUI

struct ContentView: View {
    @State private var state = SignalState()
    @State private var audioEngine = AudioEngine()
    @State private var showingInput = false
    @State private var inputText = ""

    var body: some View {
        ZStack {
            // Chassis background
            Theme.body.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // ── Header ───────────────────────────────────────────
                    HeaderBar()

                    // ── CRT Display ──────────────────────────────────────
                    DisplayView(
                        state: state,
                        showingInput: $showingInput,
                        inputText: inputText
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 0)

                    // ── Waveform Buttons ─────────────────────────────────
                    sectionLabel("Waveform")

                    WaveformButtonsView(selectedWaveform: $state.waveform)

                    // ── Groove ───────────────────────────────────────────
                    GrooveDivider()
                        .padding(.top, 10)

                    // ── Frequency / Keypad ───────────────────────────────
                    VStack(spacing: 0) {
                        if showingInput {
                            FrequencyKeypadView(
                                inputText: $inputText,
                                frequency: $state.frequency,
                                isPresented: $showingInput
                            )
                            .frame(maxHeight: .infinity)
                        } else {
                            sectionLabel("Frequency")

                            HStack(alignment: .center, spacing: 14) {
                                JogwheelView(
                                    frequency: $state.frequency,
                                    stepIncrement: state.stepIncrement
                                )
                                .frame(width: 192, height: 192)

                                VStack(spacing: 12) {
                                    StepButtonsView(stepIncrement: $state.stepIncrement)
                                    VolumeButtonsView(volume: $state.volume)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                    .frame(height: 222)

                    // ── Groove ───────────────────────────────────────────
                    GrooveDivider()

                    // ── Power ────────────────────────────────────────────
                    PowerView(isPlaying: $state.isPlaying)

                    // ── Footer ───────────────────────────────────────────
                    HStack {
                        Text("Precision Audio Instrument")
                        Spacer()
                        Text("48kHz / 16-bit")
                    }
                    .font(Theme.display(7))
                    .foregroundStyle(Theme.textFaint.opacity(0.6))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
                }
            }
            .scrollDisabled(true)
        }
        // Push audio engine updates whenever state changes
        .onChange(of: showingInput) {
            if !showingInput { inputText = "" }
        }
        .onChange(of: state.stepIncrement)   { state.snapFrequency() }
        .onChange(of: state.frequency)      { audioEngine.update(state: state) }
        .onChange(of: state.waveform)       { audioEngine.update(state: state) }
        .onChange(of: state.volume)         { audioEngine.update(state: state) }
        .onChange(of: state.isPlaying)      { audioEngine.update(state: state) }
        .onAppear {
            audioEngine.update(state: state)
            audioEngine.start()
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(Theme.display(9))
                .kerning(3)
                .foregroundStyle(Theme.textFaint)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}
