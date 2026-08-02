# Feature Ideas — Prioritized List

**Date:** 2026-08-01  
**Status:** Ideas / backlog — not yet implemented

Prioritized ideas for GuitarTuner beyond the current roadmap
(`ROADMAP.md`) and the ML opportunities (`ML_DETECTION_PLAN.md`).

---

## P1 — High value, builds on existing features

| # | Feature | Notes |
|---|---------|-------|
| 1 | **Scale detection (v1.8.0)** | ✅ DONE — 12 scale patterns, toolbar chip, fretboard scale-tone overlay; follow-ups: progression-compatible scales, arpeggio detection |
| 2 | **Chord diagram library** | Fretboard grid showing finger positions for detected chords |
| 3 | **PDF / MusicXML / MIDI export** | Share tabs with other tools (Guitar Pro import path) |
| 4 | **Practice feedback** | Score accuracy of recorded playback against the tab (per-note pitch/timing) |
| 5 | **Alternate tunings** | Drop D, Open G, DADGAD, half-step down; retune fretboard + tuner |

## P2 — Audio engine enhancements

| # | Feature | Notes |
|---|---------|-------|
| 6 | **Pitch shifting (v1.9.0)** | Phase vocoder, ±12 semitones, tempo independent |
| 7 | **Time-stretch / slow-practice loops** | Slower playback without pitch change |
| 8 | **Noise reduction / denoise** | Clean up recordings before detection |
| 9 | **Guitar amp & effect modeling** | Cab sim / distortion for playback tone |

## P3 — Deeper audio analysis

| # | Feature | Notes |
|---|---------|-------|
| 10 | **Strumming-pattern recognition** | Arrows above staff from detected strums |
| 11 | **Genre / playing-style classification** | Small classifier over chroma/rhythm features |
| 12 | **Multi-track tabs** | Lead + rhythm + bass on separate tracks |
| 13 | **AI-assisted full-song transcription** | Audio → tab; pairs with lyric transcription (v2.0.0) |

## P4 — UI / DX polish

| # | Feature | Notes |
|---|---------|-------|
| 14 | **Undo/redo** | Command history in `TabPlayerState` |
| 15 | **Cloud sync** | Save/load tabs across devices |
| 16 | **Dark/light theme toggle** | Beyond current parchment theme |
| 17 | **Capo position setting** | Fret offset applied to notation |
| 18 | **Left-handed mode** | Mirror fretboard |
| 19 | **Audio waveform + beat-grid visualization** | Visualize the unified recording buffer |

---

## Suggested next picks

1. **Pitch shifting (v1.9.0)** — the roadmap's recommended next feature; phase
   vocoder for independent tempo/pitch control.
2. **Practice feedback** — high value for users, builds on the recording and
   playback pipeline already in place.
3. **PDF/MusicXML export** — unlocks sharing and interop with notation tools.

---

## Relationship to other docs

- See `ROADMAP.md` for the versioned feature roadmap.
- See `ML_DETECTION_PLAN.md` for ML-specific detection opportunities.
