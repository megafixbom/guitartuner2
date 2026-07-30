# Changelog

All notable changes to the GuitarTuner app are documented in this file.

---

## [1.6.0] — 2026-07-30

### Multi-Pitch Chord Detection
- **ChordDetector Service**: New `lib/services/chord_detector.dart` implements polyphonic chord recognition from audio input.
- **Unified Recording**: Single audio buffer feeds all detection systems (key, tempo, chords) - **NOT separate recordings**.
- **Spectral Peak Detection**: Finds 2-6 simultaneous frequency peaks using magnitude spectrum analysis.
- **Pitch Class Extraction**: Converts detected frequencies to chroma (12 pitch classes).
- **Chord Template Matching**: Compares pitch classes against 12 chord templates:
  - Triads: Major, Minor, Diminished, Augmented, Sus2, Sus4
  - Sevenths: Dom7, Maj7, Min7, Dim7
  - Extended: Add9, mAdd9
- **Jaccard Similarity Scoring**: Computes intersection/union between observed and template pitch classes.
- **Temporal Smoothing**: Removes outlier chords by comparing with neighbors (hysteresis filtering).
- **Voicing Estimation**: Calculates fret position from lowest detected frequency (bass note).
- **Chord Progression Display**: Renders chord names in blue pill boxes above notation staff.
- **Confidence Threshold**: >0.5 required for chord acceptance.
- **Root Position Ambiguity**: Tests all 12 transpositions to find best match.
- **State Integration**: `TabPlayerState.detectedChords` stores list of DetectedChord with timestamps.

### Technical Details
- **FFT Frame Size**: 4096 samples (136ms at 32kHz equivalent)
- **Hop Size**: 2048 samples (50% overlap)
- **Peak Picking**: 20Hz minimum separation between candidates
- **Frequency Range**: 80-400Hz (matches guitar standard tuning range)
- **Max Polyphony**: 6 notes (guitar strings)
- **Smoothing Window**: Compares with previous chord in progression
- **Display**: Blue pills (#3B82F6) positioned above each measure's detected chord

---

## [Future] — TODO

### v1.7.0: Smart Metronome
- [ ] Click track synced to detected beat grid (from tempo_detector)
- [ ] Subdivision options (quarter, eighth, sixteenth)
- [ ] Accent on beat 1 (downbeat emphasis)
- [ ] Sound selector (woodblock, beep, stick)
- [ ] Volume control

### v1.8.0: Scale Detection for Lead Sections
- [ ] Analyze monophonic passages for scale patterns
- [ ] Detect: major, minor, pentatonic, blues, modes (Dorian, Phrygian, etc.)
- [ ] Display "Scale: A Minor Pentatonic" overlay in toolbar
- [ ] Color-code notes on fretboard (green = scale tone, red = non-scale)
- [ ] Suggest compatible scales for detected chord progression
- [ ] Arpeggio detection (outline chord tones in lead playing)

### v1.9.0: Pitch Shifting / Key Transposition
- [ ] Phase vocoder implementation
- [ ] Transpose ±12 semitones without tempo change
- [ ] Preserve formants (natural timbre)
- [ ] Transpose entire recording or real-time monitoring

### v2.0.0: Lyric Transcription
- [ ] Whisper API / Google Speech-to-Text integration
- [ ] Vocal detection (separate from guitar)
- [ ] Timestamp-aligned lyrics
- [ ] Karaoke-style highlighting during playback
- [ ] Export as LRC file

---

## [1.5.0] — 2026-07-30

### Automatic BPM Detection
- **TempoDetector Service**: New `lib/services/tempo_detector.dart` implements automatic tempo detection using onset detection and IOI (inter-onset interval) histogram analysis.
- **Spectral Flux Onset Detection**: Computes energy change between consecutive audio frames to detect note attacks and transients.
- **IOI Histogram**: Builds histogram of time intervals between detected onsets, finds peaks corresponding to tempo candidates.
- **Tempo Candidates**: Considers base tempo plus octave ambiguities (2x, 0.5x) to resolve half-time/double-time confusion.
- **Beat Grid Generation**: Outputs synchronized beat timestamps for metronome integration.
- **Audio Sample Buffer**: Records RMS levels at 100Hz during capture (max 30,000 samples = 5 minutes).
- **BPM Range**: Detects 60-200 BPM with confidence threshold >0.4.
- **UI Integration**: 
  - BPM display shows green highlight + auto icon (✨) when tempo is auto-detected
  - Tapping BPM display clears auto-tempo and reverts to manual tap tempo
  - BPM +/- buttons still work for fine-tuning detected tempo
- **State Integration**: `TabPlayerState.detectedTempo` field stores DetectedTempo object with bpm, beats array, time signature, and confidence.

### Technical Details
- **Onset Detection Function (ODF)**: Spectral flux with adaptive threshold (mean + 0.5*stddev)
- **Peak Picking**: Non-maximum suppression with 100ms minimum inter-onset gap
- **IOI Filtering**: Only considers intervals valid for 60-200 BPM range (0.3s - 1.0s)
- **Histogram Bin Width**: 50ms bins for tempo candidate extraction
- **Confidence Metric**: Ratio of onsets supporting the detected tempo vs total onsets

---

## [1.4.0] — 2026-07-30

### Automatic Musical Key Detection
- **Pitch Class Histogram**: Builds a 12-bin pitch class distribution from all recorded notes, counting occurrences of each chromatic pitch (C, C#, D, D#... B).
- **Key Detection Algorithm**: Uses Krumhansl-Schmiedler major and minor key profiles to score each possible key. Compares observed pitch class distribution against the expected distribution for all 24 keys (12 major + 12 minor).
- **`MusicalKey` Enum**: Added enum with 12 chromatic keys (C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B) and `displayName` getter.
- **`KeyMode` Enum**: Added major/minor mode enum.
- **`DetectedKey` Class**: Contains `tonic` (MusicalKey), `mode` (KeyMode), `confidence` (0.0-1.0), and `pitchClassHistogram`. Includes `displayName` getter (e.g., "Em", "G Major") and `accidentals` list.
- **Key Signature Rendering**: `TabNotationPainter._drawKeySignature()` draws sharps (#) or flats (b) at the beginning of the standard notation staff, following standard music engraving conventions.
- **Toolbar Key Chip**: displays detected key with confidence percentage (e.g., "Em (75)"), color-coded by confidence (green >70%, amber >50%, otherwise muted).

### State Layer
- `TabPlayerState.detectedKey` field stores the automatically detected key after recording.
- `_detectMusicalKey()` method builds pitch class histogram from recorded notes and scores all 24 keys.
- `_calculateKeyFit()` computes dot product between observed and expected pitch class distributions.
- `_frequencyToPitchClass()` converts frequency to MIDI note then to pitch class (0-11).

### UI Layer
- `_keyChip()` widget displays detected key in toolbar with key icon, name, and confidence percentage.
- `TabNotationPainter.detectedKey` parameter enables key signature rendering on score canvas.

### Technical Details
- **Profile Source**: Major/minor key profiles based on Krumhansl-Schmiedler (1982) probe-tone ratings.
- **Minimum Confidence**: Keys with confidence < 0.3 are not displayed (indicating ambiguous or non-diatonic material).
- **Accidental Calculation**: `DetectedKey.accidentals` getter maps relative tonic to circle of fifths position and returns list of pitch classes to alter (sharps or flats).

---

## [1.3.0] - 2026-07-29

### Articulation Symbols & Connectors
- **Articulation Enum**: Added `Articulation` enum with `slideUp`, `slideDown`, `bend`, `release`, `hammerOn`, `pullOff`, and `vibrato`. Each has a `tabSymbol`, `label`, and `isConnector` getter for rendering logic.
- **Articulation per Note**: `TabNote` now includes an optional `articulation` field (defaults to `none`). Articulation applies to the first note of a connected pair (e.g., `slideUp` on note A means slide to the next same-string note B).
- **Articulation Selector in Toolbar**: New amber-highlighted chip button in the `TabPlayerScreen` toolbar cycles through articulations. All manually added notes inherit the currently selected articulation.
- **TAB Staff Rendering**: `TabNotationPainter` appends articulation symbols (e.g., `/` for slide, `b` for bend, `p` for pull-off) next to fret numbers on the TAB staff.
- **Slide Lines**: Diagonal connector lines drawn between consecutive same-string notes with `slideUp` or `slideDown` articulation.
- **Hammer-On / Pull-Off Curves**: Curved slur arcs with italic `h` or `p` labels centered between the two notes in both TAB and standard notation staves.
- **Standard Notation Slur Arcs**: Curved slur lines rendered in standard notation for all connector-type articulations (slides, hammer-ons, pull-offs).
- **Non-Connector Articulations**: `bend`, `release`, and `vibrato` symbols rendered inline next to fret numbers as standalone per-note effects.
- **Sample Tab Updated**: `_generateSampleTab()` now includes articulation examples across all 4 measures.
- **Auto-Detection of H/P in Recording**: `_processBatchRecordedFrequencies` auto-assigns `hammerOn`/`pullOff` when consecutive same-string notes have < 0.6 beats temporal gap.

### State Layer
- `TabPlayerState` now includes `selectedArticulation` field with `copyWith` support.
- Added `cycleSelectedArticulation()` and `setSelectedArticulation()` notifier methods.
- `addNoteManually()` uses the currently selected articulation.

---

## [1.2.1] - 2026-07-29

### Ghost / Muted Note Detection & X Notation
- **Transient Onset Detection in PitchEngine**: Added `_previousRms` tracking and `attackRmsThreshold` (0.025) to detect sharp amplitude attacks even when no stable pitch follows. When an onset is detected but the YIN algorithm finds no fundamental frequency, the frame is marked with `hasTransientAttack: true`.
- **Real-Time Ghost Note Recording**: `recordGhostNote()` method captures percussive/muted string hits during both recording and live mic modes. Ghost notes are placed on string 4 (D) by default and stored with `isGhost: true`.
- **Batch Recording Interleaving**: Ghost note timestamps recorded during a session are converted to beat positions and merged with frequency-derived notes after recording stops, then sorted by timeline position.
- **X Notation on TAB Staff**: `TabNotationPainter` renders a bold "X" symbol for ghost notes instead of a fret number, matching standard guitar tablature notation.
- **Amber Fretboard Badge**: `FretboardPainter` displays ghost notes with an amber (`#F59E0B`) glow badge with "X" text, visually distinct from green pitched notes.
- **Playback Skipping**: Audio synthesis is skipped for ghost notes during playback since they have no pitch.
- **Serialization**: `TabNote.toJson()` includes `isGhost` only when true; `fromJson()` parses it back. Added ghost note serialization test assertion.

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
