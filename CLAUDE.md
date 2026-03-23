# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

This is a SwiftUI iOS app. Build and run via Xcode (SignalGenerator.xcodeproj, scheme: SignalGenerator). The project uses Xcode's file system synchronization — adding Swift files to the SignalGenerator/ directory automatically includes them in the build.

If `xcodebuild` fails with "active developer directory is command line tools", run:
```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Architecture

Single-screen signal generator app: generates audio tones (sine, square, saw, triangle) and noise (white, pink) from 10 Hz to 20 kHz.

### Audio Engine (Audio/AudioEngine.swift)

`AVAudioEngine` with `AVAudioSourceNode` render callback for direct sample-level synthesis. All waveform types are generated in a single render callback switch statement (no separate ToneGenerator/NoiseGenerator files despite what docs/Design.md says).

**Critical constraint**: The render callback runs on a real-time audio thread. No allocations, no locks, no ObjC. Parameters are bridged from the main thread via `AudioParameters`, a class using naturally-aligned 32-bit loads/stores for thread safety.

The signal chain is: `AVAudioSourceNode → AVAudioMixerNode → AVAudioOutputNode`.

### State Management

`SignalState` (Models/SignalState.swift) is the single `@Observable` source of truth. `ContentView` owns it and passes it down. State changes propagate to the audio engine via `.onChange` modifiers that call `audioEngine.update(state:)`.

### Key Types

- `WaveformType` — `Int32` enum (rawValue maps directly to the render callback's switch cases)
- `AudioParameters` — `@unchecked Sendable` bridge between main thread and audio thread
- `ChunkyButtonStyle` — custom `ButtonStyle` with 3D press effect, used via `.chunkyButtonStyle(isActive:)` modifier

### UI Structure

`ContentView` assembles the full layout top-to-bottom: HeaderBar → DisplayView (CRT-style with Canvas waveform + readout) → WaveformButtons (3x2 grid) → Jogwheel + Step/Volume controls → PowerView. All colors and fonts come from `Theme` enum.

### Custom Fonts

Four bundled fonts registered in Info.plist (without `Fonts/` prefix — Xcode copies resources flat to bundle root): SpaceMono-Regular, SpaceMono-Bold, Anybody-Bold, Anybody-ExtraBold. Referenced via `Theme.mono()`, `Theme.monoBold()`, `Theme.display()`, `Theme.displayHeavy()`.

## Design References

`docs/Requirements.md` has the full spec. `docs/Design.md` has the technical design and build phases. `docs/Idea.md` has the original concept. When in doubt, these are authoritative.
