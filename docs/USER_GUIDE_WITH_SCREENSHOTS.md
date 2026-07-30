# GuitarTuner User Guide

> **Version:** 1.6.0  
> **Last Updated:** 2026-07-30  
> **Platform:** iOS & Android  
> **Repository:** [github.com/megafixbom/guitartuner2](https://github.com/megafixbom/guitartuner2)

---

## 📖 Table of Contents

1. [Quick Start](#quick-start)
2. [Interface Overview](#interface-overview)
3. [Recording Your Song](#recording-your-song)
4. [Understanding Key Detection](#understanding-key-detection)
5. [Understanding BPM Detection](#understanding-bpm-detection)
6. [Understanding Chord Detection](#understanding-chord-detection)
7. [Reading the Tablature](#reading-the-tablature)
8. [Playback & Editing](#playback--editing)
9. [Tips & Troubleshooting](#tips--troubleshooting)

---

## Quick Start

### Launching the App

![Screenshot: App Launch Screen](screenshots/01_launch_screen.png)
> **Figure 1:** App launch screen showing GuitarTuner logo and loading indicator.
> **How to capture:** Run app on device/simulator, capture initial loading screen.

```bash
flutter run
```

### Main Interface After Launch

![Screenshot: Main Tuner Interface](screenshots/02_main_tuner.png)
> **Figure 2:** Main tuner interface with guitar headstock, needle gauge, and LED meter.
> **How to capture:** After app loads, you'll see the tuner screen. Capture the full interface showing:
> - Acoustic headstock visualization
> - Spring physics needle gauge (centered)
> - 12-dot LED level meter below headstock
> - String selector buttons (E A D G B e)

---

## Interface Overview

### Complete UI Layout

![Screenshot: Full Interface Annotated](screenshots/03_interface_annotated.png)
> **Figure 3:** Complete interface with callouts showing all major components.
> **What to annotate:**
> 1. AppBar actions (Save, Load, Loop, Clear, Back)
> 2. Toolbar (Mic mode indicator, BPM control, Key chip, Chord display, Articulation selector, Duration selector, Transport buttons)
> 3. Score canvas (Standard notation + TAB staff)
> 4. Playhead (red line with arrow)
> 5. Fretboard visualizer (15 frets, LED badges)
> 6. Recording indicator (red pulsing dot + timer)
> 7. Waveform visualizer (12-bar animated)

### Toolbar Components

![Screenshot: Toolbar Close-up](screenshots/04_toolbar_components.png)
> **Figure 4:** Close-up of toolbar showing all interactive elements.
> **Elements to show:**
> - **Mode pill**: Shows "🎤 Live Mic" or "🎵 Recording"
> - **BPM control**: Shows current BPM (e.g., "120") with +/- buttons
> - **Key chip**: Shows detected key (e.g., "Em (78)") with green highlight
> - **Chord display**: Shows current chord in blue pill (e.g., "Am")
> - **Articulation chip**: Shows selected articulation (e.g., "/", "h", "p")
> - **Duration chip**: Shows selected duration (e.g., "1/4", "1/8")
> - **Transport buttons**: Record (●), Play (▶), Stop (⏹)

---

## Recording Your Song

### Step 1: Set Tempo (Optional)

![Screenshot: BPM Control](screenshots/05_bpm_control.png)
> **Figure 5:** BPM control showing manual vs auto-detected tempo.
> **Capture two states:**
> - **Manual**: Cyan text, no icon (e.g., "120 BPM")
> - **Auto-detected**: Green text + ✨ icon (e.g., "✨ 118 BPM")
> **How to capture:** 
> 1. Before recording: shows manual BPM (cyan)
> 2. After recording: shows auto-detected BPM (green) if confident

### Step 2: Press Record

![Screenshot: Recording Active](screenshots/06_recording_active.png)
> **Figure 6:** Recording in progress with timer, waveform, and pulsing indicator.
> **What to capture:**
> - Red pulsing dot (animated - capture mid-pulse)
> - Timer readout (e.g., "REC 12.3s")
> - Waveform visualizer with active bars (play guitar while capturing)
> - Fretboard showing live note detection (green LED badges)

**How to capture:**
1. Press record button (●)
2. Start playing guitar
3. Capture screen when timer shows ~10-15 seconds
4. Ensure waveform bars are active (green/amber/red)

### Step 3: Play Your Song

![Screenshot: Chord Detection in Action](screenshots/07_chord_detection.png)
> **Figure 7:** Chord names appearing above notation staff during playback.
> **What to capture:**
> - Blue pill chord names above staff (e.g., "Am", "G", "C", "F")
> - Corresponding notes on TAB staff
> - Standard notation with key signature
> - Playhead position (red line)

**How to capture:**
1. Record a chord progression (e.g., Am-G-C-F, 2 seconds per chord)
2. Stop recording and wait for processing
3. Press play
4. Capture when playhead is mid-progression showing chord names

### Step 4: Stop and Process

![Screenshot: Processing Complete](screenshots/08_processing_complete.png)
> **Figure 8:** Full tablature with all detection results after processing.
> **What to capture:**
> - Complete tablature (all measures visible, scroll if needed)
> - Key chip in toolbar (e.g., "Em (82)")
> - BPM chip (e.g., "✨ 121 BPM")
> - Chord names above staff for each measure
> - Key signature accidentals on standard notation staff

**How to capture:**
1. Press stop after recording (15-30 seconds of playing)
2. Wait 2-3 seconds for processing
3. Capture full interface showing all detection results

### Step 5: Review Results

![Screenshot: Horizontal Scroll](screenshots/09_horizontal_scroll.png)
> **Figure 9:** Scrolled view showing measures 5-8 of longer recording.
> **What to capture:**
> - Measures beyond first 4 (showing scroll capability)
> - Measure numbers visible (e.g., "5", "6", "7", "8")
> - Continued chord progression
> - Playhead position near end

**How to capture:**
1. Record longer song (45-60 seconds)
2. Swipe horizontally on score canvas
3. Capture when showing measures 5+

---

## Understanding Key Detection

### Key Chip Display

![Screenshot: Key Chip Confidence Levels](screenshots/10_key_confidence.png)
> **Figure 10:** Three states of key detection confidence.
> **Create composite image showing:**
> - **High confidence (>70%)**: Green border, green text, e.g., "Em (87)"
> - **Medium confidence (50-70%)**: Amber border, amber text, e.g., "Am (62)"
> - **Low confidence (<50%)**: Gray, no display (fallback to manual)

**How to capture:**
1. Record clear diatonic progression → high confidence
2. Record ambiguous/atonic passage → medium confidence
3. Record single-note non-diatonic line → low/no detection

### Key Signature on Staff

![Screenshot: Key Signature Accidentals](screenshots/11_key_signature.png)
> **Figure 11:** Key signature accidentals at start of standard notation staff.
> **What to capture:**
> - Sharp symbols (#) on correct staff lines/spaces
> - OR flat symbols (b) on correct positions
> - Correspondence with detected key chip

**Examples to capture:**
- **G Major / E Minor**: One sharp (F#) on top line
- **D Major / B Minor**: Two sharps (F#, C#)
- **F Major / D Minor**: One flat (Bb) on middle line

### Pitch Class Histogram Visualization

![Screenshot: Pitch Class Distribution](screenshots/12_pitch_histogram.png)
> **Figure 12:** Visual representation of pitch class distribution (for documentation).
> **What to show:** Bar chart with 12 bins (C, C#, D... B) showing frequency of occurrence.
> **Note:** This is internal data - may need to add debug visualization.

---

## Understanding BPM Detection

### Auto-Detected BPM

![Screenshot: BPM Before and After](screenshots/13_bpm_comparison.png)
> **Figure 13:** Side-by-side comparison of manual vs auto-detected BPM.
> **Create composite showing:**
> - **Before recording**: "120 BPM" in cyan (default/manual)
> - **After recording**: "✨ 119 BPM" in green (auto-detected)

### BPM Confidence Indicator

![Screenshot: BPM Confidence States](screenshots/14_bpm_confidence.png)
> **Figure 14:** Different BPM detection confidence levels.
> **Show three states:**
> - **High (>70%)**: Green highlight, solid icon, e.g., "✨ 120 (78%)"
> - **Medium (40-70%)**: Green highlight, no percentage shown
> - **Low (<40%)**: No auto-detection, stays cyan manual BPM

### Beat Grid Visualization

![Screenshot: Beat Grid Overlay](screenshots/15_beat_grid.png)
> **Figure 15:** (Future feature) Beat grid overlay on waveform showing detected downbeats.
> **Note:** Not yet implemented - placeholder for v1.7.0 smart metronome.

---

## Understanding Chord Detection

### Chord Names Above Staff

![Screenshot: Chord Progression Display](screenshots/16_chord_progression.png)
> **Figure 16:** Chord names (Am, G, C, F) displayed in blue pills above notation staff.
> **What to capture:**
> - Blue semi-transparent pill boxes
> - Bold chord names centered over measures
> - Correspondence with TAB notes below
> - Measure barlines aligned with chord changes

**How to capture:**
1. Record clear chord progression (4 chords, 1 measure each)
2. Wait for processing
3. Capture full measure sequence

### Chord Confidence Examples

![Screenshot: Chord Detection Accuracy](screenshots/17_chord_accuracy.png)
> **Figure 17:** Examples of high vs marginal chord detections.
> **Create composite showing:**
> - **High confidence (>80%)**: "Am" clearly visible
> - **Marginal (50-60%)**: Chord shown but may flicker
> - **Rejected (<50%)**: No chord name displayed

### Complex Chord Voicings

![Screenshot: Barre Chord Detection](screenshots/18_barre_chords.png)
> **Figure 18:** Detection of barre chords (e.g., F major at 1st fret, Bm at 2nd fret).
> **What to capture:**
> - Barre chord voicings in TAB
> - Corresponding chord names detected
> - Multiple fingered positions

---

## Reading the Tablature

### Dual Staff System

![Screenshot: Standard + TAB Staff](screenshots/19_dual_staff.png)
> **Figure 19:** Side-by-side comparison of standard notation and TAB.
> **What to annotate:**
> - **Top staff**: 5-line standard notation with treble clef
> - **Bottom staff**: 6-line TAB with string labels (e B G D A E)
> - **Note alignment**: Vertical alignment between staves
> - **Duration flags**: Quarter, eighth, sixteenth notes

### Note Duration Symbols

![Screenshot: Note Duration Examples](screenshots/20_note_durations.png)
> **Figure 20:** All note duration types with labels.
> **Show examples of:**
> - Whole note (𝅝): Open oval, no stem (4 beats)
> - Half note (𝅗𝅥): Open oval, with stem (2 beats)
> - Quarter note (𝅘𝅥): Filled circle, stem (1 beat)
> - Eighth note (𝅘𝅥𝅮): Filled circle, stem + 1 flag (1/2 beat)
> - Sixteenth note (𝅘𝅥𝅯): Filled circle, stem + 2 flags (1/4 beat)

### Articulation Symbols

![Screenshot: Articulation Markings](screenshots/21_articulations.png)
> **Figure 21:** All articulation symbols with explanations.
> **Show examples of:**
> - **Hammer-on (h)**: Curved slur with "h" label between notes
> - **Pull-off (p)**: Curved slur with "p" label
> - **Slide up (/)**: Diagonal line ascending
> - **Slide down (\\)**: Diagonal line descending
> - **Bend (b)**: "b" symbol next to fret number
> - **Vibrato (~)**: "~" symbol next to fret number
> - **Ghost note (X)**: "X" instead of fret number (amber badge)

### Horizontal Scrolling

![Screenshot: Multi-Measure Scroll](screenshots/22_scrolling.png)
> **Figure 22:** Horizontal scroll showing 8+ measures.
> **What to capture:**
> - Scroll position indicator (if available)
> - Measures extending beyond screen width
> - Continuous staff lines across measures

---

## Playback & Editing

### Playback Controls

![Screenshot: Transport Buttons](screenshots/23_transport_buttons.png)
> **Figure 23:** Close-up of transport button states.
> **Show states:**
> - **Stopped**: All buttons neutral
> - **Playing**: Play button highlighted green (▶)
> - **Recording**: Record button red pulsing (●)
> - **Looping**: Loop icon highlighted (🔁)

### Manual Note Entry

![Screenshot: Tap-to-Add Notes](screenshots/24_manual_entry.png)
> **Figure 24:** Adding notes manually by tapping score/fretboard.
> **What to capture:**
> - Note appearing where tapped on staff
> - Duration selector active (e.g., "1/4" highlighted)
> - Articulation selector active (e.g., "h" selected)

### Clear Tab Confirmation

![Screenshot: Clear Tab Dialog](screenshots/25_clear_dialog.png)
> **Figure 25:** Confirmation dialog before clearing all notes.
> **What to capture:**
> - Alert dialog with "Clear Tab?" title
> - "Cancel" and "Clear" buttons
> - Warning message "This will delete all notes"

---

## Tips & Troubleshooting

### Optimal Recording Setup

![Screenshot: Proper Mic Position](screenshots/26_mic_position.png)
> **Figure 26:** (Lifestyle photo) Guitar positioned 1-2 feet from device microphone.
> **What to show:**
> - Device on stand/tablet holder
> - Guitar soundhole aimed at mic
> - Distance indicator (1-2 ft)

### Common Issues Visual Guide

![Screenshot: Detection Issues Comparison](screenshots/27_issues_comparison.png)
> **Figure 27:** Side-by-side comparison of correct vs problematic recordings.
> **Show:**
> - **Good**: Clear chord detection, stable BPM
> - **Bad**: No detection, erratic BPM (too noisy, too short, etc.)

---

## Appendix: Quick Reference Card

![Screenshot: ToolbarLegend](screenshots/28_toolbar_legend.png)
> **Figure 28:** Annotated toolbar with all button functions labeled.

![Screenshot: ChordChart](screenshots/29_common_chords.png)
> **Figure 29:** Common chord progressions (I-V-vi-IV, 12-bar blues, etc.)

![Screenshot: FretboardNotes](screenshots/30_fretboard_notes.png)
> **Figure 30:** Fretboard diagram with note names (E F G A B C D) at each fret.

---

## Document Information

**Created:** 2026-07-30  
**Version:** 1.6.0  
**Total Screenshots:** 30 placeholders  
**Status:** Screenshots pending capture  

### Screenshot Capture Checklist

- [ ] 01_launch_screen.png
- [ ] 02_main_tuner.png
- [ ] 03_interface_annotated.png
- [ ] 04_toolbar_components.png
- [ ] 05_bpm_control.png
- [ ] 06_recording_active.png
- [ ] 07_chord_detection.png
- [ ] 08_processing_complete.png
- [ ] 09_horizontal_scroll.png
- [ ] 10_key_confidence.png
- [ ] 11_key_signature.png
- [ ] 12_pitch_histogram.png
- [ ] 13_bpm_comparison.png
- [ ] 14_bpm_confidence.png
- [ ] 15_beat_grid.png
- [ ] 16_chord_progression.png
- [ ] 17_chord_accuracy.png
- [ ] 18_barre_chords.png
- [ ] 19_dual_staff.png
- [ ] 20_note_durations.png
- [ ] 21_articulations.png
- [ ] 22_scrolling.png
- [ ] 23_transport_buttons.png
- [ ] 24_manual_entry.png
- [ ] 25_clear_dialog.png
- [ ] 26_mic_position.png
- [ ] 27_issues_comparison.png
- [ ] 28_toolbar_legend.png
- [ ] 29_common_chords.png
- [ ] 30_fretboard_notes.png

---

**Next Steps:**
1. Run app on device/simulator
2. Capture screenshots per descriptions above
3. Save to `docs/screenshots/` folder
4. Run conversion script to generate PDF/DOCX

**For PDF/DOCX conversion, see:** `docs/scripts/README.md`
