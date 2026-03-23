import Foundation

enum FrequencyToNote {
    private static let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    /// Returns the nearest musical note for a given frequency.
    /// e.g. 440 Hz → "A4", 450 Hz → "A4 +39¢"
    static func convert(_ frequency: Double) -> String {
        guard frequency > 0 else { return "" }

        // Semitones relative to A4 (440 Hz)
        let semitones = 12.0 * log2(frequency / 440.0)
        let rounded = semitones.rounded()
        let midi = Int(rounded) + 69         // A4 = MIDI 69
        let cents = Int((semitones - rounded) * 100)

        let noteName = noteNames[((midi % 12) + 12) % 12]
        let octave = (midi / 12) - 1

        if cents == 0 {
            return "\(noteName)\(octave)"
        } else if cents > 0 {
            return "\(noteName)\(octave) +\(cents)¢"
        } else {
            return "\(noteName)\(octave) \(cents)¢"
        }
    }
}
