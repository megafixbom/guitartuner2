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
* **Parchment White Score Sheet Canvas**:
  * Crisp white sheet music background (`#FFFFFF`) with elevation paper drop shadows.
  * Standard 5-line musical notation staff with properly ordered string mapping (high strings near top of staff, low strings lower).
  * Traditional 6-line guitar TAB staff with vertical **T-A-B** logo, string labels (`e, B, G, D, A, E`), and dynamically computed measure dividers.
  * Fret numbers inside white background cutouts with iconic **Guitar Pro red playhead line & top pointer arrow** (`#EF4444`).
* **15-Fret Rosewood Guitar Visualizer**:
  * Detailed rosewood neck texture with 12-TET logarithmic fret wire scaling, bone nut (`fret 0`), inlay markers, and proportional steel string gauges.
  * Glowing emerald LED finger position badges (`#10B981`) that illuminate dynamically on active notes during playback.
* **Live Mic Recording & Pitch Transcription**:
  * Tactile red glowing **Record Button** (`Icons.fiber_manual_record`), live timer readout (`REC 0.0s`) with a 100ms-resolution recording clock, and a 16-bar animated audio waveform equalizer bar.
  * Automatic note transcription converting raw microphone frequencies ($70\text{ Hz}$ to $400\text{ Hz}$) into exact 6-string guitar coordinates (strings 1–6, frets 0–24), with proper beat-mapping scaled to the actual recording duration.
* **BPM-Synchronized Playback Engine**:
  * Smoothly sweeps the red playhead cursor across the score at exact BPM tempos, triggering PCM reference audio sample tones (`E4`, `B3`, `G3`, `D3`, `A2`, `E2`) sequentially while lighting up fretboard badges.
* **Local Session Persistence & JSON Storage**:
  * Automatic and manual JSON session saving (`recorded_tab_session.json`) via `path_provider` documents storage with **Save** (`Icons.save_alt`) and **Load** (`Icons.folder_open`) actions.

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
├── CHANGELOG.md                       # Comprehensive version changelog (v1.0.0, v1.0.1, v1.1.0)
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
