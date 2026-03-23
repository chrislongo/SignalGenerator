import AVFoundation

// MARK: - Thread-safe audio parameters
//
// AudioParameters is accessed from two threads:
//   - Main thread: UI writes new values via set*() methods
//   - Audio thread: render callback reads values
//
// On ARM64 (all modern iOS devices), naturally aligned 32-bit loads/stores
// are single-instruction atomic operations. We use Int32/Float (both 32-bit)
// for all parameters. This is safe in practice even though Swift's memory
// model doesn't formally guarantee it.
final class AudioParameters: @unchecked Sendable {
    private var _frequency: Float = 440.0
    private var _volume: Float = 0.5
    private var _waveform: Int32 = 0
    private var _isPlaying: Int32 = 1

    var frequency: Float { _frequency }
    var volume: Float    { _volume }
    var waveform: Int32  { _waveform }
    var isPlaying: Bool  { _isPlaying != 0 }

    func setFrequency(_ v: Float)  { _frequency = v }
    func setVolume(_ v: Float)     { _volume = v }
    func setWaveform(_ v: Int32)   { _waveform = v }
    func setIsPlaying(_ v: Bool)   { _isPlaying = v ? 1 : 0 }
}

// MARK: - Audio Engine
final class AudioEngine {

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let params = AudioParameters()

    static let sampleRate: Double = 48000

    init() {
        configureAudioSession()
        setupSourceNode()
        setupGraph()
    }

    // MARK: - Setup

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setPreferredSampleRate(Self.sampleRate)
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func setupSourceNode() {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: Self.sampleRate,
            channels: 1
        )!

        let params = self.params
        var phase: Double = 0

        // Pink noise state (Voss-McCartney algorithm)
        var pinkB0: Double = 0, pinkB1: Double = 0, pinkB2: Double = 0
        var pinkB3: Double = 0, pinkB4: Double = 0, pinkB5: Double = 0, pinkB6: Double = 0

        // Simple LCG for lock-free random numbers on the audio thread
        var lcgState: UInt64 = 12345678901234567

        func lcgNext() -> Float {
            lcgState = lcgState &* 6364136223846793005 &+ 1442695040888963407
            let bits = UInt32(lcgState >> 33)
            let f = Float(bitPattern: (bits & 0x007FFFFF) | 0x3F800000) - 1.0
            return f * 2.0 - 1.0
        }

        sourceNode = AVAudioSourceNode(format: format) { isSilence, _, frameCount, audioBufferList -> OSStatus in
            let freq      = params.frequency
            let vol       = params.volume
            let waveform  = params.waveform
            let playing   = params.isPlaying

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let rawBuffer = ablPointer[0].mData else { return noErr }
            let buffer = rawBuffer.assumingMemoryBound(to: Float.self)

            if !playing {
                isSilence.pointee = true
                for i in 0..<Int(frameCount) { buffer[i] = 0 }
                return noErr
            }

            let phaseIncrement = Double(freq) / Self.sampleRate

            for i in 0..<Int(frameCount) {
                let sample: Float

                switch waveform {
                case 0: // Sine
                    sample = Float(sin(2.0 * .pi * phase))

                case 1: // Square
                    sample = phase < 0.5 ? 1.0 : -1.0

                case 2: // Sawtooth
                    sample = Float(2.0 * phase - 1.0)

                case 3: // Triangle
                    sample = Float(4.0 * abs(phase - 0.5) - 1.0)

                case 4: // White noise
                    sample = lcgNext()

                case 5: // Pink noise (Voss-McCartney)
                    let white = Double(lcgNext())
                    pinkB0 = 0.99886 * pinkB0 + white * 0.0555179
                    pinkB1 = 0.99332 * pinkB1 + white * 0.0750759
                    pinkB2 = 0.96900 * pinkB2 + white * 0.1538520
                    pinkB3 = 0.86650 * pinkB3 + white * 0.3104856
                    pinkB4 = 0.55000 * pinkB4 + white * 0.5329522
                    pinkB5 = -0.7616 * pinkB5 - white * 0.0168980
                    let pink = (pinkB0 + pinkB1 + pinkB2 + pinkB3 + pinkB4 + pinkB5 + pinkB6 + white * 0.5362) * 0.11
                    pinkB6 = white * 0.115926
                    sample = Float(pink)

                default:
                    sample = 0
                }

                buffer[i] = sample * vol

                // Advance phase only for tonal waveforms
                if waveform < 4 {
                    phase += phaseIncrement
                    if phase >= 1.0 { phase -= 1.0 }
                }
            }

            return noErr
        }
    }

    private func setupGraph() {
        guard let sourceNode else { return }
        let mixer = engine.mainMixerNode
        let output = engine.outputNode
        let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1)!
        let outputFormat = output.inputFormat(forBus: 0)

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)
        engine.connect(mixer, to: output, format: outputFormat)
        engine.prepare()
    }

    // MARK: - Control

    func start() {
        do {
            try engine.start()
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
    }

    // MARK: - Parameter updates (call from main thread)

    func update(state: SignalState) {
        params.setFrequency(Float(state.frequency))
        params.setVolume(Float(state.volume) / 10.0)
        params.setWaveform(state.waveform.rawValue)
        params.setIsPlaying(state.isPlaying)
    }
}
