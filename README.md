# GuitarTuner — Professional Real-Time Tuner & Guitar Pro Tab Workspace

GuitarTuner is a high-performance, professional mobile application built with Flutter & Riverpod. It combines a **GuitarTuna-inspired real-time guitar tuner** with an **interactive Guitar Pro-style TAB player, live recorder, score sheet generator, and audio synthesizer**.

Under the hood, the app features an optimized digital signal processing (DSP) pipeline that offloads computation from the main UI thread to a background Dart Isolate to guarantee a smooth 60 FPS rendering experience.

---

## 🌟 Key Features

### 🎸 1. Real-Time Precision Guitar Tuner
* **GuitarTuna Dark Theme**: Deep charcoal/navy mesh grid with high-contrast glowing status indicators.
* **Spring Physics Needle Gauge**: Smooth centering dial utilizing Flutter's `SpringSimulation` to eliminate erratic needle jump.
* **Interactive Headstock & LED Level Meter**: Stylized acoustic headstock interface coupled with a 12-dot hardware LED audio level meter showing real-time LUFS and dBFS sound intensity below the headstock.
* **Isolate Worker & Ring Buffer**: YIN pitch-detection engine runs inside a dedicated background Dart Isolate fed by a zero-allocation circular `FloatRingBuffer`.
* **Hardware Noise Gating**: Disables hardware AGC/echo cancellation artifacts to ensure pure tone readings with strict vocal gating and $\pm3.5$ cents dead-zone locking with a 2.5-second in-tune hold latch for smooth user feedback.

### 🎼 2. Guitar Pro-Style Interactive Tab Workspace (`TabPlayerScreen`)
* **Professional Parchment Score Sheet**:
  * Warm parchment-toned canvas (`#FAF8F0`) with authentic paper feel and subtle drop shadows.
  * Standard 5-line musical notation staff with duration-aware note engraving (open heads for whole/half, filled for quarters, flagged for eighth/sixteenth).
  * Traditional 6-line guitar TAB staff with vertical **T-A-B** logo, string labels (`e, B, G, D, A, E`), dynamically computed measure dividers, and beat subdivision ticks.
  * Fret numbers inside white cutouts with **Guitar Pro red playhead line & top pointer arrow** (`#EF4444`).
* **Manual Note Entry & Editing**:
  * Tap on the score canvas to add notes at quantized 16th-note positions with the currently selected note duration.
  * Tap on the fretboard visualizer to place notes by string and fret position.
  * Note duration selector cycling through whole, half, quarter, eighth, and sixteenth notes.
  * Articulation selector for slides (`/`), hammer-ons (`h`), pull-offs (`p`), bends (`b`), release, and vibrato (`~`). Articulation symbols rendered inline on TAB staff with connector curves and slur arcs in standard notation.
* **15-Fret Rosewood Guitar Visualizer**:
  * Detailed rosewood neck texture with 12-TET logarithmic fret wire scaling, bone nut, inlay markers (single + double at 12th), and proportional steel string gauges.
  * String labels (`e, B, G, D, A, E`) on nut area and fret number markers along the bottom.
  * Glowing emerald LED finger position badges (`#10B981`) that illuminate during playback for the full note duration span.
* **Tap Tempo & BPM Control**:
  * Tap the BPM readout to set tempo by rhythm; calculates rolling average from last 8 taps.
  * Fine-tune with +/- 1 BPM buttons. Range: 40-280 BPM.
* **Live Mic Recording & Pitch Transcription**:
  * Tactile red glowing **Record Button** with pulsing animated indicator, live timer readout with 100ms clock, and a 12-bar waveform visualizer.
  * Automatic note transcription with duration inference from temporal gaps between detected frequencies.
  * Batch recording processes all samples at stop and generates measures dynamically.
  * **Ghost/Muted Note Detection**: Transient attacks without a stable pitch (palm mutes, percussive rakes) are captured as ghost notes with "X" notation on the TAB staff and amber fretboard badges.
* **BPM-Synchronized Playback Engine**:
  * Smoothly sweeps the red playhead cursor across the score at exact BPM tempos, triggering PCM reference audio samples (`E4`, `B3`, `G3`, `D3`, `A2`, `E2`) while lighting up fretboard badges with duration-aware highlighting.
* **Local Session Persistence & JSON Storage**:
  * Automatic and manual JSON session saving (`recorded_tab_session.json`) via `path_provider` with full note duration serialization.
* **Clear Tab**: Reset the entire tab to empty measures with confirmation dialog.

---

## 📁 Updated Project Directory Structure

```text
guitartuner2/
├── android/                           # Modern Gradle Kotlin build configuration (v2 embedding)
├── assets/
│   ├── images/
│   │   └── acoustic_headstock.jpg     # Acoustic guitar visual reference asset
│   └── sounds/
│       ├── A2.wav, B3.wav, D3.wav     # High-fidelity PCM guitar string audio samples
│       ├── E2.wav, E4.wav, G3.wav     # Reference tuning & synthesizer audio samples
│       └── in_tune_chime.wav          # In-tune audio completion chime
├── lib/
│   ├── main.dart                      # App entry point & Riverpod ProviderScope initialization
│   ├── services/
│   │   ├── audio_service.dart         # Microphone permission handler & circular ring buffer stream
│   │   ├── pitch_detector.dart        # YIN Pitch detection algorithm implementation
│   │   └── pitch_engine.dart          # YIN pitch engine, cents math, noise gate, & EMA smoothing
│   ├── state/
│   │   ├── tab_player_state.dart      # Tab player state model, transcription mapper & JSON storage
│   │   └── tuner_state.dart           # Riverpod StateNotifier managing isolate lifecycles & state
│   └── views/
│       ├── tab_player_screen.dart     # Guitar Pro tab score, 15-fret visualizer & recorder controls
│       └── tuner_screen.dart          # Main tuner interface, spring dial & LED sound meter
├── test/
│   ├── tuner_test.dart                # Complete DSP, FloatRingBuffer & JSON serialization unit tests
│   └── widget_test.dart               # Flutter smoke and widget integration tests
├── CHANGELOG.md                       # Comprehensive version changelog (v1.0.0 - v1.3.0)
└── README.md                          # Project documentation and setup guide
```

---

## 🚀 Setup & Build Instructions

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.0.0)
* Dart SDK (>= 3.0.0 < 4.0.0)
* Connected Android/iOS physical device or emulator with microphone access enabled.

### Local Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/megafixbom/guitartuner2.git
   cd guitartuner2
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Analyze code for static quality checks:
   ```bash
   flutter analyze
   ```
4. Run automated test suite:
   ```bash
   flutter test
   ```
5. Launch the app:
   ```bash
   flutter run
   ```

### Production Build
To compile release binaries:
* **Android Release APK**: `flutter build apk --release --no-tree-shake-icons`
* **Output Path**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Running Unit Tests
The unit test suite in `test/tuner_test.dart` verifies:
* `FloatRingBuffer` circular queue boundaries and zero-allocation memory wrapping.
* Logarithmic cents deviation calculations and $\pm1.5$ cents dead-zone locking.
* PitchEngine YIN frequency detection and RMS noise floor gating.
* Exponential Moving Average (EMA) smoothing.
* `TabNote` and `TabMeasure` JSON serialization/deserialization.

Run all tests using:
```bash
flutter test
```

---

## 📚 Documentation

Comprehensive documentation available in multiple formats:

| Document | Markdown | PDF | Word |
|----------|----------|-----|------|
| **User Guide** | [View](docs/USER_GUIDE_WITH_SCREENSHOTS.md) | [Download](docs/pdf/USER_GUIDE_WITH_SCREENSHOTS.pdf) | [Download](docs/docx/USER_GUIDE_WITH_SCREENSHOTS.docx) |
| **BPM Detection** | [View](BPM_DETECTION_GUIDE.md) | [Download](docs/pdf/BPM_DETECTION_GUIDE.pdf) | [Download](docs/docx/BPM_DETECTION_GUIDE.docx) |
| **Chord Detection** | [View](CHORD_DETECTION_GUIDE.md) | [Download](docs/pdf/CHORD_DETECTION_GUIDE.pdf) | [Download](docs/docx/CHORD_DETECTION_GUIDE.docx) |
| **Implementation Status** | [View](IMPLEMENTATION_STATUS.md) | [Download](docs/pdf/IMPLEMENTATION_STATUS.pdf) | [Download](docs/docx/IMPLEMENTATION_STATUS.docx) |

### Screenshot Capture Status

**📸 In Progress:** 10/30 screenshots captured

See [docs/SCREENSHOT_GUIDE.md](docs/SCREENSHOT_GUIDE.md) for detailed capture instructions.

**To generate PDF/DOCX from markdown:**
```bash
cd docs/scripts
chmod +x *.sh
./convert_to_pdf.sh    # Requires: pandoc
./convert_to_docx.sh   # Requires: pandoc
```

**Requirements:**
- `pandoc` (install: `brew install pandoc`)
- `wkhtmltopdf` (optional, for better PDF quality: `brew install wkhtmltopdf`)
