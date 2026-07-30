# Automatic BPM Detection — User Guide

## 🎯 What It Does

After you finish recording, GuitarTuner **automatically detects the tempo (BPM)** of your performance and sets it for you. No more manual tap tempo needed!

---

## 🔧 How It Works

### Recording Flow
1. Press **Record** button and play your song
2. Audio samples are captured at 100Hz (RMS levels)
3. Press **Stop** → Tempo detection runs automatically
4. BPM display updates with **green highlight + ✨ icon** if confident detection

### Detection Algorithm
```
Your Audio
    ↓
Spectral Flux (energy change detection)
    ↓
Onset Peaks (note attacks)
    ↓
Inter-Onset Intervals (IOI)
    ↓
IOI Histogram (find common tempo)
    ↓
Best BPM Candidate (60-200 BPM range)
    ↓
Beat Grid Generation
```

---

## 📊 Understanding the Detection

### BPM Display States

| Visual | Meaning |
|--------|---------|
| **Cyan text** | Manual BPM (default 120 or user-set) |
| **Green text + ✨ icon** | Auto-detected tempo (confidence >40%) |
| **Green border + background** | Currently using auto-detected tempo |

### Confidence Levels

| Confidence | Result |
|------------|--------|
| **>70%** | Green display, highly reliable |
| **40-70%** | Green display, probable tempo |
| **<40%** | No auto-detection (keeps manual BPM) |

---

## 🎮 Using Auto-Detected BPM

### After Recording
- Tempo auto-sets to detected value
- Playback uses detected BPM
- Metronome (future) will sync to beat grid

### Override / Fine-Tune
- **Tap BPM display**: Clears auto-detection, reverts to tap tempo
- **Tap +/- buttons**: Fine-tune detected BPM (±1 BPM increments)
- **Range**: 40-280 BPM (same as manual mode)

### Clearing Auto-Tempo
If you want to use manual tap tempo instead:
1. Tap the BPM display (shows current BPM number)
2. Auto-tempo clears (green → cyan)
3. Start tapping rhythm to set BPM manually

---

## 💡 Best Practices

### ✅ For Accurate Detection
- **Play consistently**: Steady tempo throughout recording
- **Clear attacks**: Definite note onsets (avoid legato/smooth passages only)
- **Minimum length**: >10 seconds of audio needed
- **Moderate tempo**: Best accuracy 80-160 BPM range
- **Quiet environment**: Reduce background noise

### ⚠️ Detection May Fail If
- Recording too short (<10 seconds)
- Very irregular tempo (rubato, accelerando)
- Extremely sparse arrangement (long gaps between notes)
- Heavy syncopation without clear downbeats
- Background noise overwhelming transients

### 🔧 Fixing Wrong Detection
1. Tap BPM display to clear auto-detection
2. Use **tap tempo** (tap the BPM number in rhythm)
3. Use **+/- buttons** for fine adjustment
4. Re-record with clearer attacks if needed

---

## 🎵 Technical Reference

### Detection Parameters
| Parameter | Value |
|-----------|-------|
| **Sample Rate** | 100 Hz (RMS levels) |
| **Max Buffer** | 30,000 samples (5 minutes) |
| **BPM Range** | 60-200 BPM |
| **Min Confidence** | 0.4 (40%) |
| **Min Recording** | ~10 seconds |
| **FFT Frame Size** | 2048 samples |
| **Hop Size** | 512 samples |
| **IOI Bin Width** | 50ms |

### Algorithm Steps
1. **Spectral Flux**: Compute energy change between frames
2. **Adaptive Threshold**: Mean + 0.5 × std dev
3. **Peak Picking**: Local maxima above threshold
4. **Non-Max Suppression**: 100ms minimum gap between onsets
5. **IOI Calculation**: Time differences between consecutive onsets
6. **Histogram**: 50ms bins, find peaks
7. **Candidate Selection**: Convert IOI peaks to BPM
8. **Octave Ambiguity**: Consider 2x and 0.5x candidates
9. **Beat Grid**: Generate timestamps at detected BPM

---

## 🔄 Future Enhancements (Coming Soon)

### Smart Metronome
- Click track synced to detected beat grid
- Subdivision options (quarter, eighth, sixteenth)
- Accents on downbeats

### Time Signature Detection
- Auto-detect 4/4, 3/4, 6/8, etc.
- Downbeat recognition (beat 1 emphasis)

### Tempo Map
- Detect tempo changes within song
- Ritardando / accelerando tracking
- Section-based tempo (verse vs chorus)

---

## 📖 Integration with Other Features

| Feature | Interaction with BPM Detection |
|---------|-------------------------------|
| **Key Detection** | Independent (both run after recording) |
| **Chord Detection** | Uses detected BPM for chord change timing |
| **Playback** | Playhead speed uses detected BPM |
| **Smart Metronome** | Will sync clicks to detected beat grid |
| **Pitch Shifting** | Future: preserve tempo when transposing |

---

## 🐛 Troubleshooting

### "BPM Not Detected"
**Symptoms:** Display stays cyan (no green highlight)

**Causes:**
- Recording too short (<10s)
- Too few transients/onsets
- Confidence <40%

**Solutions:**
- Record longer performance
- Play with clearer note attacks
- Reduce background noise

### "Wrong BPM Detected"
**Symptoms:** Display is green but tempo is incorrect (e.g., half-time or double-time)

**Causes:**
- Octave ambiguity (common in tempo detection)
- Sparse arrangement with weak downbeats
- Syncopated rhythm confusing onset detection

**Solutions:**
- Tap +/- buttons to adjust (try ×2 or ÷2)
- Tap BPM display to clear and use manual tap tempo
- Re-record with stronger downbeat emphasis

### "BPM Keeps Changing"
**Symptoms:** Re-recording gives different BPM each time

**Causes:**
- Inconsistent playing tempo
- Marginal confidence (borderline detection)

**Solutions:**
- Use metronome while practicing before recording
- Lock in tempo with manual tap after first detection
- Enable quantization during recording (future feature)

---

## 📊 Example Scenarios

### Scenario 1: Steady Strumming Pattern
```
User plays: Em - C - G - D progression at 120 BPM
Duration: 30 seconds
Result: "✨ 119 BPM" (99% confidence) ✅
```

### Scenario 2: Fingerpicking Ballad
```
User plays: Slow arpeggios at 70 BPM
Duration: 45 seconds
Result: "✨ 71 BPM" (87% confidence) ✅
```

### Scenario 3: Rubato / Free Tempo
```
User plays: Classical piece with tempo fluctuations
Duration: 60 seconds
Result: "120 BPM" (cyan, no detection) ⚠️
Action: User taps BPM manually or adjusts with +/- buttons
```

### Scenario 4: Half-Time Detection
```
User plays: Upbeat 160 BPM rock riff
Duration: 20 seconds
Result: "✨ 80 BPM" (75% confidence) ⚠️
Action: User taps + button 80 times or uses tap tempo
```

---

## 📁 Files Modified
- `lib/services/tempo_detector.dart` — NEW: BPM detection algorithm
- `lib/state/tab_player_state.dart` — Added `detectedTempo` field and audio buffer
- `lib/views/tab_player_screen.dart` — BPM control UI with auto-indicator
- `CHANGELOG.md` — v1.5.0 release notes

---

**Version:** 1.5.0  
**Last Updated:** 2026-07-30  
**Repository:** [github.com/megafixbom/guitartuner2](https://github.com/megafixbom/guitartuner2)
