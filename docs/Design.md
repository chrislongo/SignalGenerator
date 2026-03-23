# Signal Generator — Technical Design

## Architecture

Single-screen SwiftUI app with a clean separation between audio synthesis, UI state, and visual rendering.

```
SignalGenerator/
├── App/
│   └── SignalGeneratorApp.swift          # App entry point
├── Audio/
│   ├── AudioEngine.swift                 # AVAudioEngine setup, node graph, start/stop
│   ├── ToneGenerator.swift               # Waveform synthesis via AVAudioSourceNode
│   └── NoiseGenerator.swift              # White/pink noise synthesis
├── Models/
│   ├── SignalState.swift                  # Observable app state (freq, waveform, vol, power)
│   └── WaveformType.swift                # Enum: sine, square, saw, triangle, white, pink
├── Views/
│   ├── ContentView.swift                 # Root layout — assembles all sections
│   ├── Display/
│   │   ├── DisplayView.swift             # CRT display container (bezel, scanlines, grid)
│   │   ├── WaveformCanvasView.swift      # Real-time waveform rendering via Canvas
│   │   └── ReadoutView.swift             # Frequency, note, volume, waveform label
│   ├── Controls/
│   │   ├── JogwheelView.swift            # Rotary jogwheel with inertia
│   │   ├── WaveformButtonsView.swift     # 3×2 waveform/noise selector grid
│   │   ├── StepButtonsView.swift         # Step increment selector
│   │   └── VolumeButtonsView.swift       # +/− volume controls
│   ├── Components/
│   │   ├── ChunkyButton.swift            # Reusable button with 3D press style
│   │   ├── GrooveDivider.swift           # Recessed panel divider line
│   │   └── HeaderBar.swift               # Teal header with brand/model
│   └── PowerView.swift                   # Power toggle + output jack
├── Utilities/
│   ├── FrequencyToNote.swift             # Frequency → musical note + cents conversion
│   └── Theme.swift                       # Color palette, fonts, shared constants
└── Resources/
    └── Assets.xcassets                   # App icon, accent color
```

---

## Audio Engine

### Approach: AVAudioSourceNode

Use `AVAudioEngine` with an `AVAudioSourceNode` that supplies raw PCM samples via a render callback. This gives us direct sample-level control at the hardware buffer level — lowest possible latency, no intermediate buffers.

```
AVAudioSourceNode (render callback) → AVAudioMixerNode (volume) → AVAudioOutputNode (speakers)
```

### Why AVAudioSourceNode over alternatives

| Approach | Latency | Control | Complexity |
|----------|---------|---------|------------|
| AVAudioPlayerNode + buffers | Medium | Scheduling buffers, gaps possible | Medium |
| AVAudioSourceNode callback | **Lowest** | **Direct sample generation** | Low |
| AudioUnit (C API) | Lowest | Direct | High (C/ObjC interop) |
| AVTonePlayerNode (doesn't exist) | — | — | — |

AVAudioSourceNode is the sweet spot: Audio Unit-level performance with a Swift-friendly API. Introduced in iOS 13.

### Render Callback

The callback runs on a real-time audio thread. Rules:
- **No allocations** — no `Array`, `String`, or any heap allocation
- **No locks** — no `DispatchSemaphore`, `NSLock`, `os_unfair_lock`
- **No Objective-C** — no message sends, no `@objc` calls
- Read parameters via atomics (`Atomic<Float>`, `Atomic<Int>`)

```swift
// Pseudocode for the render block
sourceNode = AVAudioSourceNode { _, _, frameCount, bufferList -> OSStatus in
    let freq = currentFrequency.load(ordering: .relaxed)
    let type = currentWaveform.load(ordering: .relaxed)
    let vol  = currentVolume.load(ordering: .relaxed)

    let buffer = UnsafeMutableBufferPointer(bufferList.pointee.mBuffers)
    let phaseInc = freq / sampleRate

    for frame in 0..<Int(frameCount) {
        let sample = waveformSample(type: type, phase: phase) * vol
        buffer[frame] = sample
        phase += phaseInc
        if phase >= 1.0 { phase -= 1.0 }
    }
    return noErr
}
```

### Waveform Math

All waveforms computed from a normalized phase `p` in `[0, 1)`:

| Waveform | Formula |
|----------|---------|
| Sine | `sin(2π * p)` |
| Square | `p < 0.5 ? 1.0 : -1.0` (with band-limiting for anti-aliasing) |
| Sawtooth | `2.0 * p - 1.0` |
| Triangle | `4.0 * abs(p - 0.5) - 1.0` |
| White noise | `Float.random(in: -1...1)` per sample |
| Pink noise | Voss-McCartney algorithm (summed octave-band random values) |

### Seamless Waveform Switching

When the user changes waveform type, don't reset the phase — just change the waveform function on the next sample. Since we use a continuous phase accumulator, this avoids pops. For noise → tone transitions, reset phase to 0 (noise doesn't use phase).

### Volume

Volume is applied as a linear multiplier in the render callback (`sample * volume`). The `AVAudioMixerNode` could also handle this, but applying it at the source keeps everything in one place and avoids the extra node's latency.

Volume steps: 0% to 100% in 10% increments (11 levels). Default: 50%.

---

## State Management

### SignalState (ObservableObject)

Single source of truth, observed by all views:

```swift
@Observable
class SignalState {
    var frequency: Double = 440.0      // 10...20000
    var waveform: WaveformType = .sine
    var stepIncrement: Double = 1.0     // 0.1, 1, 10, 100
    var volume: Int = 5                 // 0...10 (maps to 0%...100%)
    var isPlaying: Bool = true

    var volumePercent: Int { volume * 10 }
    var musicalNote: String { FrequencyToNote.convert(frequency) }
}
```

Uses Swift 5.9 `@Observable` macro (iOS 17+) — cleaner than `ObservableObject`/`@Published`, automatic fine-grained view updates.

### Audio Thread Communication

The `SignalState` lives on the main thread. The audio render callback runs on a real-time thread. Bridge them with Swift Atomics:

```swift
// Updated from main thread whenever SignalState changes
let atomicFrequency = ManagedAtomic<Float>(440.0)
let atomicWaveform = ManagedAtomic<Int>(0)
let atomicVolume = ManagedAtomic<Float>(0.5)
```

Use `.relaxed` ordering — we don't need strict ordering guarantees, just eventual visibility. A one-frame delay (5ms at 48kHz/256 buffer) is imperceptible.

---

## Jogwheel

### Gesture Handling

The jogwheel uses a `DragGesture` mapped to angular rotation:

1. On drag start: record initial touch angle relative to wheel center
2. On drag change: compute angular delta, apply frequency change scaled by step increment
3. On drag end: capture angular velocity, start inertial decay

### Inertia

```swift
// On release, start a DisplayLink-driven decay
angularVelocity = lastDelta / lastDeltaTime
Timer.publish(every: 1/60) { ... }
    angularVelocity *= 0.94  // friction
    frequency += angularVelocity * stepIncrement * sensitivity
    if abs(angularVelocity) < threshold { stop }
```

### Visual Rotation

The wheel face rotates via `.rotationEffect()`. The thumb indent and knurling rotate with it since they're part of the same view. No indicator mark to track.

---

## Display Rendering

### Waveform Visualization (Canvas)

Use SwiftUI `Canvas` view with a `TimelineView(.animation)` to drive 60fps updates:

```swift
TimelineView(.animation) { timeline in
    Canvas { context, size in
        // Draw grid lines
        // Draw waveform path based on current waveform type + frequency
        // Apply glow effect (draw twice: once thick/transparent, once thin/opaque)
    }
}
```

The waveform draws a `Path` based on the same math as the audio engine (sine, square, etc.) but for display purposes only — not reading from the actual audio buffer. Number of visible cycles scales: `clamp(frequency / 80, 1.5, 12)`.

### CRT Effects

All done with SwiftUI modifiers, no shaders needed:
- **Scanlines**: Horizontal striped overlay (`Rectangle` with repeating gradient in an `overlay`)
- **Screen curvature highlight**: Radial gradient positioned top-left
- **Grid**: Drawn in the Canvas as thin lines
- **Bezel**: `RoundedRectangle` with inner shadow and dark border
- **Glow on waveform**: Double-draw technique (thick transparent pass + thin opaque pass)

### Color Scheme

- Waveform trace: teal (`#48c8d8`) with soft glow
- Grid lines: teal at ~5% opacity
- Frequency readout: amber (`#f0982c`)
- Note + waveform label: teal
- Volume: amber at reduced opacity

---

## Component: ChunkyButton

Reusable across all button groups. Encapsulates the 3D press style:

```swift
struct ChunkyButton<Label: View>: View {
    let isActive: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
        }
        .background(isActive ? Color.cream : Color.buttonFace)
        .foregroundStyle(isActive ? Color.dark : Color.lightText)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.25), radius: 0, y: 3)  // depth shadow
        // Press state handled via ButtonStyle
    }
}
```

Custom `ButtonStyle` handles the press animation (translateY + shadow reduction).

---

## Theme

Centralized in `Theme.swift`:

```swift
enum Theme {
    // Chassis
    static let body = Color(hex: "#2a2a2c")
    static let bodyLight = Color(hex: "#383838")
    static let bodyLighter = Color(hex: "#484848")
    static let bodyDark = Color(hex: "#1a1a1c")

    // Accents
    static let teal = Color(hex: "#38a8a0")
    static let red = Color(hex: "#d03828")
    static let amber = Color(hex: "#f0982c")
    static let crtTeal = Color(hex: "#48c8d8")

    // Buttons
    static let buttonFace = Color(hex: "#484848")
    static let buttonActive = Color(hex: "#d8d0c8")

    // Fonts
    static let mono = Font.custom("SpaceMono-Bold", size: 13)
    static let display = Font.custom("SpaceMono-Bold", size: 34)
}
```

Bundle Space Mono and Anybody fonts as custom fonts in the app.

---

## Build Phases

### Phase 1 — Audio engine + minimal UI
- AVAudioEngine setup with AVAudioSourceNode
- All 6 waveform/noise types working
- Basic SwiftUI controls (buttons, frequency display)
- Volume control
- Verify glitch-free playback and seamless waveform switching

### Phase 2 — Jogwheel
- Rotary gesture with angular tracking
- Frequency stepping tied to step increment
- Inertial spin with friction decay

### Phase 3 — Display
- Canvas waveform visualization at 60fps
- CRT effects (scanlines, glow, grid, bezel)
- Frequency readout, musical note, volume percentage

### Phase 4 — Visual polish
- Full retro theme: dark grey chassis, textures, grooves
- ChunkyButton with 3D press animation
- Header bar, power button, footer
- Custom bundled fonts

### Phase 5 — Finishing
- Light mode support
- iPad layout adaptation
- App icon
- Performance profiling (audio thread, Canvas frame rate)
