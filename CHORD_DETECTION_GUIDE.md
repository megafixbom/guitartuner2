# Chord Detection — User Guide

## 🎸 What It Does

GuitarTuner now **automatically detects chords** from your polyphonic guitar performance! No more playing single notes only — strum full chords and see them identified in real-time.

---

## 🔧 How It Works

### Chord Detection Flow
```
Your Strummed Chord
    ↓
Spectral Analysis (FFT)
    ↓
Frequency Peak Detection (2-6 notes)
    ↓
Convert to Pitch Classes (chroma)
    ↓
Match Against Chord Templates
    ↓
Best Match: Chord Name + Confidence
    ↓
Display Above Notation Staff
```

### Supported Chords (12 Types)

| Category | Chords |
|----------|--------|
| **Triads** | Major, Minor, Diminished, Augmented, Sus2, Sus4 |
| **Sevenths** | Dominant 7th, Major 7th, Minor 7th, Diminished 7th |
| **Extended** | Add9, Minor Add9 |

---

## 📊 Understanding the Display

### Chord Names Above Staff

```
     Am      G       C       F
┌────┴──┐ ┌─┴──┐ ┌──┴──┐ ┌─┴─┐
│  Am   │ │ G  │ │  C  │ │ F │  ← Blue pills with chord names
└────┬──┘ └─┬──┘ └──┬──┘ └─┬─┘
     │       │       │      │
═════════════════════════════════ ← Standard notation
     𝄞   ♯                        ← Key signature
═════════════════════════════════
     ════════════════════════════  ← TAB staff
```

### Visual Elements
- **Blue pill box**: Semi-transparent background (#3B82F6 at 15% opacity)
- **Bold chord name**: "Am", "G7", "Dm7", etc.
- **Positioned above staff**: Centered over corresponding measure
- **Timeline progression**: Chords appear in sequence as they change

### Confidence Levels

| Confidence | Display | Reliability |
|------------|---------|-------------|
| **>80%** | Solid blue pill | Highly reliable, clear chord |
| **60-80%** | Blue pill | Probable match |
| **50-60%** | Blue pill (marginal) | Ambiguous, possible false positive |
| **<50%** | No display | Rejected as unreliable |

---

## 🎮 Using Chord Detection

### Recording Chords

1. **Press Record** → Strum your chord progression
2. **Play clearly**: Let chords ring for 1-2 seconds each
3. **Press Stop** → Chord detection runs (2-3 seconds)
4. **View results**: Chords displayed above notation staff

### Example Progression

```
User plays: | Am  | G   | C   | F   | (2 beats per chord)
Duration: 8 seconds at 120 BPM
Detection result:
  - Measure 1: "Am" (87% confidence)
  - Measure 2: "G"  (92% confidence)
  - Measure 3: "C"  (89% confidence)
  - Measure 4: "F"  (76% confidence)
```

### Chord + Melody

If you play melody notes over sustained chords:
- **Bass notes** determine chord root
- **Melody notes** treated as extensions (9th, 11th, 13th)
- **Chord name** reflects underlying harmony

Example:
```
Chord: C major (C-E-G)
Melody: D note on top
Detection: "Cadd9" (if D is prominent enough)
```

---

## 💡 Best Practices

### ✅ For Accurate Detection

**Strumming Technique:**
- Strum all strings clearly (don't mute unintentionally)
- Let chord sustain for at least 500ms
- Use consistent rhythm (avoid arpeggios for detection)
- Play in time with steady tempo

**Chord Voicings:**
- Open position chords work best (frets 0-3)
- Barre chords detected well (frets 1-7)
- Power chords (root-5th) may show as "sus2"
- Avoid partial chords (2-3 strings only)

**Recording Quality:**
- Quiet environment (reduce background noise)
- Clear guitar tone (avoid heavy distortion)
- Moderate volume (not too soft, not clipping)
- Minimum 8 seconds for reliable detection

### ⚠️ Detection Limitations

**May Fail or Show Wrong Chord If:**
- Chord changes too fast (<500ms per chord)
- Heavy palm muting (mutes bass notes)
- Excessive string noise/fret buzz
- Polyphony <2 notes (single note lines)
- Very high fret positions (>7th fret)
- Non-standard tunings (detection assumes EADGBE)

**Common Misidentifications:**
- **Am ↔ C**: Both share notes A-C-E, differs by bass
- **G ↔ Em**: Share G-B-D notes
- **Fmaj7 ↔ Dm7**: Similar pitch content
- **Power chord (A5) ↔ Asus2**: Both root-5th structure

---

## 🎵 Chord Types Explained

### Major Triads
**Notation**: `C`, `G`, `D`, `A`, `E`, `F`

**Sound**: Bright, happy, stable

**Structure**: Root + Major 3rd + Perfect 5th (1-3-5)

**Example**: C major = C-E-G

---

### Minor Triads
**Notation**: `Am`, `Em`, `Dm`, `Bm`, `F#m`

**Sound**: Dark, sad, melancholic

**Structure**: Root + Minor 3rd + Perfect 5th (1-b3-5)

**Example**: A minor = A-C-E

---

### Dominant 7th
**Notation**: `G7`, `A7`, `D7`, `E7`, `C7`

**Sound**: Bluesy, wants to resolve

**Structure**: Root + Maj 3rd + Perf 5th + Min 7th (1-3-5-b7)

**Example**: G7 = G-B-D-F

---

### Major 7th
**Notation**: `Cmaj7`, `Dmaj7`, `Emaj7`

**Sound**: Jazz, dreamy, sophisticated

**Structure**: Root + Maj 3rd + Perf 5th + Maj 7th (1-3-5-7)

**Example**: Cmaj7 = C-E-G-B

---

### Minor 7th
**Notation**: `Am7`, `Dm7`, `Em7`

**Sound**: Smooth minor, jazz minor

**Structure**: Root + Min 3rd + Perf 5th + Min 7th (1-b3-5-b7)

**Example**: Am7 = A-C-E-G

---

### Diminished
**Notation**: `Bdim`, `D#dim`, `G#dim`

**Sound**: Tense, mysterious, wants to resolve

**Structure**: Root + Min 3rd + Dim 5th (1-b3-b5)

**Example**: Bdim = B-D-F

---

### Augmented
**Notation**: `Caug`, `Eaug`, `G#aug`

**Sound**: Dreamlike, unsettling, symmetrical

**Structure**: Root + Maj 3rd + Aug 5th (1-3-#5)

**Example**: Caug = C-E-G#

---

### Suspended 4th
**Notation**: `Csus4`, `Gsus4`, `Dsus4`

**Sound**: Open, unresolved, folk-like

**Structure**: Root + Perf 4th + Perf 5th (1-4-5)

**Example**: Csus4 = C-F-G

---

### Suspended 2nd
**Notation**: `Csus2`, `Gsus2`, `Dsus2`

**Sound**: Gentle, open, ambiguous

**Structure**: Root + Maj 2nd + Perf 5th (1-2-5)

**Example**: Csus2 = C-D-G

---

### Add 9th
**Notation**: `Cadd9`, `Gadd9`, `Dadd9`

**Sound**: Rich, contemporary, emotional

**Structure**: Major triad + Major 9th (1-3-5-9)

**Example**: Cadd9 = C-E-G-D

---

### Minor Add 9th
**Notation**: `Amadd9`, `Dmadd9`

**Sound**: Melancholic but beautiful

**Structure**: Minor triad + Major 9th (1-b3-5-9)

**Example**: Amadd9 = A-C-E-B

---

## 🔄 Troubleshooting

### "No Chords Detected"
**Symptoms:** Blank space above staff (no blue pills)

**Causes:**
- Playing single-note lines (need 2+ notes simultaneously)
- Chords too short (<500ms duration)
- Confidence <50% (rejected)
- Recording too noisy

**Solutions:**
- Strum full chords (4-6 strings)
- Let each chord ring for 1-2 seconds
- Reduce background noise
- Check guitar volume (not too soft)

---

### "Wrong Chord Name"
**Symptoms:** Blue pill shows incorrect chord (e.g., "C" when you played "Am")

**Causes:**
- Ambiguous voicing (chords share notes)
- Weak bass note detection
- Inversion (bass note ≠ root)
- Melody note overpowering harmony

**Solutions:**
- Play root-position chords (bass = root note)
- Strum from bass to treble (emphasize low strings)
- Avoid melody notes during chord change
- Check capo position (detection assumes standard tuning)

---

### "Chords Flickering"
**Symptoms:** Rapid chord changes (Am-G-Am-G-Am) within one measure

**Causes:**
- Marginal confidence (oscillating between matches)
- Uneven strumming pattern
- Sympathetic string resonance

**Solutions:**
- Strum more evenly and consistently
- Mute unused strings properly
- Detection has smoothing, but performance may need cleanup
- Re-record with cleaner technique

---

## 📊 Technical Reference

### Detection Parameters
| Parameter | Value |
|-----------|-------|
| **FFT Size** | 4096 samples |
| **Hop Size** | 2048 samples (50% overlap) |
| **Frequency Range** | 80-400 Hz |
| **Max Polyphony** | 6 notes (strings) |
| **Min Peak Separation** | 20 Hz |
| **Confidence Threshold** | 0.5 (50%) |
| **Min Chord Duration** | ~500ms |

### Algorithm Steps
1. **Windowing**: Apply Hann window to audio frame
2. **Magnitude Spectrum**: Compute spectral energy distribution
3. **Peak Picking**: Find local maxima (>20Hz apart)
4. **Pitch Class Conversion**: MIDI note → chroma (0-11)
5. **Template Matching**: Test all 12 roots × 12 chord types
6. **Jaccard Scoring**: Intersection / Union of pitch classes
7. **Best Match Selection**: Highest score above 0.5 threshold
8. **Voicing Estimation**: Lowest freq → fret position
9. **Temporal Smoothing**: Compare with previous chord
10. **Timeline Alignment**: Assign chord to measure

---

## 🎵 Integration with Other Features

### With Key Detection (v1.4.0)
- **Chord progression** validates detected key
- **Key signature** displayed on staff
- **Chord names** shown above staff
- Example: Detected key "Am" + progression "Am-G-C-F" confirms A minor

### With BPM Detection (v1.5.0)
- **Chord changes** aligned to beat grid
- **Chord duration** measured in beats/measures
- **Tempo** used for chord timeline positioning
- Example: 120 BPM + 4/4 time → chord per measure = 4 beats

### With Articulation (v1.3.0)
- **Chord strums** can have articulations (slide, bend)
- **Individual notes** within chord may have H/P markers
- Future: Arpeggiated chord detection

---

## 📁 Files Modified
- `lib/services/chord_detector.dart` — NEW: Multi-pitch chord detection
- `lib/state/tab_player_state.dart` — Added `detectedChords` field
- `lib/views/tab_player_screen.dart` — Chord name rendering above staff
- `CHANGELOG.md` — v1.6.0 release notes
- `ROADMAP.md` — Chord detection marked as completed

---

## 🚀 Future Enhancements

### In Progress
- [ ] Chord diagram display (6x4 grid showing finger positions)
- [ ] Power chord simplification (detect "A5" instead of "Asus2")
- [ ] Inversion detection (chord/bass note notation)
- [ ] Chord duration tracking (how long each chord held)

### Planned
- [ ] Real-time chord display during recording (not just post-processing)
- [ ] Chord suggestion (alternative voicings for same chord)
- [ ] Progression analysis (common patterns: I-V-vi-IV, ii-V-I)
- [ ] Export chord chart (leadsheet format with chord symbols)

---

**Version:** 1.6.0  
**Last Updated:** 2026-07-30  
**Repository:** [github.com/megafixbom/guitartuner2](https://github.com/megafixbom/guitartuner2)
