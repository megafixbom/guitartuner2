# ChordPrecision — Real-Time Guitar Tuner Mobile App

ChordPrecision is a high-performance, real-time guitar tuner mobile app built with Flutter. Inspired by the GuitarTuna aesthetic, it features a clean single-screen UI layout, responsive spring-physics needle tracking, and a custom-designed interactive headstock selector.

Under the hood, the app features an optimized digital signal processing (DSP) pipeline that offloads computation from the main UI thread to prevent layout stutter or frame drops.

---

## 🌟 Key Features

*   **GuitarTuna Visual Theme**: Deep charcoal/navy mesh grid background with neon status indicators.
*   **Spring Physics Needle Gauge**: A centering circle needle meter utilizing Flutter's `SpringSimulation` to rotate fluidly instead of jumping abruptly between frequency updates.
*   **Interactive 6-Peg Headstock**: Stylized acoustic peg interface. Pegs dynamically glow orange when active (recognizing sound) and neon green when perfectly in tune.
*   **Auto & Manual Modes**: Automatically locks onto the closest string (E2, A2, D3, G3, B3, E4) or lets the user select a string manually to play reference tones.
*   **Background Isolate Worker**: Offloads the YIN pitch-detection algorithm ($O(W \times N)$ operations) to a separate background Dart Isolate to guarantee 60 FPS main thread rendering.
*   **Zero-Allocation Circular Ring Buffer**: Utilizes a circular float array (`FloatRingBuffer`) to stream PCM microphone data without generating heap memory garbage collection (GC) churn.
*   **Tuning Dead Zone**: Locks the needle to exactly `0.0` cents when within a $\pm1.5$ cents threshold to filter out natural human string tension fluctuations.

---

## 📁 Project Directory Structure

```text
lib/
├── main.dart                          # App entry point & Riverpod ProviderScope setup
├── services/
│   ├── audio_service.dart             # Microphone permission handler & circular ring buffer stream
│   └── pitch_engine.dart              # YIN pitch engine, cents math, noise gate, & EMA smoothing
├── state/
│   └── tuner_state.dart               # Riverpod StateNotifier managing isolate lifecycles & state
└── views/
    ├── tuner_screen.dart              # Main interface, custom grid painter, spring dial, & headstock
test/
└── tuner_test.dart                    # Complete unit test suite verifying DSP and buffer logic
```

---

## 🚀 Setup & Build Instructions

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.0.0)
*   Dart SDK (>= 3.0.0 < 4.0.0)
*   A connected physical mobile device (Android/iOS) or emulator with microphone permissions enabled.

### Local Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/megafixbom/guitartuner2.git
    cd guitartuner2
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Analyze the code for syntax static checks:
    ```bash
    flutter analyze
    ```
4.  Run the test suite:
    ```bash
    flutter test
    ```
5.  Launch the app on your device:
    ```bash
    flutter run
    ```

### Production Build
To compile release binaries:
*   **Android APK**: `flutter build apk --release`
*   **iOS App Store Build**: `flutter build ipa --release`

---

## 🧪 Running Unit Tests
A robust set of tests is located in `test/tuner_test.dart` validating:
*   [FloatRingBuffer] index wrapping, FIFO queue behavior, and memory boundary wrapping.
*   Logarithmic cents deviation conversions ($\pm50$ cents limits).
*   The $\pm1.5$ cents dead-zone lock snapping to center.
*   RMS noise floor thresholds (rejecting room hums under `0.008` RMS).
*   Exponential Moving Average (EMA) smoothing over consecutive buffers.

Run tests using:
```bash
flutter test test/tuner_test.dart
```
