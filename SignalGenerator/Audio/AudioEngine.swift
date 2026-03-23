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

        // 4x oversampling: generate at 192 kHz, filter, decimate to 48 kHz
        let oversampleFactor = 4
        let oversampleRate = Self.sampleRate * Double(oversampleFactor)

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

        // Crossfade state for seamless waveform switching
        var prevWaveform: Int32 = 0
        var crossfadeRemaining: Int = 0
        let crossfadeSamples: Int = 256

        // Half-band FIR filter for 4x decimation (15-tap)
        // Designed for steep cutoff at Nyquist/4 with good stopband rejection
        let filterTaps: [Float] = [
            -0.0105,  0.0,  0.0596,  0.0,  -0.1827,
             0.0,     0.6273, 1.0,    0.6273, 0.0,
            -0.1827,  0.0,   0.0596,  0.0,  -0.0105
        ]
        let filterLen = filterTaps.count
        // Ring buffer for filter state
        var filterBuf = [Float](repeating: 0, count: filterLen)
        var filterIdx = 0
        // Normalization: sum of taps
        let filterGain: Float = 1.0 / filterTaps.reduce(0, +)

        func generateSample(waveform: Int32, phase: Double) -> Float {
            switch waveform {
            case 0: return Float(sin(2.0 * .pi * phase))
            case 1: return phase < 0.5 ? 1.0 : -1.0
            case 2: return Float(2.0 * phase - 1.0)
            case 3: return Float(4.0 * abs(phase - 0.5) - 1.0)
            case 4: return lcgNext()
            case 5:
                let white = Double(lcgNext())
                pinkB0 = 0.99886 * pinkB0 + white * 0.0555179
                pinkB1 = 0.99332 * pinkB1 + white * 0.0750759
                pinkB2 = 0.96900 * pinkB2 + white * 0.1538520
                pinkB3 = 0.86650 * pinkB3 + white * 0.3104856
                pinkB4 = 0.55000 * pinkB4 + white * 0.5329522
                pinkB5 = -0.7616 * pinkB5 - white * 0.0168980
                let pink = (pinkB0 + pinkB1 + pinkB2 + pinkB3 + pinkB4 + pinkB5 + pinkB6 + white * 0.5362) * 0.11
                pinkB6 = white * 0.115926
                return Float(pink)
            default: return 0
            }
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

            // Detect waveform change and start crossfade
            if waveform != prevWaveform {
                crossfadeRemaining = crossfadeSamples
                prevWaveform = waveform
            }

            let phaseIncrement = Double(freq) / oversampleRate

            for i in 0..<Int(frameCount) {
                // Generate 4 oversampled samples, feed through filter
                for _ in 0..<oversampleFactor {
                    let raw = generateSample(waveform: waveform, phase: phase)

                    // Push into filter ring buffer
                    filterBuf[filterIdx] = raw
                    filterIdx = (filterIdx + 1) % filterLen

                    // Advance phase for tonal waveforms
                    if waveform < 4 {
                        phase += phaseIncrement
                        if phase >= 1.0 { phase -= 1.0 }
                    }
                }

                // Apply FIR filter and decimate (take every 4th sample)
                var acc: Float = 0
                for j in 0..<filterLen {
                    let bufIdx = (filterIdx + j) % filterLen
                    acc += filterBuf[bufIdx] * filterTaps[j]
                }
                let filtered = acc * filterGain

                // Apply crossfade
                let sample: Float
                if crossfadeRemaining > 0 {
                    let t = Float(crossfadeRemaining) / Float(crossfadeSamples)
                    sample = filtered * (1.0 - t)
                    crossfadeRemaining -= 1
                } else {
                    sample = filtered
                }

                buffer[i] = sample * vol
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
