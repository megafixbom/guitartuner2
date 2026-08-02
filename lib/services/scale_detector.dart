/// Scale detection service for guitar lead sections.
///
/// Analyzes a monophonic passage's pitch class histogram to find the best
/// matching musical scale (major, minor, pentatonic, blues, modes).
///
/// TODO (Future - v1.9.0): Pitch shifting / key transposition
/// TODO (Future - v2.0.0): Lyric transcription
library;

/// Musical scale types with their interval patterns (in semitones from tonic).
enum ScaleType {
  major([0, 2, 4, 5, 7, 9, 11]),
  naturalMinor([0, 2, 3, 5, 7, 8, 10]),
  harmonicMinor([0, 2, 3, 5, 7, 8, 11]),
  melodicMinor([0, 2, 3, 5, 7, 9, 11]),
  majorPentatonic([0, 2, 4, 7, 9]),
  minorPentatonic([0, 3, 5, 7, 10]),
  blues([0, 3, 5, 6, 7, 10]),
  dorian([0, 2, 3, 5, 7, 9, 10]),
  phrygian([0, 1, 3, 5, 7, 8, 10]),
  lydian([0, 2, 4, 6, 7, 9, 11]),
  mixolydian([0, 2, 4, 5, 7, 9, 10]),
  locrian([0, 1, 3, 5, 6, 8, 10]);

  const ScaleType(this.intervals);

  /// Interval pattern relative to the tonic, in semitones.
  final List<int> intervals;

  /// Display label used in the toolbar chip, e.g. "Minor Pentatonic".
  String get label => switch (this) {
        ScaleType.major => 'Major',
        ScaleType.naturalMinor => 'Minor',
        ScaleType.harmonicMinor => 'Harmonic Minor',
        ScaleType.melodicMinor => 'Melodic Minor',
        ScaleType.majorPentatonic => 'Major Pentatonic',
        ScaleType.minorPentatonic => 'Minor Pentatonic',
        ScaleType.blues => 'Blues',
        ScaleType.dorian => 'Dorian',
        ScaleType.phrygian => 'Phrygian',
        ScaleType.lydian => 'Lydian',
        ScaleType.mixolydian => 'Mixolydian',
        ScaleType.locrian => 'Locrian',
      };

  /// Pitch classes (relative to a tonic of 0) contained in this scale.
  Set<int> get notes => intervals.toSet();
}

/// A detected musical scale with its tonic and confidence.
class DetectedScale {
  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Tonic pitch class, 0 = C, 1 = C#, ... 11 = B.
  final int tonic;
  final ScaleType type;
  final double confidence;
  final List<int> pitchClassHistogram;

  const DetectedScale({
    required this.tonic,
    required this.type,
    required this.confidence,
    required this.pitchClassHistogram,
  });

  /// Display name, e.g. "A Minor Pentatonic".
  String get displayName => '${_noteNames[tonic]} ${type.label}';

  /// Absolute pitch classes (0-11) that belong to this scale.
  Set<int> get absoluteNotes =>
      type.notes.map((n) => (tonic + n) % 12).toSet();

  /// Whether the given pitch class (0-11) is a scale tone.
  bool isInScale(int pitchClass) => absoluteNotes.contains(pitchClass);
}

/// Detects the best-fitting scale for a monophonic pitch class histogram.
class ScaleDetector {
  /// Detect the best scale, or `null` when the passage is too small or the
  /// match is too weak.
  ///
  /// [pitchClassCounts] is a 12-element histogram of note pitch classes.
  DetectedScale? detect(List<int> pitchClassCounts) {
    if (pitchClassCounts.length < 12) return null;

    final totalNotes = pitchClassCounts.fold<int>(0, (sum, c) => sum + c);
    if (totalNotes < 4) return null;

    ScaleType? bestType;
    int bestTonic = 0;
    double bestScore = -1.0;
    double bestCoverage = 0.0;

    for (final type in ScaleType.values) {
      final scaleNotes = type.notes;
      for (int tonic = 0; tonic < 12; tonic++) {
        final absoluteNotes =
            scaleNotes.map((n) => (tonic + n) % 12).toSet();

        // Coverage: fraction of played notes that fall inside the scale.
        var inScaleCount = 0;
        for (int pc = 0; pc < 12; pc++) {
          if (absoluteNotes.contains(pc)) {
            inScaleCount += pitchClassCounts[pc];
          }
        }
        final coverage = inScaleCount / totalNotes;

        // Tonic emphasis: melodies tend to land on the tonic.
        final tonicEmphasis = pitchClassCounts[tonic] / totalNotes;

        // Size match: prefer scales whose size closely matches the number of
        // distinct pitch classes actually used (e.g. pentatonic vs full major).
        final distinctUsed =
            pitchClassCounts.where((c) => c > 0).length;
        final sizePenalty =
            (scaleNotes.length - distinctUsed).abs().clamp(0, 7) / 7.0;

        final score = coverage * 0.7 +
            tonicEmphasis * 0.2 +
            (1.0 - sizePenalty) * 0.1;

        if (score > bestScore) {
          bestScore = score;
          bestCoverage = coverage;
          bestType = type;
          bestTonic = tonic;
        }
      }
    }

    if (bestType == null || bestCoverage < 0.6) return null;

    return DetectedScale(
      tonic: bestTonic,
      type: bestType,
      confidence: bestScore.clamp(0.0, 1.0),
      pitchClassHistogram: List.of(pitchClassCounts),
    );
  }
}
