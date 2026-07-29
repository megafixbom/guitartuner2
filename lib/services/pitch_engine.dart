import 'dart:math' as math;
import 'pitch_detector.dart';

/// Represents a single guitar/instrument string's tuning details
class GuitarString {
  final int index;          // 1-indexed (1 is High E, 6 is Low E)
  final String noteName;    // "E", "A", "D", etc.
  final double targetHz;    // Target frequency in Hz
  final int octave;         // Octave (e.g., 2 for Low E)

  const GuitarString({
    required this.index,
    required this.noteName,
    required this.targetHz,
    required this.octave,
  });
}

/// The state of the tuner at any frame
class TunerStatus {
  final double? detectedFrequency;
  final double? smoothedFrequency;
  final GuitarString? targetString;
  final double centsOffset; // -50 to +50
  final bool isPerfect;     // True if within acceptable margin (e.g. -3 to +3 cents)
  final String message;     // "Too Flat", "Too Sharp", "In Tune", or "Pluck a string"
  final double volumeLevel; // RMS value for visual levels
  final double dbFS;       // Decibels relative to Full Scale (-100 dBFS to 0 dBFS)
  final double lufs;       // Loudness Units Full Scale (K-weighted loudness estimate)

  const TunerStatus({
    this.detectedFrequency,
    this.smoothedFrequency,
    this.targetString,
    this.centsOffset = 0.0,
    this.isPerfect = false,
    required this.message,
    this.volumeLevel = 0.0,
    this.dbFS = -100.0,
    this.lufs = -100.0,
  });

  const TunerStatus.searching([this.volumeLevel = 0.0, this.dbFS = -100.0, this.lufs = -100.0])
      : detectedFrequency = null,
        smoothedFrequency = null,
        targetString = null,
        centsOffset = 0.0,
        isPerfect = false,
        message = 'Pluck a string';
}

class PitchEngine {
  late final PitchDetector _detector;
  
  // Standard Reference Frequency A4 = 440.0 Hz
  static const double referenceA4 = 440.0;

  // Standard 6-String Guitar Tuning (Derived exactly from A4 = 440.0 Hz 12-TET)
  // E4 (String 1) = A4 * 2^(7/12)   = ~329.62755 Hz
  // B3 (String 2) = A4 * 2^(2/12)   = ~246.94165 Hz
  // G3 (String 3) = A4 * 2^(-2/12)  = ~195.99772 Hz
  // D3 (String 4) = A4 * 2^(-7/12)  = ~146.83238 Hz
  // A2 (String 5) = A4 * 2^(-12/12) = 110.00000 Hz
  // E2 (String 6) = A4 * 2^(-19/12) = ~82.40689 Hz
  static const List<GuitarString> standardGuitarTuning = [
    GuitarString(index: 1, noteName: 'E', targetHz: 329.62755, octave: 4), // High E (E4)
    GuitarString(index: 2, noteName: 'B', targetHz: 246.94165, octave: 3), // B (B3)
    GuitarString(index: 3, noteName: 'G', targetHz: 195.99772, octave: 3), // G (G3)
    GuitarString(index: 4, noteName: 'D', targetHz: 146.83238, octave: 3), // D (D3)
    GuitarString(index: 5, noteName: 'A', targetHz: 110.00000, octave: 2), // A (A2)
    GuitarString(index: 6, noteName: 'E', targetHz: 82.40689,  octave: 2), // Low E (E2)
  ];

  // Configurable DSP settings
  static const double noiseFloorRms = 0.005; // Balanced noise floor
  static const double minConfidence = 0.65; // Balanced pitch probability threshold for low E & A strings
  static const double emaAlpha = 0.25;     // Exponential Moving Average smoothing factor
  static const double perfectThresholdCents = 3.5; // In-tune window in cents

  // Moving Median Filter Buffer (Window Size = 5)
  final List<double> _pitchHistory = [];
  static const int medianWindowSize = 5;

  // Hold-Green In-Tune Latch Timer (Locks green "In Tune" status for 2.5 seconds)
  DateTime? _lastInTuneTime;
  static const Duration inTuneHoldDuration = Duration(milliseconds: 2500);

  // Filtering states
  double? _prevFrequency;
  GuitarString? _prevString;
  int _invalidFrameCount = 0;

  PitchEngine({int sampleRate = 16000, int bufferSize = 2048}) {
    _detector = PitchDetector(sampleRate.toDouble(), bufferSize);
  }

  /// Processes a float sample buffer, calculates pitch, and determines tuning alignment.
  TunerStatus processAudioBuffer(
    List<double> doubleSamples, {
    required bool isAutoMode,
    GuitarString? manualTargetString,
  }) {
    // 1. Calculate signal level (RMS), dBFS, and LUFS
    final double rms = _calculateRms(doubleSamples);
    final double dbFS = rms > 0.0000001 ? (20 * math.log(rms) / math.ln10).clamp(-100.0, 0.0) : -100.0;
    final double lufs = (dbFS - 0.69).clamp(-100.0, 0.0);

    if (rms < noiseFloorRms) {
      // Check if we are currently holding an "In Tune" green status latch
      if (_lastInTuneTime != null && DateTime.now().difference(_lastInTuneTime!) < inTuneHoldDuration && _prevString != null) {
        return TunerStatus(
          detectedFrequency: _prevString!.targetHz,
          smoothedFrequency: _prevString!.targetHz,
          targetString: _prevString,
          centsOffset: 0.0,
          isPerfect: true,
          message: 'In Tune',
          volumeLevel: rms,
          dbFS: dbFS,
          lufs: lufs,
        );
      }
      _resetFilters();
      return TunerStatus.searching(rms, dbFS, lufs);
    }

    // 2. Perform YIN Pitch Detection
    final result = _detector.getPitch(doubleSamples);
    
    if (!result.pitched || result.probability < minConfidence || result.pitch <= 0.0) {
      _invalidFrameCount++;
      if (_invalidFrameCount >= 3) {
        _pitchHistory.clear();
      }
      return TunerStatus.searching(rms, dbFS, lufs);
    }
    _invalidFrameCount = 0;

    double rawPitch = result.pitch;

    // --- Sub-Harmonic & Octave Jump Correction (E2 [82.4Hz] & A2 [110Hz]) ---
    // Protect D3 (146.83Hz): E2 2nd harmonic fold window starts strictly above 158Hz (164.8Hz +/- 6.8Hz) so D3 (146.83Hz) is NEVER modified even if sharp
    if (rawPitch >= 158.0 && rawPitch < 190.0) {
      // E2 octave jump (164.8 Hz -> 82.4 Hz)
      rawPitch /= 2.0;
    } else if (rawPitch >= 200.0 && rawPitch < 240.0) {
      // A2 octave jump (220.0 Hz -> 110.0 Hz)
      rawPitch /= 2.0;
    }

    // Guitar string fundamental range: Low E (70Hz) to High E (360Hz)
    if (rawPitch < 70.0 || rawPitch > 360.0) {
      return TunerStatus.searching(rms, dbFS, lufs);
    }

    // 3. Moving Median Filtering (Window Size = 5) to remove impulse glitches
    _pitchHistory.add(rawPitch);
    if (_pitchHistory.length > medianWindowSize) {
      _pitchHistory.removeAt(0);
    }
    
    final List<double> sortedPitches = List<double>.from(_pitchHistory)..sort();
    final double medianPitch = sortedPitches[sortedPitches.length ~/ 2];

    // 4. Determine target string
    GuitarString targetString;
    if (isAutoMode) {
      targetString = _findClosestString(medianPitch);
      final double centsFromTarget = (1200 * (math.log(medianPitch / targetString.targetHz) / math.ln2)).abs();
      // Allow wider 160 cents window in AUTO mode so D3 string (146.83Hz) is smoothly recognized even when out of tune
      if (centsFromTarget > 160.0) {
        return TunerStatus.searching(rms, dbFS, lufs);
      }
    } else {
      if (manualTargetString == null) {
        _resetFilters();
        return TunerStatus.searching(rms, dbFS, lufs);
      }
      targetString = manualTargetString;
      final double centsFromTarget = (1200 * (math.log(medianPitch / targetString.targetHz) / math.ln2)).abs();
      if (centsFromTarget > 200.0) {
        return TunerStatus.searching(rms, dbFS, lufs);
      }
    }

    // 5. Exponential Moving Average (EMA) Smoothing
    if (_prevString?.index != targetString.index) {
      _prevFrequency = medianPitch;
      _lastInTuneTime = null; // Clear latch when switching strings
    }
    
    final double smoothedPitch = _prevFrequency == null
        ? medianPitch
        : (emaAlpha * medianPitch) + ((1.0 - emaAlpha) * _prevFrequency!);
    
    _prevFrequency = smoothedPitch;
    _prevString = targetString;

    // 6. Cents Offset & In-Tune Latch Logic
    final double centsOffset = 1200 * (math.log(smoothedPitch / targetString.targetHz) / math.ln2);
    bool isPerfect = centsOffset.abs() <= perfectThresholdCents;
    
    // Hold green "In Tune" state for 2.5 seconds once in-tune target is achieved
    final bool isHoldingInTune = _lastInTuneTime != null && DateTime.now().difference(_lastInTuneTime!) < inTuneHoldDuration;
    if (isPerfect) {
      _lastInTuneTime = DateTime.now();
    } else if (isHoldingInTune) {
      isPerfect = true;
    }

    // Lock cents to 0.0 while in-tune latch is active so needle doesn't drift right
    final double lockedCents = isPerfect ? 0.0 : centsOffset;
    final double clampedCents = lockedCents.clamp(-50.0, 50.0);
    
    String message;
    if (isPerfect) {
      message = 'In Tune';
    } else if (clampedCents < 0) {
      message = 'Too Flat';
    } else {
      message = 'Too Sharp';
    }

    return TunerStatus(
      detectedFrequency: rawPitch,
      smoothedFrequency: smoothedPitch,
      targetString: targetString,
      centsOffset: clampedCents,
      isPerfect: isPerfect,
      message: message,
      volumeLevel: rms,
      dbFS: dbFS,
      lufs: lufs,
    );
  }

  /// Resets the EMA smoothing filters (e.g. when silence occurs)
  void _resetFilters() {
    _prevFrequency = null;
    _prevString = null;
    _pitchHistory.clear();
  }

  /// Calculates the Root Mean Square (RMS) amplitude of the audio buffer
  double _calculateRms(List<double> buffer) {
    if (buffer.isEmpty) return 0.0;
    double sumSquares = 0.0;
    for (int i = 0; i < buffer.length; i++) {
      sumSquares += buffer[i] * buffer[i];
    }
    return math.sqrt(sumSquares / buffer.length);
  }

  /// Finds the string with the closest fundamental frequency to the detected pitch
  GuitarString _findClosestString(double frequency) {
    GuitarString closest = standardGuitarTuning.first;
    double minDiff = double.infinity;

    for (var string in standardGuitarTuning) {
      // Calculate absolute logarithmic difference in cents
      final double centsDiff = (1200 * (math.log(frequency / string.targetHz) / math.ln2)).abs();
      if (centsDiff < minDiff) {
        minDiff = centsDiff;
        closest = string;
      }
    }

    return closest;
  }
}
