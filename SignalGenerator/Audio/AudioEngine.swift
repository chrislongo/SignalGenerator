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
        var triIntegrator: Double = 0  // leaky integrator for band-limited triangle

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

        // Crossfade state for seamless waveform switching and play/stop
        var prevWaveform: Int32 = 0
        var crossfadeRemaining: Int = 0
        let crossfadeSamples: Int = 256
        var wasPlaying: Bool = true
        var fadeInRemaining: Int = 0
        var fadeOutRemaining: Int = 0

        // PolyBLEP: smooths discontinuities in square/saw waves to eliminate aliasing.
        // `t` is the phase position, `dt` is the phase increment per sample.
        // Returns a correction value near waveform transitions.
        func polyBlep(_ t: Double, _ dt: Double) -> Double {
            if t < dt {
                // Just passed a rising edge
                let x = t / dt
                return x + x - x * x - 1.0
            } else if t > 1.0 - dt {
                // About to hit a rising edge
                let x = (t - 1.0) / dt
                return x * x + x + x + 1.0
            }
            return 0.0
        }

        sourceNode = AVAudioSourceNode(format: format) { isSilence, _, frameCount, audioBufferList -> OSStatus in
            let freq      = params.frequency
            let vol       = params.volume
            let waveform  = params.waveform
            let playing   = params.isPlaying

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let rawBuffer = ablPointer[0].mData else { return noErr }
            let buffer = rawBuffer.assumingMemoryBound(to: Float.self)

            // Detect play/stop transitions for fade in/out
            if playing && !wasPlaying {
                fadeInRemaining = crossfadeSamples
                fadeOutRemaining = 0
            } else if !playing && wasPlaying {
                fadeOutRemaining = crossfadeSamples
            }
            wasPlaying = playing

            if !playing && fadeOutRemaining == 0 {
                isSilence.pointee = true
                for i in 0..<Int(frameCount) { buffer[i] = 0 }
                return noErr
            }

            // Detect waveform change and start crossfade
            if waveform != prevWaveform {
                crossfadeRemaining = crossfadeSamples
                prevWaveform = waveform
            }

            let phaseIncrement = Double(freq) / Self.sampleRate

            for i in 0..<Int(frameCount) {
                var sample: Double

                switch waveform {
                case 0: // Sine (no aliasing)
                    sample = sin(2.0 * .pi * phase)

                case 1: // Square with PolyBLEP
                    sample = phase < 0.5 ? 1.0 : -1.0
                    sample += polyBlep(phase, phaseIncrement)
                    sample -= polyBlep(fmod(phase + 0.5, 1.0), phaseIncrement)

                case 2: // Sawtooth with PolyBLEP
                    sample = 2.0 * phase - 1.0
                    sample -= polyBlep(phase, phaseIncrement)

                case 3: // Triangle (integrated band-limited square)
                    var sq = phase < 0.5 ? 1.0 : -1.0
                    sq += polyBlep(phase, phaseIncrement)
                    sq -= polyBlep(fmod(phase + 0.5, 1.0), phaseIncrement)
                    // Integrate the square wave to produce triangle
                    triIntegrator += phaseIncrement * sq * 4.0
                    sample = triIntegrator

                case 4: // White noise
                    sample = Double(lcgNext())

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
                    sample = pink

                default:
                    sample = 0
                }

                // Apply crossfade (waveform switch)
                if crossfadeRemaining > 0 {
                    let t = Double(crossfadeRemaining) / Double(crossfadeSamples)
                    sample *= (1.0 - t)
                    crossfadeRemaining -= 1
                }

                // Apply fade in/out (play/stop)
                if fadeInRemaining > 0 {
                    let t = Double(fadeInRemaining) / Double(crossfadeSamples)
                    sample *= (1.0 - t)
                    fadeInRemaining -= 1
                } else if fadeOutRemaining > 0 {
                    let t = Double(fadeOutRemaining) / Double(crossfadeSamples)
                    sample *= t
                    fadeOutRemaining -= 1
                }

                buffer[i] = Float(sample) * vol

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
