# Signal Generator for iOS — Requirements

## Overview

A standalone iOS app that generates audio test tones and noise signals with a tactile, retro-instrument UI. The aesthetic blends 1970s handheld electronics (TI calculators, Mattel game handhelds, Commodore) with Teenage Engineering's playful minimalism and color blocking. It should feel like holding a dedicated piece of hardware, not a modern iOS app.

---

## Audio Engine

### Tone Generation
- Frequency range: 10 Hz – 20 kHz
- Waveforms: Sine, Square, Sawtooth, Triangle
- Output must be continuous, glitch-free, and phase-correct when changing frequency or waveform on the fly

### Noise Generation
- White noise (flat spectral density)
- Pink noise (−3 dB/octave rolloff)
- Noise selection replaces the current tone (not layered)

### Anti-Aliasing
- 4x oversampling (192 kHz) with half-band FIR decimation filter
- Eliminates aliasing artifacts on square/saw waves at high frequencies

### Waveform Switching
- Crossfade between waveforms to prevent pops/clicks

### Volume
- Adjustable output level via step-based +/− controls (not a slider)
- Sensible default volume (50%) to avoid blasting the user on first launch

---

## Controls

### Frequency Jogwheel
- Large, prominent jogwheel — the centerpiece of the UI
- Vintage thumb-wheel style with concave thumb indent
- Drag/rotate gesture to sweep frequency; clockwise = higher
- No inertia — direct 1:1 control, stops when you stop
- No indicator mark — clean wheel face

### Step Increment
- Buttons to set the jogwheel's step resolution: **0.1 Hz, 1 Hz, 10 Hz, 100 Hz**
- Active increment uses the unified active button style (off-white)
- Allows coarse sweeping and fine-tuning without mode switching
- Frequency snaps to the nearest step value when changing increments (e.g. 443 Hz snaps to 440 at step 10)

### Direct Frequency Input
- Tap the frequency readout to open a calculator-style numeric keypad
- Number keys 0–9, decimal point, backspace
- **Hz** button confirms the value directly, **kHz** confirms as value × 1000
- ESC cancels and returns to normal display
- Values outside 10–20000 Hz are rejected

### Waveform / Noise Selector
- Dedicated buttons for each type: Sine, Square, Saw, Triangle, White Noise, Pink Noise
- One active at a time; active button uses the unified active style (off-white with dark text)
- Switching waveform mid-tone should be seamless (no pop/click)

### Volume
- Dedicated **+** / **−** buttons
- Volume shown as 0–100% in the display (no separate meter)

### Power
- Power toggle button (red when active)
- Turns display and signal on/off

---

## Display

The display uses a **CRT / vector display** aesthetic — dark screen with scanlines, subtle curvature highlight, and a faint grid overlay.

### Frequency Readout
- Numeric display of current frequency (e.g., `440 Hz` / `1.20 kHz`)
- Monospaced font (Space Mono) in amber
- Nearest musical note shown below (e.g., `A4`, `C#3 +12¢`) in teal

### Volume Readout
- Volume percentage displayed (e.g., `VOL 50%`)

### Active Waveform Label
- Current waveform name shown (e.g., `SINE`, `TRI`, `WHITE`)

### Waveform Visualization
- Animated, real-time rendering of the active waveform
- Waveform shape reflects the selected type (sine, square, saw, triangle, noise)
- Number of visible cycles scales with frequency (fewer at low, more at high)
- Teal waveform trace with soft glow, matching the display color scheme

---

## UI / Visual Design

### Aesthetic Direction
- **Dark grey plastic chassis** — cool neutral dark grey
- **Recessed grooves** between sections like injection-molded panel divisions
- **Embossed labels** stamped into the plastic surface
- Key references:
  - 1972 TI Datamath calculator — chunky buttons, textured surfaces, handheld form factor
  - Teenage Engineering KO II — playful minimalism, bold typography, color blocking
  - BK Precision signal generators — utilitarian instrument aesthetic

### Color Palette
- Chassis: dark grey (#2a2a2c range)
- Display: dark screen with teal waveform and grid, amber frequency readout
- Header bar: teal color block
- Buttons (inactive): medium grey (#484848), brighter than chassis
- Buttons (active): off-white/cream (#d8d0c8) with dark text, pressed-in appearance
- Power button: red when active

### Buttons
- Chunky, rounded (8px radius), physical press-depth via shadow
- 3D appearance: bottom shadow for depth
- Press animation: translateY + shadow reduction
- Active state: pressed-in (offset down, no shadow)
- All buttons share the same inactive/active style — no per-button colors

### Layout
- **Portrait only**, single-screen — everything accessible without navigation
- Top to bottom: teal header bar → CRT display → waveform buttons (3×2 grid) → groove divider → jogwheel (left) + step/volume controls (right) → groove divider → power toggle → footer

---

## Platform & Technical

- **iOS only** (iPhone primary, iPad supported)
- Swift / SwiftUI
- Audio framework: AVAudioEngine with AVAudioSourceNode
- No network access required — fully offline
- Target: iOS 17+

---

## Resolved Questions

- **Dial behavior:** Direct control, no inertia
- **Mute button:** Not needed — volume-down-to-zero is sufficient
- **Haptic feedback:** No
- **Volume display:** Show as 0–100% in the display
- **Presets / musical notes:** Show the nearest musical note with cents offset in the display
- **Orientation:** Portrait only
