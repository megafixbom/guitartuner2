import 'dart:math' as math;
import 'dart:typed_data';

/// Automatic BPM (tempo) detector using onset detection and IOI histogram
///
/// Algorithm:
/// 1. Compute spectral flux from audio frames
/// 2. Detect onset peaks (local maxima)
/// 3. Calculate inter-onset intervals (IOI)
/// 4. Build IOI histogram
/// 5. Find most common IOI → convert to BPM
/// 6. Refine with beat grid estimation
///
/// TODO (Future - v2.0.0): Lyric transcription (vocal activity detection)
/// - Whisper API / Google Speech-to-Text integration
class TempoDetector {
  final int sampleRate;
  final double minBpm;
  final double maxBpm;

  TempoDetector({
    this.sampleRate = 16000,
    this.minBpm = 60.0,
    this.maxBpm = 200.0,
  });

  /// Detect BPM from audio samples
  DetectedTempo? detect(Float32List audioSamples) {
    if (audioSamples.length < sampleRate) return null; // Need at least 1 second

    // Step 1: Compute spectral flux (onset detection function)
    final flux = _computeSpectralFlux(audioSamples);

    // Step 2: Detect onset peaks
    final onsetTimes = _detectOnsetPeaks(flux);

    if (onsetTimes.length < 4) return null; // Need at least 4 onsets

    // Step 3: Calculate inter-onset intervals
    final iois = _calculateIOIs(onsetTimes);

    if (iois.isEmpty) return null;

    // Step 4: Build IOI histogram and find tempo candidates
    final candidates = _findTempoCandidates(iois);

    if (candidates.isEmpty) return null;

    // Step 5: Select best BPM candidate
    final bestCandidate = candidates.reduce((a, b) =>
        a.strength > b.strength ? a : b);

    // Step 6: Generate beat grid
    final beats = _generateBeatGrid(bestCandidate.bpm, onsetTimes.first);

    return DetectedTempo(
      bpm: bestCandidate.bpm,
      beats: beats,
      confidence: bestCandidate.strength,
      timeSignature: [4, 4], // Default to 4/4, can be extended later
    );
  }

  /// Compute spectral flux (energy change between consecutive frames)
  List<double> _computeSpectralFlux(Float32List audio) {
    final frameSize = 2048;
    final hopSize = 512;
    final flux = <double>[];

    // Apply Hann window
    final window = List<double>.generate(frameSize, (i) =>
        0.5 * (1 - math.cos(2 * math.pi * i / (frameSize - 1))));

    List<double>? prevSpectrum;

    for (int i = 0; i < audio.length - frameSize; i += hopSize) {
      // Extract frame and apply window
      final frame = Float32List(frameSize);
      for (int j = 0; j < frameSize; j++) {
        frame[j] = audio[i + j] * window[j];
      }

      // Compute magnitude spectrum (simplified FFT - using zero-crossing for speed)
      final spectrum = _computeMagnitudeSpectrum(frame);

      if (prevSpectrum != null) {
        // Calculate flux (sum of positive differences)
        double fluxValue = 0.0;
        for (int j = 0; j < spectrum.length; j++) {
          final diff = spectrum[j] - prevSpectrum[j];
          if (diff > 0) fluxValue += diff;
        }
        flux.add(fluxValue);
      }

      prevSpectrum = spectrum;
    }

    // Normalize flux
    final maxFlux = flux.isEmpty ? 1.0 : flux.reduce(math.max);
    return flux.map((f) => f / maxFlux).toList();
  }

  /// Simplified magnitude spectrum using zero-crossing approximation
  /// In production, replace with actual FFT
  List<double> _computeMagnitudeSpectrum(Float32List frame) {
    const numBins = 1024;
    final spectrum = List<double>.filled(numBins, 0.0);

    // Zero-crossing rate as proxy for spectral content
    int zeroCrossings = 0;
    for (int i = 1; i < frame.length; i++) {
      if ((frame[i - 1] >= 0 && frame[i] < 0) ||
          (frame[i - 1] < 0 && frame[i] >= 0)) {
        zeroCrossings++;
      }
    }

    // Distribute energy across spectrum based on ZCR
    final centerBin = (zeroCrossings * 50).clamp(0, numBins - 1);
    for (int i = 0; i < numBins; i++) {
      final distance = (i - centerBin).abs();
      if (distance < 100) {
        spectrum[i] = 1.0 - (distance / 100);
      }
    }

    return spectrum;
  }

  /// Detect onset peaks from flux using adaptive threshold
  List<double> _detectOnsetPeaks(List<double> flux) {
    final onsetTimes = <double>[];
    final hopSize = 512;

    // Adaptive threshold: mean + constant * std dev
    final mean = flux.fold<double>(0, (sum, v) => sum + v) / flux.length;
    final variance = flux.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean));
    final stdDev = math.sqrt(variance / flux.length);
    final threshold = mean + 0.5 * stdDev;

    // Find peaks above threshold
    for (int i = 1; i < flux.length - 1; i++) {
      if (flux[i] > flux[i - 1] &&
          flux[i] > flux[i + 1] &&
          flux[i] > threshold) {
        // Non-maximum suppression: keep only local maxima
        final time = (i * hopSize) / sampleRate;
        onsetTimes.add(time);
      }
    }

    // Remove duplicates (onsets too close together)
    final filtered = <double>[onsetTimes.first];
    for (int i = 1; i < onsetTimes.length; i++) {
      if (onsetTimes[i] - filtered.last > 0.1) { // Minimum 100ms between onsets
        filtered.add(onsetTimes[i]);
      }
    }

    return filtered;
  }

  /// Calculate inter-onset intervals
  List<double> _calculateIOIs(List<double> onsetTimes) {
    final iois = <double>[];
    for (int i = 1; i < onsetTimes.length; i++) {
      final ioi = onsetTimes[i] - onsetTimes[i - 1];
      // Filter IOIs to valid BPM range
      if (ioi >= 60.0 / maxBpm && ioi <= 60.0 / minBpm) {
        iois.add(ioi);
      }
    }
    return iois;
  }

  /// Find tempo candidates from IOI histogram
  List<_TempoCandidate> _findTempoCandidates(List<double> iois) {
    if (iois.isEmpty) return [];

    // Build IOI histogram
    const binWidth = 0.05; // 50ms bins
    final histogram = <double, int>{};

    for (final ioi in iois) {
      final bin = (ioi / binWidth).round() * binWidth;
      histogram[bin] = (histogram[bin] ?? 0) + 1;
    }

    // Find peaks in histogram
    final bins = histogram.keys.toList()..sort();
    final candidates = <_TempoCandidate>[];

    for (int i = 1; i < bins.length - 1; i++) {
      if (histogram[bins[i]]! > histogram[bins[i - 1]]! &&
          histogram[bins[i]]! > histogram[bins[i + 1]]!) {
        final ioi = bins[i];
        final bpm = 60.0 / ioi;
        if (bpm >= minBpm && bpm <= maxBpm) {
          final strength = histogram[bins[i]]! / iois.length;
          candidates.add(_TempoCandidate(bpm: bpm, strength: strength));
        }
      }
    }

    // Also consider tempo multiples/halves (common ambiguity)
    final expanded = <_TempoCandidate>[];
    for (final c in candidates) {
      expanded.add(c);
      if (c.bpm * 2 <= maxBpm) {
        expanded.add(_TempoCandidate(bpm: c.bpm * 2, strength: c.strength * 0.8));
      }
      if (c.bpm / 2 >= minBpm) {
        expanded.add(_TempoCandidate(bpm: c.bpm / 2, strength: c.strength * 0.8));
      }
    }

    return expanded;
  }

  /// Generate beat grid from BPM
  List<double> _generateBeatGrid(double bpm, double startTime) {
    final beatPeriod = 60.0 / bpm;
    final beats = <double>[startTime];

    // Generate beats for up to 5 minutes
    while (beats.last < 300.0) {
      beats.add(beats.last + beatPeriod);
    }

    return beats;
  }
}

class _TempoCandidate {
  final double bpm;
  final double strength;

  _TempoCandidate({required this.bpm, required this.strength});
}

/// Detected tempo with beat grid
class DetectedTempo {
  final double bpm;
  final List<double> beats; // Beat timestamps in seconds
  final List<int> timeSignature; // [numerator, denominator] e.g., [4, 4]
  final double confidence; // 0.0 - 1.0

  const DetectedTempo({
    required this.bpm,
    required this.beats,
    required this.timeSignature,
    required this.confidence,
  });

  DetectedTempo copyWith({
    double? bpm,
    List<double>? beats,
    List<int>? timeSignature,
    double? confidence,
  }) {
    return DetectedTempo(
      bpm: bpm ?? this.bpm,
      beats: beats ?? this.beats,
      timeSignature: timeSignature ?? this.timeSignature,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'beats': beats,
      'timeSignature': timeSignature,
      'confidence': confidence,
    };
  }

  factory DetectedTempo.fromJson(Map<String, dynamic> json) {
    return DetectedTempo(
      bpm: json['bpm'] as double,
      beats: (json['beats'] as List).cast<double>(),
      timeSignature: (json['timeSignature'] as List).cast<int>(),
      confidence: json['confidence'] as double,
    );
  }
}
