# Changelog

All notable changes to the GuitarTuner app are documented in this file.

---

## [1.1.0] - 2026-07-28

### 🎼 Interactive Guitar Pro Tab Workspace (`tab_player_screen.dart`)
- **Parchment White Score Sheet Canvas**:
  - Rendered a pure white sheet music background (`#FFFFFF`) with subtle elevation paper drop shadows.
  - Standard 5-line musical notation staff with a bold black treble clef (`🎼`).
  - Traditional 6-line guitar TAB staff with vertical **T-A-B** logo and string labels (`e, B, G, D, A, E`).
  - Measure index numbers (`1, 2, 3, 4`) and black fret numbers inside white background cutouts.
  - Iconic **Guitar Pro red playhead line & top pointer arrow** (`#EF4444`).
- **15-Fret Rosewood Guitar Visualizer**:
  - Detailed rosewood neck texture with 12-TET logarithmic fret wire scaling, bone nut (`fret 0`), inlay markers, and proportional steel string gauges.
  - Glowing emerald LED finger position badges (`#10B981`) that light up dynamically on active notes.
- **Recording & Capture Pipeline**:
  - Tactile red glowing **Record Button** (`Icons.fiber_manual_record`), live timer readout (`REC 0.0s`), and a 16-bar animated audio waveform equalizer bar.
  - Automatic note transcription converting raw microphone frequencies ($70\text{ Hz}$ to $400\text{ Hz}$) into exact 6-string guitar coordinates (strings 1–6, frets 0–24).
- **BPM-Synchronized Playback Engine**:
  - Smoothly sweeps the red playhead cursor across the score at exact BPM tempos, triggering PCM reference audio sample tones (`E4`, `B3`, `G3`, `D3`, `A2`, `E2`) sequentially.
- **Local Session Persistence & JSON Serialization**:
  - Automatic and manual JSON session saving (`recorded_tab_session.json`) via `path_provider` documents storage with **Save** (`Icons.save_alt`) and **Load** (`Icons.folder_open`) actions.
- **Performance & Code Quality Optimizations**:
  - Added sub-beat position delta thresholding `(position - state.playheadPosition).abs() >= 0.02` to prevent 60 FPS widget rebuild churn.
  - Added `@override void dispose()` to `TabPlayerNotifier` to clean up `AudioPlayer` resources.
  - Automatic loop pass resetting for audio note triggers.
- **Automated Test Coverage**:
  - Added `TabNote` and `TabMeasure` JSON serialization unit tests (`15/15 tests passed`).
- **Release APK**:
  - Compiled release APK at `build/app/outputs/flutter-apk/app-release.apk` (45.7 MB).

---

## [1.0.1] - 2026-07-28

### 🎵 Pitch Engine & Audio Processing Fixes
- **Disabled Hardware Audio Artifacts**: Turned off Android hardware `autoGain`, `echoCancel`, and `noiseSuppress` in `RecordConfig`. This prevents the phone's native hardware noise processing from distorting sound waves and causing pitch readings to register as "Too Sharp" when playing external synthetic or guitar reference tones.
- **Lowered Noise Gate & Confidence Thresholds**:
  - Lowered `noiseFloorRms` to `0.003` to allow accurate detection of quiet/distant string tones.
  - Adjusted YIN pitch confidence threshold (`minConfidence`) to `0.70` for smoother detection of synthetic reference tones.
  - Increased Exponential Moving Average smoothing (`emaAlpha`) to `0.40` for faster gauge needle response.
- **Restored Sleek Headstock Layout**: Restored the original vertical vector acoustic headstock layout.
- **Hardware LED Dotted Sound Level Meter**: Added a 12-dot glowing hardware LED sound level meter directly **below the guitar headstock**, displaying real-time LUFS and dBFS sound intensity with green, amber, and red clipping indicator LEDs.
- **Strict Vocal & Speech Gating**: Raised noise floor (`rms = 0.015`), required strict pitch confidence (`minConfidence = 0.90`), and tightened string cents deviation windows (`75 cents` in AUTO, `100 cents` in MANUAL) to eliminate stray voice pickups.

### 🛠️ Android & Build Pipeline
- **Updated Dependencies**: Upgraded `audioplayers`, `permission_handler`, `path_provider`, `record`, and `vibration` in `pubspec.yaml` to ensure full compatibility with Flutter 3.x v2 Android embedding.
- **Fresh Android Platform Structure**: Regenerated modern Gradle Kotlin configurations (`build.gradle.kts` & `settings.gradle.kts`).
- **APK Generation**: Built release APK output at `build/app/outputs/flutter-apk/app-release.apk` (42.8 MB).

---

## [1.0.0] - Initial Release
- Premium GuitarTuna clone with real-time tuner gauge, auto string selection, reference tone player, and haptic feedback.
