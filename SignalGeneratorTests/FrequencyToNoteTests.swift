import Testing
@testable import SignalGenerator

@Suite("FrequencyToNote")
struct FrequencyToNoteTests {

    @Test func a440() {
        #expect(FrequencyToNote.convert(440.0) == "A4")
    }

    @Test func middleC() {
        // C4 = 261.626 Hz
        #expect(FrequencyToNote.convert(261.626) == "C4")
    }

    @Test func centsPositive() {
        // 450 Hz is ~39 cents sharp of A4
        let result = FrequencyToNote.convert(450.0)
        #expect(result.hasPrefix("A4 +"))
        #expect(result.hasSuffix("¢"))
    }

    @Test func centsNegative() {
        // 430 Hz is flat of A4
        let result = FrequencyToNote.convert(430.0)
        #expect(result.contains("-"))
        #expect(result.hasSuffix("¢"))
    }

    @Test func zeroReturnsEmpty() {
        #expect(FrequencyToNote.convert(0) == "")
    }

    @Test func negativeReturnsEmpty() {
        #expect(FrequencyToNote.convert(-100) == "")
    }

    @Test func octaveBoundaries() {
        // A3 = 220 Hz, A5 = 880 Hz
        #expect(FrequencyToNote.convert(220.0) == "A3")
        #expect(FrequencyToNote.convert(880.0) == "A5")
    }

    @Test func lowFrequency() {
        // ~16.35 Hz = C0
        let result = FrequencyToNote.convert(16.35)
        #expect(result.hasPrefix("C"))
    }

    @Test func highFrequency() {
        // 19912 Hz ≈ D#10 area
        let result = FrequencyToNote.convert(19912.0)
        #expect(!result.isEmpty)
    }

    @Test func exactSemitones() {
        // E4 = 329.628 Hz
        let result = FrequencyToNote.convert(329.628)
        #expect(result == "E4")
    }
}
