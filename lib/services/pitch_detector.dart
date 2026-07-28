/// Holds the result of a pitch validation.
class PitchDetectorResult {
  final double pitch;
  final double probability;
  final bool pitched;

  PitchDetectorResult({
    required this.pitch,
    required this.probability,
    required this.pitched,
  });
}

class Pitched {
  final int tau;
  final double probability;
  final bool pitched;

  Pitched(this.tau, this.probability, this.pitched);
}

/// Pure Dart implementation of the YIN pitch detection algorithm.
/// Bypasses external package SDK constraints to run on older Dart versions.
class PitchDetector {
  /// The default YIN threshold value (0.10 to 0.20).
  static final double defaultThreshold = 0.20;

  final double _threshold;
  final double _sampleRate;
  final List<double> _yinBuffer;

  PitchDetector(double audioSampleRate, int bufferSize)
      : _sampleRate = audioSampleRate,
        _threshold = defaultThreshold,
        _yinBuffer = List<double>.filled(bufferSize ~/ 2, 0.0);

  /// Analyzes double float PCM buffer and returns fundamental frequency estimation
  PitchDetectorResult getPitch(final List<double> audioBuffer) {
    final double pitchInHertz;

    // Step 2: Difference function
    _difference(audioBuffer);

    // Step 3: Cumulative mean normalized difference
    _cumulativeMeanNormalizedDifference();

    // Step 4: Absolute threshold
    final pitchedResult = _absoluteThreshold();

    // Step 5: Parabolic interpolation
    if (pitchedResult.tau != -1) {
      final double betterTau = _parabolicInterpolation(pitchedResult.tau);
      pitchInHertz = _sampleRate / betterTau;
    } else {
      pitchInHertz = -1;
    }

    return PitchDetectorResult(
      pitch: pitchInHertz,
      probability: pitchedResult.probability,
      pitched: pitchedResult.pitched,
    );
  }

  /// Step 2 of YIN: Calculates squared difference between signal and its shifted version
  void _difference(final List<double> audioBuffer) {
    int index, tau;
    double delta;
    for (tau = 0; tau < _yinBuffer.length; tau++) {
      _yinBuffer[tau] = 0;
    }
    for (tau = 1; tau < _yinBuffer.length; tau++) {
      for (index = 0; index < _yinBuffer.length; index++) {
        delta = audioBuffer[index] - audioBuffer[index + tau];
        _yinBuffer[tau] += delta * delta;
      }
    }
  }

  /// Step 3 of YIN: Cumulative mean normalized difference function
  void _cumulativeMeanNormalizedDifference() {
    int tau;
    _yinBuffer[0] = 1;
    double runningSum = 0;
    for (tau = 1; tau < _yinBuffer.length; tau++) {
      runningSum += _yinBuffer[tau];
      _yinBuffer[tau] *= tau / runningSum;
    }
  }

  /// Step 4 of YIN: Finds first local minimum below threshold
  Pitched _absoluteThreshold() {
    int tau;
    double probability = -1;
    bool pitched = false;

    for (tau = 2; tau < _yinBuffer.length; tau++) {
      if (_yinBuffer[tau] < _threshold) {
        while (tau + 1 < _yinBuffer.length &&
            _yinBuffer[tau + 1] < _yinBuffer[tau]) {
          tau++;
        }
        probability = 1 - _yinBuffer[tau];
        break;
      }
    }

    if (tau == _yinBuffer.length || _yinBuffer[tau] >= _threshold) {
      tau = -1;
      probability = 0;
      pitched = false;
    } else {
      pitched = true;
    }

    return Pitched(tau, probability, pitched);
  }

  /// Step 5 of YIN: Interpolation to find fine-grained pitch peak
  double _parabolicInterpolation(final int tauEstimate) {
    final double betterTau;
    final int x0;
    final int x2;

    if (tauEstimate < 1) {
      x0 = tauEstimate;
    } else {
      x0 = tauEstimate - 1;
    }
    if (tauEstimate + 1 < _yinBuffer.length) {
      x2 = tauEstimate + 1;
    } else {
      x2 = tauEstimate;
    }
    if (x0 == tauEstimate) {
      if (_yinBuffer[tauEstimate] <= _yinBuffer[x2]) {
        betterTau = tauEstimate.toDouble();
      } else {
        betterTau = x2.toDouble();
      }
    } else if (x2 == tauEstimate) {
      if (_yinBuffer[tauEstimate] <= _yinBuffer[x0]) {
        betterTau = tauEstimate.toDouble();
      } else {
        betterTau = x0.toDouble();
      }
    } else {
      double s0, s1, s2;
      s0 = _yinBuffer[x0];
      s1 = _yinBuffer[tauEstimate];
      s2 = _yinBuffer[x2];
      betterTau = tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
    }
    return betterTau;
  }
}
