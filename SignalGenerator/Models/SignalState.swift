import Foundation
import Observation

@Observable
final class SignalState {

    // MARK: - Signal parameters
    var frequency: Double = 440.0
    var waveform: WaveformType = .sine
    var stepIncrement: Double = 1.0   // 0.1, 1, 10, 100
    var volume: Int = 5               // 0...10
    var isPlaying: Bool = true

    // MARK: - Persistence
    private enum Keys {
        static let frequency    = "frequency"
        static let waveform     = "waveform"
        static let stepIncrement = "stepIncrement"
        static let volume       = "volume"
        static let isPlaying    = "isPlaying"
    }

    func load() {
        let d = UserDefaults.standard
        if d.object(forKey: Keys.frequency) != nil {
            frequency     = d.double(forKey: Keys.frequency).clamped(to: 10...20000)
            waveform      = WaveformType(rawValue: Int32(d.integer(forKey: Keys.waveform))) ?? .sine
            let savedStep = d.double(forKey: Keys.stepIncrement)
            stepIncrement = [0.1, 1.0, 10.0, 100.0].contains(savedStep) ? savedStep : 1.0
            volume        = d.integer(forKey: Keys.volume).clamped(to: 0...10)
            isPlaying     = d.bool(forKey: Keys.isPlaying)
        }
    }

    func save() {
        let d = UserDefaults.standard
        d.set(frequency,     forKey: Keys.frequency)
        d.set(waveform.rawValue, forKey: Keys.waveform)
        d.set(stepIncrement, forKey: Keys.stepIncrement)
        d.set(volume,        forKey: Keys.volume)
        d.set(isPlaying,     forKey: Keys.isPlaying)
    }

    // MARK: - Derived
    var volumePercent: Int { volume * 10 }

    var formattedFrequency: String {
        if frequency >= 1000 {
            let kHz = frequency / 1000
            return kHz < 10
                ? String(format: "%.2f", kHz)
                : String(format: "%.1f", kHz)
        } else {
            return stepIncrement < 1
                ? String(format: "%.1f", frequency)
                : String(format: "%.0f", frequency)
        }
    }

    var frequencyUnit: String {
        frequency >= 1000 ? "kHz" : "Hz"
    }

    var musicalNote: String {
        FrequencyToNote.convert(frequency)
    }

    // MARK: - Helpers
    func incrementVolume() {
        if volume < 10 { volume += 1 }
    }

    func decrementVolume() {
        if volume > 0 { volume -= 1 }
    }

    func adjustFrequency(by delta: Double) {
        frequency = (frequency + delta * stepIncrement).clamped(to: 10...20000)
    }

    func snapFrequency() {
        if stepIncrement >= 1 {
            frequency = (frequency / stepIncrement).rounded() * stepIncrement
            frequency = frequency.clamped(to: 10...20000)
        }
    }
}

// MARK: - Comparable clamping
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
