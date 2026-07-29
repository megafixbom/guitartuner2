# Changelog

All notable changes to the GuitarTuner app are documented in this file.

---

## [1.2.0] - 2026-07-29

### Professional Tablature Workspace Overhaul
- **Note Duration System**: Added `NoteDuration` enum (whole, half, quarter, eighth, sixteenth) with beat value calculation. `TabNote` now tracks duration per note. Duration-aware playback highlights notes for their full beat span on the fretboard.
- **Duration-Based Notation Engraving**: `TabNotationPainter` now renders musically correct note heads: open ovals for whole/half notes, filled circles for quarters, flagged stems for eighth/sixteenth notes. Beat subdivision tick marks added to TAB staff.
- **Manual Note Entry**: Tap directly on the score canvas to add notes at quantized 16th-note positions. Tap on the fretboard visualizer to add notes by string/fret position at the current playhead beat.
- **Tap Tempo BPM**: Tap the BPM display to set tempo by tapping rhythm. Calculates rolling average from last 8 taps. BPM +/- 1 buttons for fine adjustment.
- **Note Duration Selector**: Cycle through note durations (1/4, 1/8, 1/16, etc.) via the duration chip button. All manually added notes use the selected duration.
- **Clear Tab Function**: Delete all notes and reset to empty measures with confirmation dialog.
- **UI Professional Redesign**:
  - Compact single-row toolbar with mode pill, BPM control, duration selector, and transport buttons.
  - Pulsing red recording dot with animated transparency.
  - Parchment-toned score canvas (`#FAF8F0`) with authentic paper texture feel.
  - Fretboard now includes string labels (e, B, G, D, A, E) and fret number markers.
  - Refined color palette using slate/cyan/green/red accent system on deep dark background.
  - AppBar consolidated with save/load/loop/clear actions and back navigation.
- **Recording Duration Inference**: Batch recording now infers note durations from the temporal gaps between consecutive detected frequencies.

### State Layer Improvements
- `TabPlayerState` now includes `selectedDuration` and `tapTempoHistory` fields.
- Added methods: `addNoteManually()`, `clearTab()`, `registerTapTempo()`, `cycleSelectedDuration()`, `setSelectedDuration()`, `deleteNoteAt()`.
- `TabNote` serialization includes `duration` field for session persistence.
- Test updated with `NoteDuration` serialization assertion.

---

## [1.1.1] - 2026-07-29

### Guitar Tuner Fixes
- **In-Tune Hold Latch Duration**: Extended from 500ms to 2500ms to match the documented value, providing a smoother and more user-friendly in-tune hold experience.
- **YIN Algorithm Bounds Safety**: Added assertion to verify audio buffer size is sufficient for YIN difference computation, preventing silent out-of-bounds access.
- **In-Tune Comment Consistency**: Fixed conflicting comments across `pitch_engine.dart` regarding the latch duration.

### Tablature Improvements
- **Side-Effect Removal in `build()`**: Moved `_playheadController.duration` setting out of the `build()` method into a tracked `_updatePlayheadDuration()` helper that only updates when BPM or total measures actually change.
- **Standard Notation Y-Position Fix**: Corrected inverted Y-position mapping in `TabNotationPainter` so that higher-pitch strings (String 1, E4) now render near the top of the staff and lower-pitch strings (String 6, E2) render lower, following proper music engraving conventions.
- **Dynamic Measure Rendering**: `TabNotationPainter` now dynamically computes measure widths and barline counts from the actual `measures` list instead of hardcoding 4 measures. Added guard for empty measures.
- **Recording Beat Mapping Fix**: `_processBatchRecordedFrequencies()` now spreads recorded frequency samples across the actual recording duration (in beats at the current BPM) instead of always using a fixed 16-beat spread.
- **Dynamic `seekTo` Clamping**: Playhead position now clamps to `totalMeasures * 4.0` instead of hardcoded `16.0`, supporting variable-length recordings.
- **Proper Timer-Based Recording Clock**: Replaced dead-code `updateRecordingTimer()` setter with a `Timer.periodic` that fires every 100ms during recording, computing elapsed seconds from the actual recording start time.
- **Recording Timer Cleanup**: `toggleLiveMicMode()` and `toggleRecording()` now properly cancel the recording timer. `dispose()` also cancels any active timer.

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
