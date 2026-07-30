# Screenshot Capture Guide

> **Purpose:** This guide helps you capture consistent, high-quality screenshots for GuitarTuner documentation.
>
> **Total:** 30 screenshots needed  
> **Time Estimate:** 2-3 hours  
> **Tools:** Device/simulator + screenshot software + image editor

---

## 📸 General Guidelines

### Image Specifications
- **Resolution:** 1920×1080 minimum (or native device resolution)
- **Format:** PNG (preferred) or JPG
- **Aspect Ratio:** 16:9 for full interface, 4:3 for close-ups
- **File Size:** <500KB each (compress with https://tinypng.com if needed)

### Naming Convention
```
[screenshot_number]_[feature]_[state].png
Example: 05_bpm_control_manual.png
```

### Capture Best Practices
1. **Clean device:** Use simulator or real device with clean UI (no notifications)
2. **Consistent lighting:** For lifestyle photos, use even, diffused lighting
3. **Focus:** Ensure text is sharp and readable
4. **Annotations:** Use red boxes/circles/arrows consistently (10pt stroke)
5. **Scale:** Show enough context—don't crop too tightly

---

## 📱 Required Screenshots

### Section 1: App Launch & Main Interface (4 screenshots)

#### 01_launch_screen.png
**What to show:**
- App icon and "GuitarTuner" logo
- Loading indicator/spinner
- Version number (1.6.0)

**How to capture:**
1. Launch app
2. Capture immediately on loading screen
3. Use simulator or device in portrait mode

---

#### 02_main_tuner.png
**What to show:**
- Complete tuner interface
- Guitar headstock visualization
- Needle gauge (centered)
- 12 LED dots below headstock
- String selector buttons (E A D G B e)
- AppBar with actions

**How to capture:**
1. Wait for app to finish loading
2. Capture full screen
3. Ensure all UI elements visible (no cut-off)

---

#### 03_interface_annotated.png
**What to show:**
- Same as #02 but with labeled callouts
- Numbered annotations (1-7) pointing to:
  1. AppBar actions
  2. Toolbar
  3. Score canvas
  4. Playhead
  5. Fretboard
  6. Recording indicator
  7. Waveform

**How to capture:**
1. Capture #02 first
2. Open in image editor (Photoshop, GIMP, Figma, Canva)
3. Add numbered circles and leader lines
4. Add legend on right side or bottom

**Tools recommendation:**
- **Free:** GIMP, Figma, Canva
- **Paid:** Photoshop, Affinity Photo
- **Online:** Photopea.com

---

#### 04_toolbar_components.png
**What to show:**
- Close-up of toolbar only
- All 7 components visible:
  - Mode pill
  - BPM control with +/- buttons
  - Key chip (if detected)
  - Chord display (if detected)
  - Articulation chip
  - Duration chip
  - Transport buttons (● ▶ ⏹)
  - Loop button

**How to capture:**
1. Record briefly to activate all elements
2. Zoom in on toolbar area
3. Capture tight crop showing just toolbar
4. OR annotate full screenshot with boxes around each component

---

### Section 2: Recording Process (4 screenshots)

#### 05_bpm_control.png
**What to show:**
- Two states side-by-side:
  - **Left:** "120 BPM" in cyan (before recording)
  - **Right:** "✨ 119 BPM" in green (after auto-detection)

**How to capture:**
1. Launch app, capture BPM display (cyan)
2. Record 20+ seconds of steady playing
3. Stop and wait for processing
4. Capture BPM display (green with ✨)
5. Composite into side-by-side image

---

#### 06_recording_active.png
**What to show:**
- Red pulsing record dot (●)
- Timer showing "REC XX.Xs"
- Waveform visualizer with active bars
- Fretboard with some LED badges lit

**How to capture:**
1. Press record button
2. Start playing guitar
3. Wait until timer shows ~12.3s
4. Capture while playing (ensure waveform bars are active)

**Tip:** Capture multiple frames and pick the clearest

---

#### 07_chord_detection.png
**What to show:**
- Chord names in blue pills above staff
- At least 3 different chords visible (e.g., "Am", "G", "C")
- Corresponding TAB notation below
- Standard notation with key signature

**How to capture:**
1. Record progression: Am → G → C (2 seconds each)
2. Stop and wait for processing
3. Press play
4. Capture when playhead shows all three chords

---

#### 08_processing_complete.png
**What to show:**
- Full tablature (4+ measures)
- Key chip in toolbar (e.g., "Em (82)")
- BPM chip (e.g., "✨ 118 BPM")
- Chord names above staff
- Key signature accidentals (sharps/flats)

**How to capture:**
1. Record 30-second song with clear chords and key
2. Wait 2-3 seconds for processing
3. Capture complete interface
4. Ensure all detection results visible

---

### Section 3: Horizontal Scrolling (1 screenshot)

#### 09_horizontal_scroll.png
**What to show:**
- Measures 5-8 of recording
- Measure numbers visible ("5", "6", "7", "8")
- Scroll indicator or edge of previous measure
- Playhead position mid-way

**How to capture:**
1. Record 60-second song (15+ measures)
2. Swipe horizontally on score canvas
3. Capture when showing measures 5+
4. Show some context of earlier measure on left edge

---

### Section 4: Key Detection (3 screenshots)

#### 10_key_confidence.png
**What to show:**
- Three toolbar states in one composite:
  1. "Em (87)" - green (high confidence >70%)
  2. "Am (62)" - amber (medium confidence 50-70%)
  3. "120 BPM" - cyan, no key chip (low confidence <40%)

**How to capture:**
1. **High conf:** Record strong diatonic progression (I-IV-V in one key)
2. **Med conf:** Record progression with borrowed chords
3. **Low conf:** Record non-diatonic/chromatic line
4. Composite into one image

---

#### 11_key_signature.png
**What to show:**
- Standard notation staff with key signature
- Clear view of sharps (#) or flats (b)
- Corresponding key chip visible

**How to capture:**
1. Record in G Major (one sharp: F#)
2. Wait for processing
3. Capture close-up of left side of staff
4. Show treble clef + sharp on F line

**Alternative keys to capture:**
- D Major (F#, C#) - two sharps
- F Major (Bb) - one flat

---

#### 12_pitch_histogram.png
**What to show:**
- Bar chart with 12 bins (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
- Heights showing frequency of each pitch class
- Highlighted tonic note

**How to create:**
1. This is internal data - requires debug visualization
2. Export pitch class histogram to console
3. Create chart in Excel/Google Sheets
4. OR add temporary debug UI to app
5. Screenshot chart

**Placeholder if time-limited:**
- Use generic histogram image with label "Concept visualization"

---

### Section 5: BPM Detection (3 screenshots)

#### 13_bpm_comparison.png
**What to show:**
- Before/after comparison:
  - **Before:** "120 BPM" cyan
  - **After:** "✨ 121 BPM" green
- Same composition as #05 but different aspect

**How to capture:**
- Similar to #05, show toolbar focus
- Add arrow between states

---

#### 14_bpm_confidence.png
**What to show:**
- Three BPM states:
  1. "✨ 120 (78%)" - green
  2. "✨ 118" - green, no percentage
  3. "120" - cyan (no auto-detection)

**How to capture:**
- Similar process to #10
- Vary recording consistency for different confidences

---

#### 15_beat_grid.png
**What to show:**
- **(FUTURE v1.7.0)** Beat markers on waveform
- Vertical lines on beats
- Downbeat highlighted

**How to capture:**
- **Not yet implemented**
- Use placeholder: "Coming in v1.7.0 - Smart Metronome"
- OR mock up concept visualization in image editor

---

### Section 6: Chord Detection (3 screenshots)

#### 16_chord_progression.png
**What to show:**
- Full measure with chord name above
- Example: "Am → G → C → F" progression
- Blue pill boxes clearly visible
- Standard notation below

**How to capture:**
- Record common progression (I-V-vi-IV)
- Capture when all 4 chords visible
- Ensure chord names not cut off

**Common progressions to use:**
- I-V-vi-IV: C → G → Am → F
- 12-bar blues: I-I-I-I → IV-IV-I-I → V-IV-I-I
- ii-V-I: Dm → G7 → C

---

#### 17_chord_accuracy.png
**What to show:**
- Composite of:
  - **High accuracy:** "Am" (87%) - stable
  - **Marginal:** "Cadd9" (54%) - may flicker
  - **Rejected:** (no display, <50% confidence)

**How to capture:**
1. Clean major/minor triads for high accuracy
2. Complex voicings/add9 for marginal
3. Ambiguous/incomplete chords for rejected

---

#### 18_barre_chords.png
**What to show:**
- F major (1st fret barre)
- Bm (2nd fret barre)
- Corresponding TAB fingering
- Detected chord names

**How to capture:**
1. Play barre chords clearly
2. Ensure all 6 strings not muted
3. Capture TAB showing barre position
4. Show detected "F" and "Bm" names

---

### Section 7: Tablature Reading (4 screenshots)

#### 19_dual_staff.png
**What to show:**
- Standard notation and TAB staff side-by-side
- Vertical alignment of notes
- Treble clef visible
- String labels (e B G D A E) visible

**How to capture:**
- Record simple melody
- Capture close-up of left portion of staff
- Ensure both staves in frame

---

#### 20_note_durations.png
**What to show:**
- All 5 duration types with labels:
  1. Whole note (𝅝)
  2. Half note (𝅗𝅥)
  3. Quarter note (𝅘𝅥)
  4. Eighth note (𝅘𝅥𝅮)
  5. Sixteenth note (𝅘𝅥𝅯)
- Duration value in text (e.g., "4 beats", "1 beat")

**How to create:**
1. Record melody using all duration types
2. Capture close-up
3. Add labels in image editor OR
4. Create diagram separately in vector tool

---

#### 21_articulations.png
**What to show:**
- Examples of each articulation:
  - Hammer-on (h)
  - Pull-off (p)
  - Slide up (/)
  - Slide down (\)
  - Bend (b)
  - Vibrato (~)
  - Ghost note (X)

**How to capture:**
1. Record riff with all articulations
2. Capture close-ups of each
3. Composite into single image
4. Add labels explaining each symbol

---

#### 22_scrolling.png
**What to show:**
- Measures beyond first 4
- Horizontal scroll in progress
- Measure numbers visible

**How to capture:**
- Already captured as #09
- Use different scroll position/measure range
- Show 8+ measures

---

### Section 8: Playback & Editing (3 screenshots)

#### 23_transport_buttons.png
**What to show:**
- Close-up of transport controls
- 4 button states:
  1. Record (●) red
  2. Play (▶) green
  3. Stop (⏹)
  4. Loop (🔁) highlighted

**How to capture:**
- Capture buttons in action
- OR capture 4 separate states and composite

---

#### 24_manual_entry.png
**What to show:**
- Duration selector chip highlighted (e.g., "1/4" amber)
- Articulation selector (e.g., "h" selected)
- Note being added via tap on staff/fretboard
- Ghost note or feedback on tap

**How to capture:**
1. Select duration (tap duration chip)
2. Tap on staff to add note
3. Capture mid-action (note appearing)

---

#### 25_clear_dialog.png
**What to show:**
- Confirmation dialog:
  - Title: "Clear Tab?"
  - Body: "This will delete all notes."
  - Buttons: "Cancel" and "Clear"

**How to capture:**
1. Tap Clear button in AppBar
2. Capture dialog immediately
3. Ensure text fully visible

---

### Section 9: Lifestyle & Reference (5 screenshots)

#### 26_mic_position.png
**What to show:**
- Guitar positioned 1-2 feet from device
- Device on stand or table
- Soundhole aimed at microphone
- Good lighting

**How to capture:**
1. Set up guitar on stand or held
2. Position device 1-2 ft away
3. Take photo from side angle
4. Show distance clearly
5. Add arrow/text overlay for 1-2 ft distance

**Equipment:**
- Tripod or phone stand
- Good lighting (natural or softbox)
- Clean background

---

#### 27_issues_comparison.png
**What to show:**
- Two states side-by-side:
  - **Good:** Clear detection (chords, key, BPM all visible)
  - **Bad:** No detection (empty staff, no chips)
- Annotated with reasons

**How to capture:**
1. Capture good recording (Section 2-6 screenshots)
2. Capture poor recording (too noisy, too short, no clear notes)
3. Composite with red X / green check marks
4. Add text annotations

---

#### 28_toolbar_legend.png
**What to show:**
- Toolbar with all components labeled
- Lines/leaders pointing to each element
- Text labels: "Mode Pill", "BPM Control", "Key Chip", etc.

**How to capture:**
- Use #04 as base
- Add callouts in image editor

---

#### 29_common_chords.png
**What to show:**
- Chord chart showing common progressions:
  - I-V-vi-IV
  - 12-bar blues
  - ii-V-I
- Chord diagrams or chord names
- Key context (e.g., "in C major: C → G → Am → F")

**How to create:**
1. Use GuitarTuner to detect each chord
2. OR create chord diagram separately
3. Assemble into reference card layout
4. Add key context text

---

#### 30_fretboard_notes.png
**What to show:**
- Complete fretboard diagram (frets 0-12)
- All note names labeled (E F G A B C D with accidentals)
- Highlighted root notes

**How to create:**
1. Screenshot GuitarTuner fretboard
2. OR use standard guitar fretboard diagram
3. Add note name labels in image editor
4. Highlight naturals vs accidentals

**Reference:** https://www.fender.com/articles/chords/guitar-note-chart

---

## 🛠️ Tools & Software

### Screenshot Capture
| Platform | Tool |
|----------|------|
| **iOS Simulator** | Cmd+S or Screenshot button |
| **Android Emulator** | Camera icon in toolbar |
| **Physical iOS** | Power + Volume Up |
| **Physical Android** | Power + Volume Down |
| **Web Browser** | Cmd/Ctrl+Shift+P → "Capture full size screenshot" |

### Image Editing
| Type | Free | Paid |
|------|------|------|
| **Raster** | GIMP, Photopea | Photoshop, Affinity Photo |
| **Vector** | Figma, Inkscape | Illustrator, Affinity Designer |
| **Quick** | Canva | - |

### Compression
- **Online:** https://tinypng.com
- **Desktop:** ImageOptim (macOS), FileOptimizer (Windows)
- **CLI:** `pngquant input.png --quality=65-80`

---

## ✅ Quality Checklist

Before adding screenshots to documentation:

- [ ] Text is sharp and readable (no blur)
- [ ] All UI elements fully visible (not cut-off)
- [ ] Consistent sizing across all screenshots (±50px)
- [ ] Colors accurate (check toolbar chip colors)
- [ ] Annotations consistent style (same color/size/line weight)
- [ ] File size <500KB (compressed if needed)
- [ ] Filename matches convention (e.g., `05_bpm_control.png`)
- [ ] Saved to `docs/screenshots/` folder

---

## 📤 Final Steps

After capturing all 30 screenshots:

1. **Organize files:**
   ```bash
   mkdir -p docs/screenshots
   mv *.png docs/screenshots/
   ```

2. **Verify in documentation:**
   - Open `docs/USER_GUIDE_WITH_SCREENSHOTS.md`
   - Check all image paths correct
   - Preview markdown in editor

3. **Convert to PDF/DOCX:**
   ```bash
   cd docs/scripts
   ./convert_to_pdf.sh
   ./convert_to_docx.sh
   ```

4. **Commit to git:**
   ```bash
   git add docs/screenshots/
   git commit -m "docs: add 30 screenshots for user guide"
   git push
   ```

---

**Estimated time:** 2-3 hours  
**Difficulty:** Intermediate  
**Tools needed:** Device/emulator + image editor

**Questions?** Refer to example screenshots in similar open-source projects or ask the team.
