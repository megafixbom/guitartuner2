import 'dart:math' as math;
import 'package:pitch_detector_dart/pitch_detector_dart.dart';

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

  const TunerStatus({
    this.detectedFrequency,
    this.smoothedFrequency,
    this.targetString,
    this.centsOffset = 0.0,
    this.isPerfect = false,
    required this.message,
    this.volumeLevel = 0.0,
  });

  factory TunerStatus.searching(double volumeLevel) {
    return TunerStatus(
      message: 'Pluck a string',
      volumeLevel: volumeLevel,
    );
  }
}

class PitchEngine {
  late final PitchDetector _detector;
  
  // Standard Guitar Tuning Configuration (Strings 1 to 6)
  static const List<GuitarString> standardGuitarTuning = [
    GuitarString(index: 1, noteName: 'E', targetHz: 329.63, octave: 4), // High E
    GuitarString(index: 2, noteName: 'B', targetHz: 246.94, octave: 3), // B
    GuitarString(index: 3, noteName: 'G', targetHz: 196.00, octave: 3), // G
    GuitarString(index: 4, noteName: 'D', targetHz: 146.83, octave: 3), // D
    GuitarString(index: 5, noteName: 'A', targetHz: 110.00, octave: 2), // A
    GuitarString(index: 6, noteName: 'E', targetHz: 82.41,  octave: 2), // Low E
  ];

  // Configurable DSP settings
  static const double noiseFloorRms = 0.008; // Roughly -42dB. Ignore quieter inputs.
  static const double minConfidence = 0.85; // Pitch probability threshold
  static const double emaAlpha = 0.30;     // Exponential Moving Average smoothing factor
  static const double perfectThresholdCents = 1.5; // In-tune window in cents (GuitarTuna default)

  // Filtering states
  double? _prevFrequency;
  GuitarString? _prevString;

  PitchEngine({int sampleRate = 16000, int bufferSize = 2048}) {
    _detector = PitchDetector(sampleRate.toDouble(), bufferSize);
  }

  /// Processes a float sample buffer, calculates pitch, and determines tuning alignment.
  /// [doubleSamples] must represent audio data in the range [-1.0, 1.0].
  /// [isAutoMode] allows target selection automatically vs locking on [manualTargetString].
  TunerStatus processAudioBuffer(
    List<double> doubleSamples, {
    required bool isAutoMode,
    GuitarString? manualTargetString,
  }) {
    // 1. Calculate signal level (RMS) to enforce the noise gate
    final double rms = _calculateRms(doubleSamples);
    if (rms < noiseFloorRms) {
      _resetFilters();
      return TunerStatus.searching(rms);
    }

    // 2. Perform pitch detection
    final result = _detector.getPitch(doubleSamples);
    
    // Check if a pitched sound was detected with high confidence
    if (!result.pitched || result.probability < minConfidence || result.pitch <= 0.0) {
      return TunerStatus.searching(rms);
    }

    final double rawPitch = result.pitch;

    // Reject unrealistic guitar frequencies
    // Guitar range: E2 (82.4Hz) to E4 (329.6Hz). We allow some headroom (e.g. 50Hz to 800Hz).
    if (rawPitch < 50.0 || rawPitch > 800.0) {
      return TunerStatus.searching(rms);
    }

    // 3. Determine the target guitar string
    GuitarString targetString;
    if (isAutoMode) {
      targetString = _findClosestString(rawPitch);
    } else {
      if (manualTargetString == null) {
        _resetFilters();
        return TunerStatus.searching(rms);
      }
      targetString = manualTargetString;
    }

    // 4. Smooth the frequency using Exponential Moving Average (EMA)
    // If the active string changed, reset the smoothing filter instantly to prevent slow sliding
    if (_prevString?.index != targetString.index) {
      _prevFrequency = rawPitch;
    }
    
    final double smoothedPitch = _prevFrequency == null
        ? rawPitch
        : (emaAlpha * rawPitch) + ((1.0 - emaAlpha) * _prevFrequency!);
    
    _prevFrequency = smoothedPitch;
    _prevString = targetString;

    // 5. Calculate deviation in Cents
    // Formula: Cents = 1200 * log2(Detected_Hz / Target_Hz)
    final double centsOffset = 1200 * (math.log(smoothedPitch / targetString.targetHz) / math.ln2);
    
    // 6. Check if note is perfectly in tune (within the dead zone)
    final bool isPerfect = centsOffset.abs() <= perfectThresholdCents;
    
    // Lock cents to 0.0 inside the dead zone to prevent micro-fluctuations
    final double lockedCents = isPerfect ? 0.0 : centsOffset;
    
    // Clamp offset to +/- 50 cents for clean dial representation
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
    );
  }

  /// Resets the EMA smoothing filters (e.g. when silence occurs)
  void _resetFilters() {
    _prevFrequency = null;
    _prevString = null;
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
