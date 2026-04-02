# SignalGenerator SG-2400

A precision audio signal generator for iOS with a retro hardware aesthetic.

<p>
  <a href="https://apps.apple.com/us/app/signal-generator-sg-2400/id6761087119">
    <img src="docs/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg" alt="Download on the App Store" height="40">
  </a>
</p>

<p align="center">
  <img src="docs/signalgen-1.png" alt="SignalGenerator SG-2400" width="250">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/signalgen-2.png" alt="SignalGenerator SG-2400 — Frequency Input" width="250">
</p>

## Features

- **Tone generation** — Sine, Square, Sawtooth, and Triangle waveforms from 10 Hz to 20 kHz
- **Noise generation** — White and Pink noise
- **PolyBLEP anti-aliasing** — Band-limited square, sawtooth, and triangle waves for clean output at all frequencies
- **Jogwheel** — Rotary frequency control with configurable step increments (0.1, 1, 10, 100 Hz) and frequency snapping
- **Direct frequency input** — Tap the display readout to type an exact frequency via calculator-style keypad
- **CRT display** — Real-time animated waveform visualization with frequency readout, musical note detection, and volume indicator
- **Crossfade switching** — Seamless transitions between waveform types with no pops or clicks
- **Retro UI** — Inspired by 1970s handheld electronics, TI calculators, and Teenage Engineering

## Requirements

- iOS 17+
- Xcode 16+

## Building

Open `SignalGenerator.xcodeproj` in Xcode, select your target device, and run.

## Architecture

Built with SwiftUI and AVAudioEngine. The audio engine uses an `AVAudioSourceNode` render callback with PolyBLEP anti-aliasing for alias-free synthesis — lowest possible latency with no intermediate buffers.

