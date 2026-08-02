/// Pitch shifting / key transposition via a phase vocoder.
///
/// Implements the classic "pitch shifting with the phase vocoder" algorithm:
/// 1. STFT the input with a Hann window (analysis hop = frame/4).
/// 2. Track each bin's instantaneous frequency from the phase advance and
///    re-synthesize frames with a different synthesis hop (time-stretch).
/// 3. Linearly resample the stretched signal back to the original duration,
///    which raises/lowers the pitch without changing the length.
///
/// Because the spectral envelope is carried by the magnitudes while only the
/// phases (frequencies) are modified, timbre/formants are preserved far better
/// than plain resampling ("chipmunk" effect is minimized).
///
/// TODO (Future - v2.1.0): On-device TFLite Whisper (offline lyrics)
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Complex in-place radix-2 FFT (forward and inverse).
class Fft {
  final int n;
  final Float64List real;
  final Float64List imag;
  final List<int> _rev;

  /// [n] must be a power of two.
  Fft(int n)
      : n = n,
        real = Float64List(n),
        imag = Float64List(n),
        _rev = List<int>.filled(n, 0) {
    assert((n & (n - 1)) == 0, 'FFT size must be a power of two');
    _buildBitReversal();
  }

  void _buildBitReversal() {
    var log2 = 0;
    var size = n;
    while (size > 1) {
      size >>= 1;
      log2++;
    }
    for (int i = 0; i < n; i++) {
      var rev = 0;
      var x = i;
      for (int b = 0; b < log2; b++) {
        rev = (rev << 1) | (x & 1);
        x >>= 1;
      }
      _rev[i] = rev;
    }
  }

  /// In-place forward transform (unnormalized).
  void forward() {
    _transform(forward: true);
  }

  /// In-place inverse transform (normalized by 1/n).
  void inverse() {
    _transform(forward: false);
    for (int i = 0; i < n; i++) {
      real[i] /= n;
      imag[i] /= n;
    }
  }

  void _transform({required bool forward}) {
    // Bit-reversal permutation
    for (int i = 0; i < n; i++) {
      if (i < _rev[i]) {
        final tr = real[i];
        real[i] = real[_rev[i]];
        real[_rev[i]] = tr;
        final ti = imag[i];
        imag[i] = imag[_rev[i]];
        imag[_rev[i]] = ti;
      }
    }

    final sign = forward ? -1.0 : 1.0;
    for (int len = 2; len <= n; len <<= 1) {
      final ang = sign * 2 * math.pi / len;
      final wlenRe = math.cos(ang);
      final wlenIm = math.sin(ang);
      final half = len >> 1;
      for (int i = 0; i < n; i += len) {
        var wRe = 1.0;
        var wIm = 0.0;
        for (int j = 0; j < half; j++) {
          final uRe = real[i + j];
          final uIm = imag[i + j];
          final vRe = real[i + j + half] * wRe - imag[i + j + half] * wIm;
          final vIm = real[i + j + half] * wIm + imag[i + j + half] * wRe;
          real[i + j] = uRe + vRe;
          imag[i + j] = uIm + vIm;
          real[i + j + half] = uRe - vRe;
          imag[i + j + half] = uIm - vIm;
          final nextRe = wRe * wlenRe - wIm * wlenIm;
          wIm = wRe * wlenIm + wIm * wlenRe;
          wRe = nextRe;
        }
      }
    }
  }
}

/// Shifts the pitch of an audio buffer by a number of semitones.
class PitchShifter {
  /// Analysis hop as a fraction of the frame size (STFT overlap).
  static const double _hopRatio = 0.25;

  /// Shift [samples] by [semitones] (positive = up, negative = down) while
  /// preserving the original duration. Output length matches the input.
  Float32List shiftPitch(
    Float32List samples,
    double semitones, {
    int frameSize = 1024,
  }) {
    if (samples.isEmpty) return Float32List(0);
    if (semitones == 0) return Float32List.fromList(samples);

    final stretchFactor = math.pow(2.0, semitones / 12.0).toDouble();

    if (samples.length < frameSize) {
      // Too short for STFT: fall back to plain linear resampling.
      return _resample(samples, 1.0 / stretchFactor,
          targetLength: samples.length);
    }

    final stretched = _timeStretch(samples, stretchFactor, frameSize);
    return _resample(stretched, 1.0 / stretchFactor,
        targetLength: samples.length);
  }

  /// Phase-vocoder time-stretch of [input] by [stretchFactor].
  Float32List _timeStretch(
    Float32List input,
    double stretchFactor,
    int frameSize,
  ) {
    final n = frameSize;
    final ha = (n * _hopRatio).round(); // analysis hop
    final hs = math.max(1, (ha * stretchFactor).round()); // synthesis hop

    final numFrames = math.max(1, ((input.length - n) ~/ ha) + 1);
    final outLen = (numFrames - 1) * hs + n;
    final output = Float64List(outLen);
    final windowSum = Float64List(outLen);

    final hann = Float64List(n);
    for (int i = 0; i < n; i++) {
      hann[i] = 0.5 * (1.0 - math.cos(2 * math.pi * i / (n - 1)));
    }

    final fft = Fft(n);
    final prevPhase = Float64List(n >> 1);
    final synthPhase = Float64List(n >> 1);

    var inIdx = 0;
    var outIdx = 0;

    for (int frame = 0; frame < numFrames; frame++) {
      // Window the analysis frame.
      for (int i = 0; i < n; i++) {
        fft.real[i] = (inIdx + i < input.length ? input[inIdx + i] : 0.0) *
            hann[i];
        fft.imag[i] = 0.0;
      }
      fft.forward();

      // Phase propagation / instantaneous frequency tracking.
      for (int k = 0; k < (n >> 1); k++) {
        final mag =
            math.sqrt(fft.real[k] * fft.real[k] + fft.imag[k] * fft.imag[k]);
        final phase = math.atan2(fft.imag[k], fft.real[k]);

        var phaseDiff = phase - prevPhase[k] - (2 * math.pi * k * ha) / n;
        while (phaseDiff > math.pi) {
          phaseDiff -= 2 * math.pi;
        }
        while (phaseDiff < -math.pi) {
          phaseDiff += 2 * math.pi;
        }
        final freqPerBin = (2 * math.pi * k) / n + phaseDiff / ha;
        synthPhase[k] += hs * freqPerBin;

        fft.real[k] = mag * math.cos(synthPhase[k]);
        fft.imag[k] = mag * math.sin(synthPhase[k]);
        prevPhase[k] = phase;
      }
      // Rebuild conjugate-symmetric upper bins.
      for (int k = (n >> 1) + 1; k < n; k++) {
        fft.real[k] = fft.real[n - k];
        fft.imag[k] = -fft.imag[n - k];
      }
      fft.inverse();

      // Overlap-add with accumulated-window normalization.
      for (int i = 0; i < n; i++) {
        if (outIdx + i < outLen) {
          output[outIdx + i] += fft.real[i] * hann[i];
          windowSum[outIdx + i] += hann[i] * hann[i];
        }
      }

      inIdx += ha;
      outIdx += hs;
    }

    final result = Float64List(outLen);
    for (int i = 0; i < outLen; i++) {
      result[i] = windowSum[i] > 1e-9 ? output[i] / windowSum[i] : 0.0;
    }
    return Float32List.fromList(result);
  }

  /// Linear-interpolation resample. When [targetLength] is provided the
  /// output is that length, otherwise `input.length / rate` (rounded up).
  Float32List _resample(
    Float32List input,
    double rate, {
    int? targetLength,
  }) {
    final outLen =
        targetLength ?? math.max(1, (input.length * rate).round());
    final out = Float32List(outLen);
    if (input.isEmpty) return out;

    for (int j = 0; j < outLen; j++) {
      final pos = j / rate; // source index (rate > 1 shrinks, < 1 stretches)
      final i0 = pos.floor();
      final i1 = math.min(i0 + 1, input.length - 1);
      final frac = pos - i0;
      final v0 = input[i0.clamp(0, input.length - 1)];
      final v1 = input[i1];
      out[j] = v0 + (v1 - v0) * frac;
    }
    return out;
  }
}

/// Encodes mono float samples (-1..1) as 16-bit PCM WAV bytes.
Uint8List buildWavBytes(Float32List samples, {int sampleRate = 16000}) {
  const bytesPerSample = 2;
  final dataSize = samples.length * bytesPerSample;
  final buffer = ByteData(44 + dataSize);

  void writeAscii(int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  buffer.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little); // PCM chunk size
  buffer.setUint16(20, 1, Endian.little); // PCM format
  buffer.setUint16(22, 1, Endian.little); // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * bytesPerSample, Endian.little); // byte rate
  buffer.setUint16(32, bytesPerSample, Endian.little); // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample
  writeAscii(36, 'data');
  buffer.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final pcm = (clamped * 32767).round().clamp(-32768, 32767);
    buffer.setInt16(44 + i * bytesPerSample, pcm, Endian.little);
  }
  return buffer.buffer.asUint8List();
}

/// Synthesizes a short plucked-guitar-like tone (harmonic stack + decay).
Float32List synthTone(
  double frequency, {
  int sampleRate = 16000,
  double seconds = 0.45,
}) {
  final length = (sampleRate * seconds).round();
  final out = Float32List(length);
  const harmonics = [1.0, 0.5, 0.28, 0.16, 0.09];

  for (int i = 0; i < length; i++) {
    final t = i / sampleRate;
    final decay = math.exp(-5.0 * t);
    var sample = 0.0;
    for (int h = 0; h < harmonics.length; h++) {
      final hf = frequency * (h + 1);
      if (hf > sampleRate / 2) break;
      sample += harmonics[h] * math.sin(2 * math.pi * hf * t);
    }
    out[i] = sample * decay * 0.35;
  }
  return out;
}
