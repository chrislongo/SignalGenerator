import Testing
@testable import SignalGenerator

@Suite("WaveformType")
struct WaveformTypeTests {

    @Test func rawValuesMatchRenderCallback() {
        #expect(WaveformType.sine.rawValue == 0)
        #expect(WaveformType.square.rawValue == 1)
        #expect(WaveformType.saw.rawValue == 2)
        #expect(WaveformType.triangle.rawValue == 3)
        #expect(WaveformType.white.rawValue == 4)
        #expect(WaveformType.pink.rawValue == 5)
    }

    @Test func allCasesCount() {
        #expect(WaveformType.allCases.count == 6)
    }

    @Test func labels() {
        #expect(WaveformType.sine.label == "Sine")
        #expect(WaveformType.square.label == "Square")
        #expect(WaveformType.saw.label == "Saw")
        #expect(WaveformType.triangle.label == "Triangle")
        #expect(WaveformType.white.label == "White")
        #expect(WaveformType.pink.label == "Pink")
    }

    @Test func shortLabels() {
        #expect(WaveformType.sine.shortLabel == "SINE")
        #expect(WaveformType.triangle.shortLabel == "TRI")
    }

    @Test func isNoise() {
        #expect(!WaveformType.sine.isNoise)
        #expect(!WaveformType.square.isNoise)
        #expect(!WaveformType.saw.isNoise)
        #expect(!WaveformType.triangle.isNoise)
        #expect(WaveformType.white.isNoise)
        #expect(WaveformType.pink.isNoise)
    }

    @Test func identifiable() {
        for waveform in WaveformType.allCases {
            #expect(waveform.id == waveform.rawValue)
        }
    }
}
