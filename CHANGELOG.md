# Changelog

## v0.6

- Rename app to "SignalGenerator SG-2400"
- Add "Corvid Audio" branding to footer
- Remove alpha channel from app icons (fixes TestFlight upload)
- Lighten faint UI text for better readability
- Add unit test target with 30 tests (SignalState, WaveformType, FrequencyToNote, AudioParameters, Clamped)

## v0.5

- Move frequency keypad below the CRT display, overlaying the jogwheel area
- CRT display and waveform buttons stay visible during frequency input
- Fixed-height frequency section prevents layout jumping between states

## v0.4

- Fix frequency input keypad overflowing the CRT display
- Add "C" (clear) button to frequency input keypad
- Fix band-limited triangle wave using integrated PolyBLEP'd square wave
- Add MIT license
- Update docs to reflect PolyBLEP anti-aliasing

## v0.3

- PolyBLEP anti-aliasing for square and sawtooth waves (replaced oversampling)
- Frequency snapping to step increment multiples
- Direct frequency input via calculator-style keypad (tap the display)
- Hz and kHz confirm buttons for frequency entry

## v0.2

- Fix audio popping when switching waveform types (256-sample crossfade)
- Fix button styling — active buttons show pressed-in appearance
- Fix power icon rendering
- Add app icon
- Add project documentation

## v0.1

- Initial release
- Sine, square, sawtooth, triangle waveform generation (10 Hz – 20 kHz)
- White and pink noise generation
- Rotary jogwheel with configurable step increments (0.1, 1, 10, 100 Hz)
- CRT-style display with real-time waveform visualization
- Musical note detection with cents offset
- Retro hardware UI inspired by 1970s electronics
