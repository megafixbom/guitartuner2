# Lyric Transcription — User Guide

## What It Does

Transcribes the vocals from your recorded take into timestamped lyrics using the
OpenAI Whisper speech-to-text API, then displays them karaoke-style below the
fretboard as the playhead advances. Lyrics can be copied to the clipboard in the
LRC (LyRiCs) subtitle format for use in media players.

---

## Setup: Your API Key

Whisper is a hosted API, so you need your own key. GuitarTuner never reads a key
from the agent's environment — you supply it yourself.

1. Create an OpenAI account and obtain an API key.
2. Build/run the app with the key injected as a compile-time define:

   ```bash
   flutter run --dart-define=USER_WHISPER_API_KEY=your-key-here
   ```

   The same flag works with `flutter build` and `flutter drive`.

Alternatively, pass a key at runtime to `transcribeRecordingLyrics(apiKey: ...)`
in `lib/state/tab_player_state.dart`.

---

## How to Use

1. Press **Record** and play your take (voice + guitar).
2. Press **Stop** — the audio is captured into the unified recording buffer.
3. Tap the **LRC** chip in the toolbar (it becomes enabled once a recording
   exists). It shows a spinner while transcription runs.
4. When done, the lyrics panel appears below the fretboard with the current
   line highlighted as the playhead moves (karaoke style).
5. Tap the **copy** icon in the panel header to copy the LRC to the clipboard.
   Tap the **close** icon to clear the lyrics.

If no API key is configured, the panel shows an error telling you to pass
`--dart-define=USER_WHISPER_API_KEY=...`.

---

## How It Works

### Transcription Pipeline
```
Your Recording (unified buffer)
        ↓
buildWavBytes() → 16-bit mono WAV
        ↓
Whisper /audio/transcriptions (multipart POST)
        ↓
JSON segments + word timestamps
        ↓
LyricsTranscriber.parseWhisperResponse()
        ↓
LyricLine list (withTightenedEnds aligns line boundaries)
        ↓
Karaoke lyrics panel + LRC export
```

### Vocal Activity Detection
`VocalActivityDetector` (`lib/services/vocal_detector.dart`) frames the audio,
estimates each frame's dominant frequency via FFT and its RMS energy, and marks
frames in the singing range (~80-500 Hz) as vocal. A median filter removes
isolated frames and consecutive vocal frames are merged into `VocalSegment`s.

This is a lightweight heuristic for locating vocal regions. True guitar/vocal
source separation requires ML (Spleeter / Demucs) — see `ML_DETECTION_PLAN.md`.

---

## Files

| File | Purpose |
|------|---------|
| `lib/services/lyrics_transcriber.dart` | Whisper API call, `LyricLine`/`LyricWord`, LRC export/import, end alignment |
| `lib/services/vocal_detector.dart` | Vocal-activity segments from the recording |
| `lib/state/tab_player_state.dart` | `detectedLyrics`, `vocalSegments`, transcription notifier methods |
| `lib/views/tab_player_screen.dart` | LRC toolbar chip, karaoke lyrics panel |

---

## Notes

- Transcription runs against your recorded buffer only; it does not upload the
  tab, state, or any other data.
- Word-level timestamps are preserved in `LyricLine.words` and are emitted by
  Whisper when `timestamp_granularities[]=word` is requested.
- LRC parsing (`parseLrc`) supports importing existing `.lrc` files via
  `loadLyricsFromLrc`.
