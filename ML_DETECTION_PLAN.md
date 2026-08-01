# ML Detection Opportunities — Discussion Notes

**Date:** 2026-08-01  
**Status:** Discussion / proposal — nothing implemented yet

---

## Summary

Machine learning can improve the current heuristic-based sound detection
pipeline in GuitarTuner. This document captures the options discussed and the
recommended next step.

---

## Current Detection Pipeline (no ML)

| Feature | Current approach | Notes |
|---------|------------------|-------|
| **Pitch detection** | YIN algorithm (monophonic) | Good for single notes |
| **Key detection** | Pitch class histogram + Krumhansl-Schmiedler profiles | Works well, no ML needed |
| **BPM detection** | Spectral flux + IOI histogram | Heuristic thresholds can be fragile |
| **Chord detection** | Spectral peaks + chord template matching | Heuristic; struggles with distortion/effects |

---

## Where ML Helps (ranked by value)

| # | Feature | ML approach | Why |
|---|---------|-------------|-----|
| 1 | **Onset detection** (BPM) | Small CNN on spectrogram frames | Removes fragile threshold tuning; hardens tempo detection |
| 2 | **Chord recognition** | CNN on chroma/spectrogram features | More robust to distortion/effects; better on real recordings |
| 3 | **Multi-pitch / polyphonic** | CREPE or Google Magenta "Onsets & Frames" | Required for true multi-note guitar transcription |
| 4 | **Source separation** | Spleeter / Demucs (converted to TFLite) | Splits vocals vs guitar — prerequisite for lyric transcription |
| 5 | **Lyric transcription** | Whisper API (cloud) | Already planned as v2.0.0; ML-based service |

---

## Feasibility in Flutter

- **On-device inference**: `tflite_flutter` package with small `.tflite` models
  (CNN chord / onset classifiers).
- **Latency**: On-device CNN inference is feasible in real-time on modern
  phones for small models (chromagram input).
- **Key detection** stays as-is (histogram + profile matching) — no ML required.

---

## Recommendation

Start with one of:

1. **ML onset detector** — smallest model, biggest robustness win for the
   existing BPM detection feature.
2. **Chroma-CNN chord classifier** — chord detection is the flagship feature;
   ML would make it more accurate on real-world audio.

---

## Not Started / Backlog

- [ ] Evaluate TFLite integration path (model conversion, package setup)
- [ ] ML onset detector prototype (CNN on spectrogram frames)
- [ ] Chroma-CNN chord classifier prototype
- [ ] Multi-pitch transcription model (CREPE / Onsets & Frames)
- [ ] Source separation for vocals vs guitar (prerequisite for lyric transcription)
