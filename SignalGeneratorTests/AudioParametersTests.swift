import Testing
@testable import SignalGenerator

@Suite("AudioParameters")
struct AudioParametersTests {

    @Test func defaultValues() {
        let params = AudioParameters()
        #expect(params.frequency == 440.0)
        #expect(params.volume == 0.5)
        #expect(params.waveform == 0)
        #expect(params.isPlaying == true)
    }

    @Test func setFrequency() {
        let params = AudioParameters()
        params.setFrequency(1000.0)
        #expect(params.frequency == 1000.0)
    }

    @Test func setVolume() {
        let params = AudioParameters()
        params.setVolume(0.0)
        #expect(params.volume == 0.0)
        params.setVolume(1.0)
        #expect(params.volume == 1.0)
    }

    @Test func setWaveform() {
        let params = AudioParameters()
        for waveform in WaveformType.allCases {
            params.setWaveform(waveform.rawValue)
            #expect(params.waveform == waveform.rawValue)
        }
    }

    @Test func setIsPlaying() {
        let params = AudioParameters()
        params.setIsPlaying(false)
        #expect(params.isPlaying == false)
        params.setIsPlaying(true)
        #expect(params.isPlaying == true)
    }
}
