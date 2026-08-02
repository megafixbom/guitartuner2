/// Heuristic vocal-activity detection used to find where singing happens in a
/// recording (complements lyric transcription).
///
/// Frames the audio, estimates each frame's dominant frequency and RMS energy,
/// and marks frames whose dominant pitch falls in the singing range as vocal.
/// A median filter removes isolated frames, then consecutive vocal frames are
/// merged into segments.
///
/// NOTE: This is a lightweight heuristic for locating vocal regions. True
/// guitar/vocal source separation requires ML (Spleeter / Demucs) — see
/// `ML_DETECTION_PLAN.md`.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'pitch_shifter.dart' show Fft;

/// A detected vocal segment in seconds.
class VocalSegment {
  final double start;
  final double end;

  const VocalSegment(this.start, this.end);

  bool contains(double seconds) => seconds >= start && seconds < end;

  double get duration => end - start;
}

/// Detects vocal segments in an audio buffer.
class VocalActivityDetector {
  static const int _frameSize = 2048;
  static const int _hopSize = 1024;

  /// Singing fundamental range (Hz).
  static const double _minVoiceHz = 80.0;
  static const double _maxVoiceHz = 500.0;

  /// Detect vocal segments. [threshold] is the RMS gate (0.0 - 1.0).
  List<VocalSegment> detectVocalSegments(
    Float32List samples,
    int sampleRate, {
    double threshold = 0.02,
  }) {
    if (samples.length < _frameSize) return const [];

    final fft = Fft(_frameSize);
    final frameCount = ((samples.length - _frameSize) ~/ _hopSize) + 1;
    final classifications = List<bool>.filled(frameCount, false);

    final binHz = sampleRate / _frameSize;

    for (int f = 0; f < frameCount; f++) {
      final offset = f * _hopSize;

      var rms = 0.0;
      for (int i = 0; i < _frameSize; i++) {
        final s = samples[offset + i];
        rms += s * s;
      }
      rms = math.sqrt(rms / _frameSize);
      if (rms < threshold) continue;

      for (int i = 0; i < _frameSize; i++) {
        fft.real[i] = samples[offset + i];
        fft.imag[i] = 0.0;
      }
      fft.forward();

      // Dominant frequency below Nyquist.
      var peakBin = 0;
      var peakMag = -1.0;
      for (int k = 1; k < _frameSize ~/ 2; k++) {
        final mag =
            math.sqrt(fft.real[k] * fft.real[k] + fft.imag[k] * fft.imag[k]);
        if (mag > peakMag) {
          peakMag = mag;
          peakBin = k;
        }
      }
      final dominantHz = peakBin * binHz;
      classifications[f] =
          dominantHz >= _minVoiceHz && dominantHz <= _maxVoiceHz;
    }

    _medianSmooth(classifications);
    return _segmentsFromClassifications(classifications, sampleRate);
  }

  /// Replace each value with the majority of its neighborhood (window 5).
  void _medianSmooth(List<bool> values) {
    if (values.length < 3) return;
    final copy = List<bool>.from(values);
    for (int i = 0; i < values.length; i++) {
      var ones = 0;
      var total = 0;
      for (int j = i - 2; j <= i + 2; j++) {
        if (j < 0 || j >= values.length) continue;
        total++;
        if (copy[j]) ones++;
      }
      values[i] = ones > total / 2;
    }
  }

  List<VocalSegment> _segmentsFromClassifications(
      List<bool> classifications, int sampleRate) {
    final segments = <VocalSegment>[];
    var start = -1;
    for (int i = 0; i < classifications.length; i++) {
      if (classifications[i] && start < 0) {
        start = i;
      } else if (!classifications[i] && start >= 0) {
        segments.add(VocalSegment(
          start * _hopSize / sampleRate,
          i * _hopSize / sampleRate,
        ));
        start = -1;
      }
    }
    if (start >= 0) {
      segments.add(VocalSegment(
        start * _hopSize / sampleRate,
        classifications.length * _hopSize / sampleRate,
      ));
    }
    return segments;
  }
}
