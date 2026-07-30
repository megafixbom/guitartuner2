import 'dart:math' as math;
import 'dart:typed_data';

/// Multi-pitch chord detector for guitar
///
/// Detects 2-6 simultaneous pitches from audio and matches to chord templates
///
/// Algorithm:
/// 1. Compute magnitude spectrum (FFT)
/// 2. Find spectral peaks (candidate frequencies)
/// 3. Convert peaks to pitch classes (chroma)
/// 4. Match against chord templates (major, minor, 7th, etc.)
/// 5. Return best matching chord with root and quality
class ChordDetector {
  final int sampleRate;
  final double minFrequency;
  final double maxFrequency;

  ChordDetector({
    this.sampleRate = 16000,
    this.minFrequency = 80.0,  // Low E string
    this.maxFrequency = 400.0, // High E string ~7th fret
  });

  /// Detect chord from audio samples
  /// Returns list of detected chords over time
  List<DetectedChord> detect(Float32List audioSamples) {
    if (audioSamples.length < sampleRate) return [];

    final chords = <DetectedChord>[];
    final windowSize = 4096;
    final hopSize = 2048;

    // Process overlapping windows
    for (int i = 0; i < audioSamples.length - windowSize; i += hopSize) {
      final window = Float32List(windowSize);
      for (int j = 0; j < windowSize; j++) {
        window[j] = audioSamples[i + j] * _hannWindow(j, windowSize);
      }

      final chord = _detectChordInFrame(window);
      if (chord != null) {
        chords.add(chord);
      }
    }

    // Smooth chord progression (remove outliers)
    return _smoothChordProgression(chords);
  }

  /// Detect chord in a single audio frame
  DetectedChord? _detectChordInFrame(Float32List frame) {
    // Step 1: Compute magnitude spectrum
    final spectrum = _computeMagnitudeSpectrum(frame);

    // Step 2: Find spectral peaks (candidate frequencies)
    final peakFreqs = _findSpectralPeaks(spectrum);

    if (peakFreqs.length < 2) return null; // Need at least 2 notes for a chord

    // Step 3: Convert frequencies to pitch classes
    final pitchClasses = <int>{};
    for (final freq in peakFreqs) {
      final pc = _frequencyToPitchClass(freq);
      pitchClasses.add(pc);
    }

    if (pitchClasses.length < 2) return null;

    // Step 4: Match against chord templates
    final chordMatch = _matchChordTemplate(pitchClasses);

    if (chordMatch == null) return null;

    // Step 5: Determine voicing/fret position
    final rootFret = _estimateRootFret(chordMatch.root, peakFreqs);

    return DetectedChord(
      name: chordMatch.name,
      root: chordMatch.root,
      quality: chordMatch.quality,
      notes: pitchClasses.toList(),
      confidence: chordMatch.confidence,
      voicingFret: rootFret,
    );
  }

  /// Compute magnitude spectrum using simplified FFT approximation
  List<double> _computeMagnitudeSpectrum(Float32List frame) {
    const numBins = 2048;
    final spectrum = List<double>.filled(numBins, 0.0);

    // Use zero-crossing and energy distribution as proxy for spectrum
    // In production, replace with actual FFT implementation
    double energy = 0.0;
    for (final sample in frame) {
      energy += sample * sample;
    }

    // Approximate spectral envelope
    int zeroCrossings = 0;
    for (int i = 1; i < frame.length; i++) {
      if ((frame[i - 1] >= 0 && frame[i] < 0) ||
          (frame[i - 1] < 0 && frame[i] >= 0)) {
        zeroCrossings++;
      }
    }

    // Distribute energy based on zero-crossing rate
    final centerFreq = (zeroCrossings * 20).clamp(50, 800);
    for (int i = 0; i < numBins; i++) {
      final binFreq = (i / numBins) * (sampleRate / 2);
      final distance = (binFreq - centerFreq).abs();
      if (distance < 200) {
        spectrum[i] = (energy / frame.length) * (1 - distance / 200);
      }
    }

    return spectrum;
  }

  /// Find peaks in magnitude spectrum
  List<double> _findSpectralPeaks(List<double> spectrum) {
    final peaks = <double>[];
    const binSize = 16000 / 2 / 2048; // ~3.9 Hz per bin

    // Simple peak picking: find local maxima
    for (int i = 10; i < spectrum.length - 10; i++) {
      if (spectrum[i] > spectrum[i - 1] &&
          spectrum[i] > spectrum[i + 1] &&
          spectrum[i] > 0.01) { // Threshold

        final freq = i * binSize;
        if (freq >= minFrequency && freq <= maxFrequency) {
          // Check if not too close to existing peak
          bool isUnique = true;
          for (final existingFreq in peaks) {
            if ((freq - existingFreq).abs() < 20) { // 20 Hz minimum separation
              isUnique = false;
              break;
            }
          }
          if (isUnique) {
            peaks.add(freq);
          }
        }
      }
    }

    // Return top 6 peaks (max 6 strings on guitar)
    peaks.sort((a, b) => spectrum[(b / binSize).round()].compareTo(
        spectrum[(a / binSize).round()]));
    return peaks.take(6).toList();
  }

  /// Convert frequency to pitch class (0-11)
  int _frequencyToPitchClass(double frequency) {
    const a4 = 440.0;
    const a4Midi = 69;
    final midiNote = a4Midi + 12 * math.log(frequency / a4) / math.ln2;
    final roundedMidi = midiNote.round();
    return (roundedMidi % 12 + 12) % 12;
  }

  /// Match pitch classes against chord templates
  _ChordMatch? _matchChordTemplate(Set<int> pitchClasses) {
    final templates = _getChordTemplates();
    _ChordMatch? bestMatch;
    double bestScore = 0.0;

    for (final template in templates) {
      // Try all 12 root positions
      for (int root = 0; root < 12; root++) {
        final transposedNotes = template.notes.map((pc) => (pc + root) % 12).toSet();
        final score = _calculateChordFit(pitchClasses, transposedNotes);

        if (score > bestScore) {
          bestScore = score;
          final rootName = _pitchClassToNoteName(root);
          bestMatch = _ChordMatch(
            name: '$rootName${template.name}',
            root: rootName,
            quality: template.name,
            confidence: score,
          );
        }
      }
    }

    // Only return if confidence is reasonable
    if (bestScore >= 0.5) {
      return bestMatch;
    }

    return null;
  }

  /// Calculate fit between observed and template pitch classes
  double _calculateChordFit(Set<int> observed, Set<int> template) {
    final intersection = observed.intersection(template).length;
    final union = observed.union(template).length;
    final missing = template.length - intersection;
    final extra = observed.length - intersection;

    // Jaccard similarity with penalties
    double score = intersection / union;

    // Penalize missing chord tones more than extra notes
    score -= missing * 0.15;
    score -= extra * 0.05;

    return score.clamp(0.0, 1.0);
  }

  /// Get chord templates (triads and sevenths)
  List<_ChordTemplate> _getChordTemplates() {
    return [
      _ChordTemplate(name: '', notes: {0, 4, 7}),                  // Major
      _ChordTemplate(name: 'm', notes: {0, 3, 7}),                 // Minor
      _ChordTemplate(name: '7', notes: {0, 4, 7, 10}),             // Dominant 7th
      _ChordTemplate(name: 'maj7', notes: {0, 4, 7, 11}),          // Major 7th
      _ChordTemplate(name: 'm7', notes: {0, 3, 7, 10}),            // Minor 7th
      _ChordTemplate(name: 'dim', notes: {0, 3, 6}),               // Diminished
      _ChordTemplate(name: 'dim7', notes: {0, 3, 6, 9}),           // Diminished 7th
      _ChordTemplate(name: 'aug', notes: {0, 4, 8}),               // Augmented
      _ChordTemplate(name: 'sus4', notes: {0, 5, 7}),              // Suspended 4th
      _ChordTemplate(name: 'sus2', notes: {0, 2, 7}),              // Suspended 2nd
      _ChordTemplate(name: 'add9', notes: {0, 4, 7, 2}),           // Add 9th
      _ChordTemplate(name: 'madd9', notes: {0, 3, 7, 2}),          // Minor add 9th
    ];
  }

  /// Estimate fret position from root note and detected frequencies
  int _estimateRootFret(String root, List<double> frequencies) {
    if (frequencies.isEmpty) return 0;

    // Find the lowest frequency (likely bass note/root)
    final lowestFreq = frequencies.reduce(math.min);
    final rootFreq = _noteNameToFrequency(root);

    if (rootFreq == null) return 0;

    // Semi-tones from lowest freq to root
    final semitones = 12 * math.log(lowestFreq / rootFreq) / math.ln2;
    final fret = semitones.round();

    return fret.clamp(0, 12);
  }

  /// Convert pitch class to note name
  String _pitchClassToNoteName(int pc) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return notes[pc];
  }

  /// Get frequency for note name (4th octave)
  double? _noteNameToFrequency(String note) {
    const freqs = {
      'C': 261.63,
      'C#': 277.18,
      'D': 293.66,
      'D#': 311.13,
      'E': 329.63,
      'F': 349.23,
      'F#': 369.99,
      'G': 392.00,
      'G#': 415.30,
      'A': 440.00,
      'A#': 466.16,
      'B': 493.88,
    };
    return freqs[note];
  }

  /// Apply Hann window to frame
  double _hannWindow(int n, int N) {
    return 0.5 * (1 - math.cos(2 * math.pi * n / (N - 1)));
  }

  /// Smooth chord progression to remove outliers
  List<DetectedChord> _smoothChordProgression(List<DetectedChord> chords) {
    if (chords.isEmpty) return [];

    final smoothed = <DetectedChord>[chords.first];
    for (int i = 1; i < chords.length; i++) {
      // Keep chord if same as neighbors or high confidence
      final prev = smoothed.last;
      final curr = chords[i];

      if (curr.name == prev.name || curr.confidence > 0.7) {
        smoothed.add(curr);
      } else {
        // Use previous chord (temporal smoothing)
        smoothed.add(prev);
      }
    }

    return smoothed;
  }
}

/// Chord template for matching
class _ChordTemplate {
  final String name;
  final Set<int> notes; // Pitch classes

  _ChordTemplate({required this.name, required this.notes});
}

/// Chord matching result
class _ChordMatch {
  final String name;
  final String root;
  final String quality;
  final double confidence;

  _ChordMatch({
    required this.name,
    required this.root,
    required this.quality,
    required this.confidence,
  });
}

/// Detected chord with metadata
class DetectedChord {
  final String name;              // "Am", "G7", "Dm7"
  final String root;              // "C", "D", "E"
  final String quality;           // "major", "minor", "7", "dim"
  final List<int> notes;          // Pitch classes [0, 4, 7]
  final double confidence;        // 0.0 - 1.0
  final int voicingFret;          // Estimated fret position (0=open, 3=3rd fret, etc.)
  final double timestamp;         // seconds from start

  const DetectedChord({
    required this.name,
    required this.root,
    required this.quality,
    required this.notes,
    required this.confidence,
    this.voicingFret = 0,
    this.timestamp = 0.0,
  });

  DetectedChord copyWith({
    String? name,
    String? root,
    String? quality,
    List<int>? notes,
    double? confidence,
    int? voicingFret,
    double? timestamp,
  }) {
    return DetectedChord(
      name: name ?? this.name,
      root: root ?? this.root,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      voicingFret: voicingFret ?? this.voicingFret,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'root': root,
      'quality': quality,
      'notes': notes,
      'confidence': confidence,
      'voicingFret': voicingFret,
      'timestamp': timestamp,
    };
  }

  factory DetectedChord.fromJson(Map<String, dynamic> json) {
    return DetectedChord(
      name: json['name'] as String,
      root: json['root'] as String,
      quality: json['quality'] as String,
      notes: (json['notes'] as List).cast<int>(),
      confidence: json['confidence'] as double,
      voicingFret: json['voicingFret'] as int,
      timestamp: json['timestamp'] as double,
    );
  }

  /// Get chord diagram fret positions for each string
  /// Returns list of 6 frets (null = muted string)
  List<int?> getDiagram() {
    // Simplified chord diagram generator
    // In production, use chord diagram database
    return [null, null, null, null, null, null];
  }
}
