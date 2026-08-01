# Moises AI-Style Features Implementation Plan

## Feature Comparison Matrix

| Feature | Moises AI | GuitarTuner Current | Priority | Effort |
|---------|-----------|---------------------|----------|--------|
| **Chord Detection** | ✅ Real-time | ❌ Monophonic only | P1 | Medium |
| **Key Finder** | ✅ | ✅ (v1.4.0) | Done | Done |
| **Pitch Control** | ✅ Shift | ❌ | P2 | Medium |
| **BPM Detection** | ✅ Auto | ⚠️ Manual only | P1 | Medium |
| **BPM Control** | ✅ Adjust | ✅ | Done | Done |
| **Lyric Transcription** | ✅ | ❌ | P3 | High |
| **Smart Metronome** | ✅ Auto-sync | ✅ (v1.7.0) | Done | Done |

---

## Feature Specifications

### 1. Chord Detection (P1 - Priority)

**Goal:** Detect polyphonic chords from audio input (2-6 notes simultaneously)

**Implementation Approach:**
```
Audio Input → YIN Multi-Pitch Detection → Pitch Classes → Chord Matching → Display
```

**Technical Requirements:**
- Multi-pitch YIN algorithm (detect 2-6 simultaneous frequencies)
- Chroma feature extraction (12-dimensional pitch class vector)
- Chord template matching (major, minor, 7th, diminished, augmented)
- Real-time display on fretboard (multiple LED badges simultaneously)
- Chord name overlay on notation staff

**Data Structures:**
```dart
class DetectedChord {
  final String name;        // "Am", "G7", "Dm7", "Cmaj7"
  final List<int> notes;    // Pitch classes [0, 4, 7]
  final String root;        // "C", "D", "E"
  final String quality;     // "major", "minor", "7", "dim"
  final double confidence;  // 0.0 - 1.0
  final int voicing;        // Fret position (open, 1st, 3rd, 5th...)
}
```

**UI Changes:**
- Chord name display below standard notation
- Chord diagram box (6x4 grid showing finger positions)
- Multiple simultaneous fretboard LEDs for chord tones
- Chord progression timeline (e.g., | Am | G | C | D |)

**Files to Modify:**
- `lib/services/pitch_detector.dart` — Multi-pitch YIN
- `lib/services/chord_detector.dart` — NEW: chord matching logic
- `lib/state/tab_player_state.dart` — Add `DetectedChord` to timeline
- `lib/views/tab_player_screen.dart` — Chord rendering on staff

---

### 2. Automatic BPM Detection (P1)

**Goal:** Auto-detect tempo from recorded audio (no manual tap tempo needed)

**Implementation Approach:**
```
Audio → Onset Detection → Inter-Onset Intervals → Histogram → Tempo Candidate Selection → BPM
```

**Technical Requirements:**
- Onset detection function (ODF) using spectral flux
- Peak picking on ODF
- IOI (inter-onset interval) histogram
- Tempo candidates: 60-200 BPM range
- Beat grid generation (downbeat detection)

**Algorithm:**
1. Compute spectral flux from audio frames
2. Detect onset peaks (local maxima above threshold)
3. Calculate time differences between onsets
4. Build histogram of IOIs
5. Find most common IOI → convert to BPM
6. Refine with beat tracking (dynamic programming)

**Data Structures:**
```dart
class DetectedTempo {
  final double bpm;           // e.g., 120.0
  final List<double> beats;   // Beat timestamps [0.0, 0.5, 1.0...]
  final List<int> timeSig;    // [4, 4] for 4/4 time
  final double confidence;    // 0.0 - 1.0
}
```

**UI Changes:**
- "Auto" button next to BPM display
- Beat grid overlay on waveform
- Time signature selector (4/4, 3/4, 6/8)

**Files to Modify:**
- `lib/services/audio_service.dart` — Onset detection
- `lib/services/tempo_detector.dart` — NEW: BPM detection
- `lib/state/tab_player_state.dart` — `detectedTempo` field
- `lib/views/tab_player_screen.dart` — Auto BPM toggle

---

### 3. Pitch Shifting / Key Transposition (P2)

**Goal:** Change song key without affecting tempo (pitch shift ±12 semitones)

**Implementation Approach:**
- Phase vocoder for pitch shifting
- Preserve original tempo
- Apply to playback engine
- Optional: real-time pitch shift during recording monitoring

**Technical Requirements:**
- FFT-based phase vocoder implementation
- Pitch shift ratio: `2^(semitones/12)`
- Overlap-add synthesis
- Maintain formants (optional, advanced)

**UI Changes:**
- Pitch shift slider (-12 to +12 semitones)
- Display: "Original: Em → Current: Gm (+3)"
- Transpose button in toolbar

**Files to Modify:**
- `lib/services/audio_service.dart` — Phase vocoder
- `lib/services/pitch_shifter.dart` — NEW
- `lib/views/tab_player_screen.dart` — Pitch control UI

---

### 4. Smart Metronome (P2) — ✅ DONE v1.7.0

**Goal:** Generate click track that syncs to detected beat grid

**Implemented:**
- `MetronomeService` in `lib/services/metronome_service.dart` plays strong/weak/subdivision clicks synced to current tempo + time signature
- Subdivision options (quarter, eighth, sixteenth)
- Accent on beat 1 (downbeat), weak on beats 2-4
- Sound selector (woodblock, beep, stick) with synthesized WAV assets
- Volume slider with mute-at-zero
- Clicks fire from the playhead crossing logic during playback/recording

**Audio Assets:**
- `assets/sounds/metronome_{woodblock|beep|stick}_{strong|weak|sub}.wav`

**UI:**
- Metronome toggle chip (`MET`) in toolbar
- Control bar with subdivision/sound selectors + volume slider

**Files:**
- `lib/services/metronome_service.dart` — NEW
- `lib/views/tab_player_screen.dart` — Metronome controls
- `lib/state/tab_player_state.dart` — metronome state + click triggering

---

### 5. Lyric Transcription (P3 - Advanced)

**Goal:** Convert sung vocals to text lyrics synchronized with music

**Implementation Approach:**
**Option A: On-Device (Limited)**
- TensorFlow Lite speech-to-text model
- English only, ~80% accuracy
- No network required

**Option B: Cloud API (Recommended)**
- Integrate with Whisper API / Google Speech-to-Text
- High accuracy, multi-language
- Requires user API key

**Technical Requirements:**
- Voice activity detection (VAD)
- Audio segmentation (vocal vs instrumental)
- Timestamp alignment with lyrics
- Karaoke-style highlighting during playback

**UI Changes:**
- Lyrics panel below fretboard
- Word-by-word highlighting during playback
- Editable lyrics (user corrections)
- Export as LRC file (lyrics + timestamps)

**Files to Create:**
- `lib/services/lyric_transcriber.dart` — NEW
- `lib/models/lyric_segment.dart` — NEW
- `lib/views/lyrics_panel.dart` — NEW

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [x] Key detection (DONE v1.4.0)
- [x] Automatic BPM detection (DONE v1.5.0)
- [x] Smart metronome (DONE v1.7.0)

### Phase 2: Harmonic Analysis (Week 3-4)
- [x] Chord detection (basic triads) (DONE v1.6.0)
- [ ] Chord diagram rendering
- [ ] Chord progression timeline

### Phase 3: Audio Manipulation (Week 5-6)
- [ ] Pitch shifting engine
- [ ] Key transposition UI
- [ ] Tempo stretching (optional)

### Phase 4: Advanced Features (Week 7-8)
- [ ] Lyric transcription (API integration)
- [ ] Lyric alignment + highlighting
- [ ] Export to LRC / MusicXML

---

## Dependencies to Add

```yaml
# pubspec.yaml
dependencies:
  # Audio processing
  audioplayers: ^6.0.0     # Already present
  record: ^4.4.4           # Already present
  
  # NEW: For FFT / pitch shifting
  meta: ^1.10.0
  
  # NEW: For speech-to-text (optional)
  # speech_to_text: ^6.4.0  # If using on-device
  
  # NEW: For advanced DSP
  # audio_waveforms: ^1.0.0 # For waveform visualization
```

---

## Technical Challenges & Solutions

### Challenge 1: Multi-Pitch Detection
**Problem:** YIN algorithm is monophonic (single pitch)

**Solutions:**
1. **Iterative YIN:** Detect strongest pitch → subtract → detect next
2. **Spectral Peaking:** Find multiple peaks in frequency spectrum
3. **Use library:** `librosa` (Python) but we need Dart implementation
4. **Hybrid approach:** Comb harmonic product spectrum (HPS) with YIN

**Chosen:** Iterative YIN with spectral subtraction (most accurate for guitar)

---

### Challenge 2: Real-Time Performance
**Problem:** DSP processing can block UI thread

**Solutions:**
1. **Isolate worker:** All DSP on background isolate (already implemented)
2. **Frame buffering:** Process 2048-sample frames (46ms at 44.1kHz)
3. **Progressive rendering:** Update UI every 100ms, not every frame
4. **Lazy evaluation:** Only process visible measures

**Status:** Already using isolates ✓ — extend for new features

---

### Challenge 3: Chord Voicing Ambiguity
**Problem:** Same chord can be played in multiple positions

**Solutions:**
1. **Bass note detection:** Root position vs inversions
2. **Fret range heuristic:** Assume open position unless high notes present
3. **User correction:** Allow manual override
4. **Show alternatives:** "Am (open) / Am (5th fret)"

---

### Challenge 4: Lyric Accuracy
**Problem:** Speech-to-text errors with singing voice

**Solutions:**
1. **API choice:** Whisper API handles singing better than standard STT
2. **User editing:** Make lyrics editable post-transcription
3. **Confidence highlighting:** Show low-confidence words in red
4. **Manual sync:** Allow user to adjust lyric timestamps

---

## Success Metrics

| Feature | Acceptance Criteria |
|---------|---------------------|
| Chord Detection | >80% accuracy on triads, <200ms latency |
| BPM Detection | ±2 BPM accuracy on 80-180 BPM range |
| Pitch Shifting | ±12 semitones, no audible artifacts |
| Metronome | <10ms jitter, sync to detected beat grid |
| Lyric Transcription | >85% word accuracy (Whisper API) |

---

## File Structure (After Implementation)

```
lib/
├── services/
│   ├── audio_service.dart        # Mic, ring buffer (existing)
│   ├── pitch_detector.dart       # YIN algorithm (existing)
│   ├── pitch_engine.dart         # Pitch processing (existing)
│   ├── chord_detector.dart       # DONE: Multi-pitch + chord matching
│   ├── tempo_detector.dart       # DONE: BPM detection
│   ├── metronome_service.dart    # DONE: Click track generation
│   ├── pitch_shifter.dart        # NEW: Phase vocoder
│   └── lyric_transcriber.dart    # NEW: Speech-to-text
├── models/
│   ├── detected_chord.dart       # NEW: Chord data model
│   ├── detected_tempo.dart       # NEW: BPM + beat grid
│   └── lyric_segment.dart        # NEW: Timestamped lyrics
├── state/
│   ├── tab_player_state.dart     # Extended with chords/tempo
│   └── tuner_state.dart          # (existing)
└── views/
    ├── tab_player_screen.dart    # Extended with chord/lyric UI
    ├── tuner_screen.dart         # (existing)
    └── lyrics_panel.dart         # NEW: Karaoke-style lyrics
```

---

## Next Steps

1. ~~Start with BPM Detection~~ ✅ DONE v1.5.0
2. ~~Add Metronome~~ ✅ DONE v1.7.0
3. ~~Implement Chord Detection~~ ✅ DONE v1.6.0
4. **Add Scale Detection** (builds on pitch class histogram from key detection)
5. **Add Pitch Shifting** (standalone, can be tested independently)
6. **Integrate Lyric API** (requires external API key setup)

Ready to begin the next implementation? I'll start with **Scale Detection** as the foundation for lead-section analysis.
