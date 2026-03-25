import Testing
@testable import SignalGenerator

@Suite("SignalState")
struct SignalStateTests {

    // MARK: - Defaults

    @Test func defaultValues() {
        let state = SignalState()
        #expect(state.frequency == 440.0)
        #expect(state.waveform == .sine)
        #expect(state.stepIncrement == 1.0)
        #expect(state.volume == 5)
        #expect(state.isPlaying == true)
    }

    // MARK: - Volume

    @Test func volumePercent() {
        let state = SignalState()
        #expect(state.volumePercent == 50)
        state.volume = 0
        #expect(state.volumePercent == 0)
        state.volume = 10
        #expect(state.volumePercent == 100)
    }

    @Test func incrementVolumeClampsAt10() {
        let state = SignalState()
        state.volume = 9
        state.incrementVolume()
        #expect(state.volume == 10)
        state.incrementVolume()
        #expect(state.volume == 10)
    }

    @Test func decrementVolumeClampsAt0() {
        let state = SignalState()
        state.volume = 1
        state.decrementVolume()
        #expect(state.volume == 0)
        state.decrementVolume()
        #expect(state.volume == 0)
    }

    // MARK: - Frequency adjustment

    @Test func adjustFrequencyClampsToRange() {
        let state = SignalState()
        state.frequency = 15
        state.stepIncrement = 10
        state.adjustFrequency(by: -1)
        #expect(state.frequency == 10) // clamped at lower bound

        state.frequency = 19990
        state.adjustFrequency(by: 1)
        #expect(state.frequency == 20000) // clamped at upper bound

        state.adjustFrequency(by: 1)
        #expect(state.frequency == 20000) // stays clamped
    }

    @Test func adjustFrequencyUsesStepIncrement() {
        let state = SignalState()
        state.frequency = 1000
        state.stepIncrement = 100
        state.adjustFrequency(by: 1)
        #expect(state.frequency == 1100)

        state.stepIncrement = 0.1
        state.adjustFrequency(by: -1)
        #expect(state.frequency == 1099.9)
    }

    // MARK: - Snap frequency

    @Test func snapFrequencyRoundsToStepIncrement() {
        let state = SignalState()
        state.stepIncrement = 10
        state.frequency = 443
        state.snapFrequency()
        #expect(state.frequency == 440)

        state.frequency = 447
        state.snapFrequency()
        #expect(state.frequency == 450)
    }

    @Test func snapFrequencyIgnoresSubHzSteps() {
        let state = SignalState()
        state.stepIncrement = 0.1
        state.frequency = 443.27
        state.snapFrequency()
        #expect(state.frequency == 443.27) // unchanged
    }

    @Test func snapFrequencyClampsAfterSnap() {
        let state = SignalState()
        state.stepIncrement = 100
        state.frequency = 5
        state.snapFrequency()
        #expect(state.frequency == 10) // snaps to 0, then clamps to 10
    }

    // MARK: - Formatted frequency

    @Test func formattedFrequencyBelowKHz() {
        let state = SignalState()
        state.stepIncrement = 1
        state.frequency = 440
        #expect(state.formattedFrequency == "440")
        #expect(state.frequencyUnit == "Hz")
    }

    @Test func formattedFrequencyBelowKHzWithDecimalStep() {
        let state = SignalState()
        state.stepIncrement = 0.1
        state.frequency = 440
        #expect(state.formattedFrequency == "440.0")
    }

    @Test func formattedFrequencyAboveKHz() {
        let state = SignalState()
        state.frequency = 1000
        #expect(state.formattedFrequency == "1.00")
        #expect(state.frequencyUnit == "kHz")
    }

    @Test func formattedFrequencyAbove10KHz() {
        let state = SignalState()
        state.frequency = 15000
        #expect(state.formattedFrequency == "15.0")
        #expect(state.frequencyUnit == "kHz")
    }
}
