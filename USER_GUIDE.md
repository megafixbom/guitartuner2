# GuitarTuner User Guide

## 📖 Table of Contents

1. [Quick Start](#quick-start)
2. [Recording Your Song](#recording-your-song)
3. [Understanding Key Detection](#understanding-key-detection)
4. [Reading the Tablature](#reading-the-tablature)
5. [Playback & Editing](#playback--editing)
6. [Tips & Troubleshooting](#tips--troubleshooting)

---

## Quick Start

### Launch the App
```bash
flutter run
```

### Main Interface Components
```
┌─────────────────────────────────────────────┐
│  [Save] [Load] [Loop] [Clear]        [Back]│ ← AppBar Actions
├─────────────────────────────────────────────┤
│ [Mic]  BPM:120±  [Em(75)] [/] [1/4] [●][▶] │ ← Toolbar
├─────────────────────────────────────────────┤
│                                             │
│ ═══════════════════════════════════════════ │ ← Standard Notation
│   𝄞   ♯                                     │    (with key signature)
│ ═══════════════════════════════════════════ │
│                                             │
│ T  ════════════════════════════════════════ │ ← TAB Staff (6 strings)
│ A  ════════════════════════════════════════ │    e B G D A E
│ B  ════════════════════════════════════════ │
│    0──2──3──────────────────────────────────│    Fret numbers
│                                             │
│            [Red Playhead Line]              │
│                  ▼                          │
├─────────────────────────────────────────────┤
│ [Fretboard Visualizer with LED badges]      │
└─────────────────────────────────────────────┘
```

---

## Recording Your Song

### Step-by-Step Recording Process

#### 1. **Set Your Tempo (BPM)**
- Default: **120 BPM** (beats per minute)
- **Tap the BPM number** to set tempo by tapping rhythm
- Use **± buttons** for fine adjustment
- Range: **40-280 BPM**

#### 2. **Press Record Button**
- Tap the **red circle button** (●) in toolbar
- Timer starts: **`REC 0.0s`**
- Red pulsing indicator appears
- 12-bar waveform visualizer shows live audio levels

#### 3. **Play Your Song**
- Play into your device's microphone
- Guitar, bass, or any monophonic instrument works
- The app detects:
  - ✓ Individual notes (frequencies 70Hz - 400Hz)
  - ✓ Ghost/muted notes (percussive attacks)
  - ✓ Hammer-ons and pull-offs (auto-detected)
  - ✓ Slides (if consecutive same-string notes)

#### 4. **Stop Recording**
- Tap the **record button again** (or press stop ▶)
- Processing begins...
- Wait 1-3 seconds for analysis

#### 5. **Review Results**
The app generates:
- **Full tablature** (up to 100 measures / ~3 minutes at 120 BPM)
- **Detected musical key** (e.g., "Em", "G Major")
- **Key signature** on standard notation staff
- **Articulation symbols** (h, p, /, b, ~)
- **Ghost notes** (X notation)

### Recording Example

**Scenario:** Record a 30-second riff in E minor at 120 BPM

1. Tap BPM, set to **120**
2. Press **Record** (●)
3. Play your riff (open E string, 2nd fret A, 3rd fret A, etc.)
4. Press **Record** again to stop
5. Result:
   - **~7-8 measures** of tablature
   - Key chip shows: **"Em (72)"**
   - Staff shows: **One sharp (F♯)** at start
   - Scrollable horizontally if >4 measures

---

## Understanding Key Detection

### How It Works

```
Your Performance
      ↓
Frequency Detection (YIN Algorithm)
      ↓
Convert to Tab Notes (String + Fret)
      ↓
Build Pitch Class Histogram (12 bins: C, C#, D... B)
      ↓
Score Against Major & Minor Key Profiles
      ↓
Best Match = Detected Key
```

### Pitch Class Histogram

The app counts how many times each of the 12 chromatic pitches appears:

```
Example in E minor:
E: ████████████ (most frequent - tonic)
F: ██
F#: ████████ (raised 7th in harmonic minor)
G: ██████████
G#: █
A: ███████
A#: 
B: ████████ (5th of key)
C: ███
C#: 
D: █████
D#: 
```

### Key Scoring

The algorithm compares your histogram against pre-defined profiles:

| Key | Major Score | Minor Score |
|-----|-------------|-------------|
| C   | 0.42        | 0.31        |
| D   | 0.38        | 0.29        |
| E   | 0.51        | **0.78** ← Best match |
| G   | 0.67        | 0.45        |
| A   | 0.59        | 0.52        |

**Result:** E minor with 78% confidence

### Interpreting the Key Chip

Toolbar displays: **`[♩ Em (78)]`**

| Confidence | Color | Meaning |
|------------|-------|---------|
| **>70%** | 🟢 Green | Strong key center, reliable detection |
| **50-70%** | 🟠 Amber | Probable key, some ambiguity |
| **<50%** | ⚪ Gray | Weak or ambiguous tonality |
| **Not shown** | — | Less than 3 notes or confidence <30% |

### Key Signature Display

Standard notation staff shows accidentals at the beginning:

**One Sharp (F♯):**
```
 ═══════════════════════════════
   𝄞   ♯                          ← F# on top line
 ═══════════════════════════════
```

**Two Sharps (F♯, C♯):**
```
 ═══════════════════════════════
   𝄞   ♯  ♯                       ← F# and C#
 ═══════════════════════════════
```

**One Flat (B♭):**
```
 ═══════════════════════════════
   𝄞   ♭                          ← Bb on middle line
 ═══════════════════════════════
```

---

## Reading the Tablature

### Dual Staff System

```
Standard Notation (top 5 lines):
  - Shows pitch height (higher = higher pitch)
  - Duration indicated by note head (open/filled) and flags
  - Key signature accidentals shown here
  - Slur arcs for hammer-ons/pull-offs/slides

TAB Staff (bottom 6 lines):
  - 6 lines = 6 guitar strings (e B G D A E top to bottom)
  - Numbers = fret to press
  - X = ghost/muted note (amber badge on fretboard)
  - Articulation symbols: h p / b ~ r
```

### Note Duration Legends

| Symbol | Duration | Note Head | Example |
|--------|----------|-----------|---------|
| 𝅝 | Whole | Open oval, no stem | 4 beats |
| 𝅗𝅥 | Half | Open oval, with stem | 2 beats |
| 𝅘𝅥 | Quarter | Filled circle, stem | 1 beat |
| 𝅘𝅥𝅮 | Eighth | Filled circle, stem + 1 flag | 1/2 beat |
| 𝅘𝅥𝅯 | Sixteenth | Filled circle, stem + 2 flags | 1/4 beat |

### Articulation Symbols

| Symbol | Meaning | Playback Effect |
|--------|---------|-----------------|
| `h` | Hammer-on | No re-pick, smooth transition |
| `p` | Pull-off | No re-pick, descending |
| `/` | Slide up | Glide to next note |
| `\` | Slide down | Glide to lower note |
| `b` | Bend | (Future: pitch bend synthesis) |
| `~` | Vibrato | (Future: vibrato effect) |
| `r` | Release | (Future: bend release) |
| `X` | Ghost note | Percussive, no pitch |

---

## Playback & Editing

### Playback Controls

| Button | Action |
|--------|--------|
| **▶** (Play) | Start playback from current position |
| **⏸** (Pause) | Pause playback |
| **⏹** (Stop) | Stop and reset to beginning |
| **🔁** (Loop) | Toggle loop on/off |

### Manual Note Entry

1. **Select Duration** — Tap duration chip to cycle (1/4, 1/8, 1/16...)
2. **Select Articulation** — Tap articulation chip to cycle (—, /, h, p, b, ~)
3. **Tap Score Canvas** — Add note at tapped position
4. **Tap Fretboard** — Add note at current playhead beat
5. **Clear Tab** — Delete all notes (confirmation dialog)

### Horizontal Scrolling

- **Swipe left/right** on score canvas to scroll
- **Auto-scroll** during playback follows playhead
- Supports up to **100 measures** (~12,000 pixels wide)

---

## Tips & Troubleshooting

### Best Recording Practices

✅ **DO:**
- Use a quiet room (noise floor = 0.015 RMS)
- Play clear, sustained notes (not percussive strumming)
- Keep guitar within 1-2 feet of microphone
- Play at moderate tempo (<160 BPM for accurate detection)
- Use clean guitar tone (no distortion/overdrive)

❌ **DON'T:**
- Play in noisy environments (TV, conversations)
- Strum full chords (monophonic detection only)
- Hit strings too hard (clipping causes false readings)
- Expect vocal detection (strict guitar gating)

### Common Issues

#### "No Key Detected"
**Causes:**
- Less than 3 notes played
- Atonal/ Chromatic passage (no clear key center)
- Very short recording (<5 seconds)

**Solutions:**
- Play longer phrases (8+ notes)
- Use diatonic melodies (stay in one key)
- Avoid excessive modulation

#### "Wrong Key Detected"
**Causes:**
- Modulation within song (key changes)
- Borrowed chords or modal mixture
- Insufficient data (too few notes)

**Solutions:**
- Record sections separately (verse, chorus)
- Check pitch histogram in developer mode (future feature)
- Manually verify against known chord progression

#### "Notes Missing from Tab"
**Causes:**
- Too quiet (below noise floor)
- Too short (<100ms duration)
- Overlapping notes (polyphony not supported)

**Solutions:**
- Play louder (but avoid clipping)
- Sustain notes longer
- Play single-note lines (not chords)

#### "Ghost Notes Appearing Randomly"
**Causes:**
- String noise or fret buzz
- Percussive attacks without clear pitch
- Handling noise (muting with palm)

**Solutions:**
- Clean up your playing technique
- Mute unused strings properly
- Use noise gate pedal if recording electric

### Performance Tips

- **100 measures max** — Recording longer than ~3 minutes at 120 BPM will truncate
- **160 BPM limit** — Faster tempos may cause detection lag
- **Monophonic only** — Chords will detect only the strongest note
- **E-G string range** — Best detection 82Hz (low E) to 330Hz (high E)

---

## Appendix: Technical Reference

### Supported Frequencies

| String | Open (Hz) | 12th Fret (Hz) |
|--------|-----------|----------------|
| 6 (E)  | 82.41     | 164.81         |
| 5 (A)  | 110.00    | 220.00         |
| 4 (D)  | 146.83    | 293.66         |
| 3 (G)  | 196.00    | 392.00         |
| 2 (B)  | 246.94    | 493.88         |
| 1 (E)  | 329.63    | 659.25         |

**Detection Range:** 70Hz - 400Hz (covers open position + ~7th fret on high E)

### Key Profiles (Krumhansl-Schmiedler)

**Major Key Profile:**
```
Scale Degrees: 1    2    3    4    5    6    7
Weights:      0.77 0.08 0.14 0.50 0.04 0.09 0.12
              (Tonic dominant leading tone...)
```

**Minor Key Profile:**
```
Scale Degrees: 1    2    3    4    5    6    7
Weights:      0.75 0.06 0.11 0.39 0.02 0.16 0.15
              (Tonic dominant submediant...)
```

### File Formats

**Session Save:** `recorded_tab_session.json`
```json
{
  "version": "1.0",
  "bpm": 120.0,
  "totalMeasures": 8,
  "detectedKey": {
    "tonic": 4,
    "mode": "minor",
    "confidence": 0.78
  },
  "measures": [
    {
      "number": 1,
      "notes": [
        {"stringIndex": 6, "fret": 0, "position": 0.0, "duration": "quarter"},
        {"stringIndex": 5, "fret": 2, "position": 1.0, "duration": "quarter"}
      ]
    }
  ]
}
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  HOW TO RECORD YOUR SONG                                │
├─────────────────────────────────────────────────────────┤
│  1. Set BPM: Tap number → tap rhythm → fine-tune ±     │
│  2. Press ● (Record) → red pulsing dot + timer starts  │
│  3. Play into mic (quiet room, 1-2 ft distance)        │
│  4. Press ● again to stop                              │
│  5. Wait for processing (1-3 seconds)                  │
│  6. View result:                                        │
│     - Scrollable tablature (swipe left/right)          │
│     - Key chip in toolbar (e.g., "Em (78)")            │
│     - Key signature on staff (♯ or ♭ symbols)          │
├─────────────────────────────────────────────────────────┤
│  KEY CONFIDENCE COLORS                                  │
├─────────────────────────────────────────────────────────┤
│  🟢 Green (>70%)  = Reliable detection                  │
│  🟠 Amber (50-70%) = Probable, some ambiguity          │
│  ⚪ Gray (<50%)   = Weak or ambiguous                   │
├─────────────────────────────────────────────────────────┤
│  SYMBOLS QUICK GUIDE                                    │
├─────────────────────────────────────────────────────────┤
│  h = Hammer-on    p = Pull-off     / = Slide up        │
│  \ = Slide down   b = Bend         ~ = Vibrato         │
│  X = Ghost note   𝅘𝅥 = Quarter note  𝅘𝅥𝅮 = Eighth note      │
└─────────────────────────────────────────────────────────┘
```

---

**Last Updated:** 2026-07-30  
**Version:** 1.4.0  
**Repository:** [github.com/megafixbom/guitartuner2](https://github.com/megafixbom/guitartuner2)
