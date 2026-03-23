# Changelog

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
