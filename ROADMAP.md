# GuitarTuner Enhancement Roadmap

> Saved 2026-07-29. Resume implementation from any section below.

---

## Completed (v1.0.0 - v1.3.0)

- [x] Real-time guitar tuner with YIN algorithm, spring needle gauge, isolate worker
- [x] Guitar Pro-style tab workspace with dual staff (standard notation + TAB)
- [x] Note duration system (whole/half/quarter/eighth/sixteenth) with duration-aware engraving
- [x] Manual note entry via score canvas tap and fretboard tap
- [x] BPM-synchronized playback with audio synthesis
- [x] Live mic recording with pitch transcription and duration inference
- [x] Ghost/muted note detection with X notation and amber badge
- [x] Tap tempo BPM control
- [x] Clear tab with confirmation dialog
- [x] Local JSON session save/load
- [x] 15-fret rosewood fretboard visualizer with 12-TET spacing
- [x] Articulation symbols (slideUp, slideDown, bend, release, hammerOn, pullOff, vibrato)
- [x] Articulation connector curves (slide lines, H/P slurs) in both staves
- [x] Articulation selector chip in toolbar

---

## Priority 1 — Short-Term (v1.4.0)

### Tuplets / Triplets
- [ ] Add `Tuplet` data model (triplet, quintuplet, sextuplet)
- [ ] `NoteDuration` integration: 3 eighth notes in the space of 2
- [ ] Bracket `--3--` rendering above beamed groups in notation
- [ ] Tuplet-aware playback quantizer (rhythm subdivision)
- [ ] UI: tuplet toggle chip next to duration selector

### Beaming / Grouping
- [ ] Beam consecutive eighth/sixteenth notes in standard notation
- [ ] `_drawBeam()` in `TabNotationPainter` connecting note stems horizontally
- [ ] Beam angle logic for ascending/descending pitch patterns
- [ ] Break beam at measure boundaries and rests

### Staccato / Accents
- [ ] Staccato dot (`·`) above/below note head
- [ ] Accent (`>`) and marcato (`^`) marks
- [ ] New `Articulation` variants or separate `NoteAccent` enum
- [ ] Rendering offset logic: above note for stems-down, below for stems-up
- [ ] Playback: staccato shortens note duration 50%

---

## Priority 2 — Medium-Term (v1.5.0)

### Grace Notes
- [ ] `GraceNote` model (pre-note, no duration, small size)
- [ ] Small-sized note head rendering (60% scale) with slash through stem
- [ ] Acciaccatura (slashed) vs appoggiatura (unslashed)
- [ ] Playback: steal duration from parent note

### Tempo / Dynamics / Expression Marks
- [ ] Dynamic markings: `pp`, `p`, `mp`, `mf`, `f`, `ff` below staff
- [ ] Crescendo/decrescendo hairpin symbols (`<` and `>`)
- [ ] Tempo text: "Allegro", "Andante" etc.
- [ ] Fermata symbol over notes/rests
- [ ] Expression text rendering system

### Repeats / Endings
- [ ] Repeat barline (`:|`) with start-repeat (`|:`)
- [ ] 1st/2nd ending brackets (volta brackets)
- [ ] Repeat count field
- [ ] Playback: loop back to start-repeat on first pass, skip on second
- [ ] D.C. al Fine / D.S. al Coda navigation markers

### Ties
- [ ] `isTied` flag on `TabNote` or separate `Tie` connector
- [ ] Curved tie arc between same-pitch consecutive notes
- [ ] Rendering in both standard notation and TAB
- [ ] Playback: tied notes sustain without re-trigger

---

## Priority 3 — Long-Term (v1.6.0+)

### Chords / Polyphony
- [ ] Allow multiple notes at the same beat position on different strings
- [ ] Stacked note heads in standard notation
- [ ] Vertical alignment in TAB across all 6 strings
- [ ] Chord name detection (auto-detect Am, C, G, etc.)
- [ ] Chord diagram box above notation
- [ ] Strum playback: simultaneous trigger of all chord tones

### Alternate Tunings
- [ ] Tuning preset selector (Drop D, Open G, DADGAD, Half Step Down)
- [ ] Per-string reference pitch mapping
- [ ] Tuner auto-detection recalibration
- [ ] Fretboard relabeling for alternate tunings
- [ ] Save/load custom tunings to JSON

### Rests
- [ ] `NoteType` enum distinguishing Note vs Rest
- [ ] Rest rendering (quarter rest, eighth rest, etc.)
- [ ] Rest positions: quarter rest centered on middle line
- [ ] Auto-rest insertion for empty beats in measures

### Key Signatures & Accidentals
- [ ] Key signature display at left of each staff (sharps/flats)
- [ ] `Accidental` enum (sharp, flat, natural, double sharp, double flat)
- [ ] Rendering before note head in notation
- [ ] Key signature auto-detection from note frequencies

### Barre Chords
- [ ] Barre indicator line across multiple strings at same fret
- [ ] Curved bracket or "B" + roman numeral notation
- [ ] Barre rendering in TAB (horizontal bracket across strings)

### Palm Muting
- [ ] `isPalmMuted` flag on `TabNote` (distinct from ghost note)
- [ ] "P.M." text or dashed line in TAB
- [ ] Playback: muted/percussive tone synthesis

### String Bends in Detail
- [ ] Bend amount: full step, half step, 1.5 steps
- [ ] "full", "1/2" text with arrow in TAB
- [ ] Pre-bend and release notation

---

## Priority 4 — Polish & DX

### Performance
- [ ] `RepaintBoundary` wrapping on score canvas for isolated repaint
- [ ] `const` constructors audit for widget rebuild reduction
- [ ] Measure culling: only paint visible measures (horizontal scroll)
- [ ] Isolate-based audio synthesis off main thread

### Export / Import
- [ ] Export tab as PDF with proper music engraving
- [ ] Export as MusicXML for Guitar Pro import
- [ ] MIDI export for playback
- [ ] Share sheet integration (iOS/Android)

### Undo / Redo
- [ ] Command history stack in `TabPlayerState`
- [ ] `undo()` and `redo()` notifier methods
- [ ] Keyboard shortcut or toolbar button

### Multi-Measure Horizontal Scroll
- [ ] `SingleChildScrollView` horizontal wrapping score
- [ ] Viewport-aware measure rendering
- [ ] Auto-scroll to follow playhead

### Accessibility
- [ ] Semantic labels on score and fretboard widgets
- [ ] Screen reader announcements for note changes
- [ ] Sufficient color contrast audit

---

## Not Started / Backlog

- [ ] Metronome click track (audio click on beats)
- [ ] Drum pattern / backing track layer
- [ ] Multi-track tab (lead + rhythm + bass)
- [ ] Cloud sync (Firebase or similar)
- [ ] Social sharing of tabs
- [ ] AI-assisted tab transcription from audio
- [ ] Scale / arpeggio pattern generator overlay
- [ ] Left-handed mode (mirror fretboard)
- [ ] Dark/light theme toggle (beyond current parchment)
- [ ] Capo position setting (fret offset for notation)
- [ ] Strumming pattern notation (arrows above staff)
- [ ] Lyrics line below standard notation
- [ ] Fingerpicking notation (p i m a labels)
- [ ] Slide guitar / bottleneck mode

---

## File Map (key implementation files)

| File | Purpose |
|------|---------|
| `lib/state/tab_player_state.dart` | State model, enums, notifier, serialization, recording |
| `lib/views/tab_player_screen.dart` | UI, toolbar, `TabNotationPainter`, `FretboardPainter` |
| `lib/state/tuner_state.dart` | Tuner state and isolate lifecycle |
| `lib/services/pitch_engine.dart` | YIN pitch engine, noise gate, onset detection |
| `lib/services/pitch_detector.dart` | YIN algorithm implementation |
| `lib/services/audio_service.dart` | Mic permission and ring buffer |
| `test/tuner_test.dart` | Unit tests for DSP, ring buffer, serialization |
