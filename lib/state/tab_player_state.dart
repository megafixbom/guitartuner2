import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum NoteDuration {
  whole,
  half,
  quarter,
  eighth,
  sixteenth;

  double get beatValue => switch (this) {
        NoteDuration.whole => 4.0,
        NoteDuration.half => 2.0,
        NoteDuration.quarter => 1.0,
        NoteDuration.eighth => 0.5,
        NoteDuration.sixteenth => 0.25,
      };

  String get label => switch (this) {
        NoteDuration.whole => '1',
        NoteDuration.half => '2',
        NoteDuration.quarter => '4',
        NoteDuration.eighth => '8',
        NoteDuration.sixteenth => '16',
      };

  static NoteDuration fromBeatSpan(double beats) {
    if (beats >= 3.5) return NoteDuration.whole;
    if (beats >= 1.5) return NoteDuration.half;
    if (beats >= 0.7) return NoteDuration.quarter;
    if (beats >= 0.35) return NoteDuration.eighth;
    return NoteDuration.sixteenth;
  }
}

enum Articulation {
  none,
  slideUp,
  slideDown,
  bend,
  release,
  hammerOn,
  pullOff,
  vibrato;

  String get tabSymbol {
    switch (this) {
      case Articulation.slideUp:
        return '/';
      case Articulation.slideDown:
        return '\\';
      case Articulation.bend:
        return 'b';
      case Articulation.release:
        return 'r';
      case Articulation.hammerOn:
        return 'h';
      case Articulation.pullOff:
        return 'p';
      case Articulation.vibrato:
        return '~';
      case Articulation.none:
        return '';
    }
  }

  String get label {
    switch (this) {
      case Articulation.slideUp:
        return 'Slide Up';
      case Articulation.slideDown:
        return 'Slide Down';
      case Articulation.bend:
        return 'Bend';
      case Articulation.release:
        return 'Release';
      case Articulation.hammerOn:
        return 'Hammer-On';
      case Articulation.pullOff:
        return 'Pull-Off';
      case Articulation.vibrato:
        return 'Vibrato';
      case Articulation.none:
        return 'None';
    }
  }

  bool get isConnector {
    return this == Articulation.slideUp ||
        this == Articulation.slideDown ||
        this == Articulation.hammerOn ||
        this == Articulation.pullOff;
  }
}

enum MusicalKey {
  C,
  Cs,
  D,
  Ds,
  E,
  F,
  Fs,
  G,
  Gs,
  A,
  As,
  B;

  String get displayName {
    switch (this) {
      case MusicalKey.C:
        return 'C';
      case MusicalKey.Cs:
        return 'C#';
      case MusicalKey.D:
        return 'D';
      case MusicalKey.Ds:
        return 'D#';
      case MusicalKey.E:
        return 'E';
      case MusicalKey.F:
        return 'F';
      case MusicalKey.Fs:
        return 'F#';
      case MusicalKey.G:
        return 'G';
      case MusicalKey.Gs:
        return 'G#';
      case MusicalKey.A:
        return 'A';
      case MusicalKey.As:
        return 'A#';
      case MusicalKey.B:
        return 'B';
    }
  }

  static MusicalKey fromSemitones(int semitones) {
    return MusicalKey.values[(semitones % 12 + 12) % 12];
  }

  int get semitones => index;
}

enum KeyMode { major, minor }

class DetectedKey {
  final MusicalKey tonic;
  final KeyMode mode;
  final double confidence;
  final List<int> pitchClassHistogram;

  const DetectedKey({
    required this.tonic,
    required this.mode,
    required this.confidence,
    required this.pitchClassHistogram,
  });

  String get displayName =>
      '${tonic.displayName}${mode == KeyMode.minor ? "m" : ""}';

  List<int> get accidentals {
    final keySignatureMap = {
      MusicalKey.C: 0,
      MusicalKey.Cs: -7,
      MusicalKey.D: -5,
      MusicalKey.Ds: -4,
      MusicalKey.E: -3,
      MusicalKey.F: 1,
      MusicalKey.Fs: 0,
      MusicalKey.G: 6,
      MusicalKey.Gs: -6,
      MusicalKey.A: -4,
      MusicalKey.As: -3,
      MusicalKey.B: -2,
    };
    final offset = mode == KeyMode.minor ? 3 : 0;
    final relativeTonic = (tonic.semitones - offset + 12) % 12;
    final relativeKey = MusicalKey.fromSemitones(relativeTonic);
    final fifths = keySignatureMap[relativeKey] ?? 0;

    if (fifths == 0) return [];
    if (fifths > 0) {
      return List.generate(fifths, (i) => [11, 6, 1, 8, 3, 10, 5][i]);
    } else {
      return List.generate(-fifths, (i) => [3, 10, 5, 0, 7, 2, 9][i]);
    }
  }

  DetectedKey copyWith({
    MusicalKey? tonic,
    KeyMode? mode,
    double? confidence,
    List<int>? pitchClassHistogram,
  }) {
    return DetectedKey(
      tonic: tonic ?? this.tonic,
      mode: mode ?? this.mode,
      confidence: confidence ?? this.confidence,
      pitchClassHistogram: pitchClassHistogram ?? this.pitchClassHistogram,
    );
  }
}

/// Represents a single note on a guitar tab staff (fret position & string index)
class TabNote {
  final int stringIndex; // 1 to 6 (1 is High E, 6 is Low E)
  final int fret;        // 0 (open) to 24, or -1 for ghost/muted notes
  final double position; // Beat position in track timeline
  final NoteDuration duration; // Note duration type
  final bool isGhost;    // True for muted/ghost notes (renders as X)
  final Articulation articulation; // Articulation technique to apply

  const TabNote({
    required this.stringIndex,
    required this.fret,
    required this.position,
    this.duration = NoteDuration.quarter,
    this.isGhost = false,
    this.articulation = Articulation.none,
  });

  Map<String, dynamic> toJson() => {
        'stringIndex': stringIndex,
        'fret': fret,
        'position': position,
        'duration': duration.label,
        if (isGhost) 'isGhost': true,
        if (articulation != Articulation.none) 'articulation': articulation.name,
      };

  factory TabNote.fromJson(Map<String, dynamic> json) => TabNote(
        stringIndex: json['stringIndex'] as int,
        fret: json['fret'] as int,
        position: (json['position'] as num).toDouble(),
        duration: _parseDuration((json['duration'] as String?) ?? '4'),
        isGhost: (json['isGhost'] as bool?) ?? false,
        articulation: _parseArticulation((json['articulation'] as String?)),
      );

  static Articulation _parseArticulation(String? name) {
    if (name == null) return Articulation.none;
    return Articulation.values.firstWhere(
      (a) => a.name == name,
      orElse: () => Articulation.none,
    );
  }

  static NoteDuration _parseDuration(String label) {
    return NoteDuration.values.firstWhere(
      (d) => d.label == label,
      orElse: () => NoteDuration.quarter,
    );
  }
}

/// Represents a single measure in a guitar tab track
class TabMeasure {
  final int number;
  final List<TabNote> notes;

  const TabMeasure({
    required this.number,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'notes': notes.map((n) => n.toJson()).toList(),
      };

  factory TabMeasure.fromJson(Map<String, dynamic> json) => TabMeasure(
        number: json['number'] as int,
        notes: (json['notes'] as List)
            .map((n) => TabNote.fromJson(n as Map<String, dynamic>))
            .toList(),
      );
}

/// Overall Tab Player state model
class TabPlayerState {
  final bool isPlaying;
  final bool isRecording;
  final double recordingDurationSeconds;
  final List<double> waveformLevels;
  final double currentBpm;
  final double playheadPosition;
  final int totalMeasures;
  final List<TabMeasure> measures;
  final bool isLooping;
  final bool isLiveMicMode;
  final NoteDuration selectedDuration;
  final Articulation selectedArticulation;
  final List<double> tapTempoHistory;
  final DetectedKey? detectedKey;

  const TabPlayerState({
    required this.isPlaying,
    this.isRecording = false,
    this.recordingDurationSeconds = 0.0,
    this.waveformLevels = const [],
    required this.currentBpm,
    required this.playheadPosition,
    required this.totalMeasures,
    required this.measures,
    required this.isLooping,
    this.isLiveMicMode = false,
    this.selectedDuration = NoteDuration.quarter,
    this.selectedArticulation = Articulation.none,
    this.tapTempoHistory = const [],
    this.detectedKey,
  });

  TabPlayerState copyWith({
    bool? isPlaying,
    bool? isRecording,
    double? recordingDurationSeconds,
    List<double>? waveformLevels,
    double? currentBpm,
    double? playheadPosition,
    int? totalMeasures,
    List<TabMeasure>? measures,
    bool? isLooping,
    bool? isLiveMicMode,
    NoteDuration? selectedDuration,
    Articulation? selectedArticulation,
    List<double>? tapTempoHistory,
    DetectedKey? detectedKey,
  }) {
    return TabPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isRecording: isRecording ?? this.isRecording,
      recordingDurationSeconds: recordingDurationSeconds ?? this.recordingDurationSeconds,
      waveformLevels: waveformLevels ?? this.waveformLevels,
      currentBpm: currentBpm ?? this.currentBpm,
      playheadPosition: playheadPosition ?? this.playheadPosition,
      totalMeasures: totalMeasures ?? this.totalMeasures,
      measures: measures ?? this.measures,
      isLooping: isLooping ?? this.isLooping,
      isLiveMicMode: isLiveMicMode ?? this.isLiveMicMode,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      selectedArticulation: selectedArticulation ?? this.selectedArticulation,
      tapTempoHistory: tapTempoHistory ?? this.tapTempoHistory,
    );
  }
}

class TabPlayerNotifier extends StateNotifier<TabPlayerState> {
  TabPlayerNotifier()
      : super(TabPlayerState(
          isPlaying: false,
          currentBpm: 120.0,
          playheadPosition: 0.0,
          totalMeasures: 4,
          measures: _generateSampleTab(),
          isLooping: true,
          isLiveMicMode: false,
        ));

  final AudioPlayer _synthAudioPlayer = AudioPlayer();
  final Set<double> _triggeredBeatPositions = {};
  final List<double> _recordedFrequencyBuffer = [];
  final List<double> _ghostNoteTimestamps = []; // seconds from recording start
  double _lastQuantizedPos = -1.0;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;

  void toggleLiveMicMode() {
    final bool newLiveMic = !state.isLiveMicMode;
    if (newLiveMic) {
      _synthAudioPlayer.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _recordingStartTime = null;
    }
    state = state.copyWith(
      isLiveMicMode: newLiveMic,
      isRecording: newLiveMic ? false : state.isRecording,
      isPlaying: newLiveMic ? false : state.isPlaying,
    );
  }

  /// 1. THE INPUT STREAM & CAPTURE FLOW
  void recordRawFrequencySample(double frequency) {
    if (frequency < 70.0 || frequency > 400.0) return;

    if (state.isRecording) {
      _recordedFrequencyBuffer.add(frequency);
    } else if (state.isLiveMicMode) {
      _processLivePitchSample(frequency);
    }
  }

  void _processLivePitchSample(double frequency) {
    // Quantize playhead timing to nearest 16th note subdivision (0.25 beat)
    final double rawPos = state.playheadPosition;
    final double quantizedPos = (rawPos * 4.0).round() / 4.0;

    // Debounce duplicate updates at identical 16th note subdivision slot
    if ((quantizedPos - _lastQuantizedPos).abs() < 0.01) return;

    final TabNote? mappedNote = _solveGuitarCoordinate(frequency, quantizedPos);
    if (mappedNote != null) {
      _lastQuantizedPos = quantizedPos;
      _appendOrUpdateNote(mappedNote);
    }
  }

  /// 2. THE TABLATURE MAPPING & RENDERING FLOW
  /// Maps frequency to optimal 6-string guitar coordinate (String 1..6, Fret 0..24)
  TabNote? _solveGuitarCoordinate(double frequency, double position) {
    // Standard Guitar String Base Frequencies (String 1 High E: 329.63Hz, String 6 Low E: 82.41Hz)
    final stringBaseHz = [329.63, 246.94, 196.00, 146.83, 110.00, 82.41];
    
    int bestStringIndex = 6;
    int bestFret = 0;
    double minCentsDiff = double.infinity;
    double minFretPenalty = double.infinity;

    for (int s = 0; s < 6; s++) {
      final double baseHz = stringBaseHz[s];
      final double fretCalc = 12.0 * (math.log(frequency / baseHz) / math.ln2);
      final int fretRounded = fretCalc.round();

      if (fretRounded >= 0 && fretRounded <= 24) {
        final double exactFretHz = baseHz * math.pow(2.0, fretRounded / 12.0);
        final double centsDiff = (1200.0 * (math.log(frequency / exactFretHz) / math.ln2)).abs();

        // Penalty score favoring lower/comfortable fret positions (frets 0..12)
        final double fretPenalty = centsDiff + (fretRounded * 0.5);

        if (fretPenalty < minFretPenalty) {
          minFretPenalty = fretPenalty;
          minCentsDiff = centsDiff;
          bestStringIndex = s + 1; // 1 to 6
          bestFret = fretRounded;
        }
      }
    }

    if (minCentsDiff < 45.0) {
      return TabNote(stringIndex: bestStringIndex, fret: bestFret, position: position);
    }
    return null;
  }

  void _appendOrUpdateNote(TabNote newNote) {
    final updatedMeasures = List<TabMeasure>.from(state.measures);
    if (updatedMeasures.isEmpty) return;

    final int targetMeasureIndex = (newNote.position / 4.0).floor().clamp(0, updatedMeasures.length - 1);
    final currentNotes = List<TabNote>.from(updatedMeasures[targetMeasureIndex].notes);

    // Replace note at identical quantized 16th note position or append
    currentNotes.removeWhere((n) => (n.position - newNote.position).abs() < 0.125);
    currentNotes.add(newNote);

    updatedMeasures[targetMeasureIndex] = TabMeasure(
      number: updatedMeasures[targetMeasureIndex].number,
      notes: currentNotes,
    );

    state = state.copyWith(measures: updatedMeasures);
  }

  void recordTranscribedPitch(double frequency) {
    recordRawFrequencySample(frequency);
  }

  /// Record a ghost/muted note (detected transient without stable pitch)
  void recordGhostNote() {
    if (_recordingStartTime != null && state.isRecording) {
      final elapsed = DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0;
      _ghostNoteTimestamps.add(elapsed);
    } else if (state.isLiveMicMode) {
      // In live mic mode, use quantized playhead position
      final double rawPos = state.playheadPosition;
      final double quantizedPos = (rawPos * 4.0).round() / 4.0;
      if ((quantizedPos - _lastQuantizedPos).abs() < 0.125) return;
      _lastQuantizedPos = quantizedPos;
      final ghostNote = TabNote(
        stringIndex: 4, // Default to D string for ghost notes
        fret: 0,
        position: quantizedPos,
        duration: state.selectedDuration,
        isGhost: true,
      );
      _appendOrUpdateNote(ghostNote);
    }
  }

  void toggleRecording() {
    final bool newRecordingState = !state.isRecording;
    if (newRecordingState) {
      _recordedFrequencyBuffer.clear();
      _ghostNoteTimestamps.clear();
      _lastQuantizedPos = -1.0;
      _synthAudioPlayer.stop();
      _recordingStartTime = DateTime.now();
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_recordingStartTime != null && state.isRecording) {
          final elapsed = DateTime.now().difference(_recordingStartTime!).inMilliseconds / 1000.0;
          state = state.copyWith(recordingDurationSeconds: elapsed);
        }
      });
      state = state.copyWith(
        isRecording: true,
        isPlaying: true,
        isLiveMicMode: false,
        recordingDurationSeconds: 0.0,
        waveformLevels: [],
      );
    } else {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _processBatchRecordedFrequencies();
      _synthAudioPlayer.stop();
      state = state.copyWith(
        isRecording: false,
        isPlaying: false,
      );
    }
  }

  void _processBatchRecordedFrequencies() {
    if (_recordedFrequencyBuffer.isEmpty && _ghostNoteTimestamps.isEmpty) return;

    final List<TabNote> batchNotes = [];
    final double totalBeats = (state.recordingDurationSeconds * state.currentBpm) / 60.0;
    final double beatStep = totalBeats / math.max(1, _recordedFrequencyBuffer.length);

    // Process frequency-derived notes
    for (int i = 0; i < _recordedFrequencyBuffer.length; i++) {
      final double frequency = _recordedFrequencyBuffer[i];
      final double rawPos = i * beatStep;
      final double quantizedPos = ((rawPos * 4.0).round() / 4.0).clamp(0.0, totalBeats);

      final double nextPos = i < _recordedFrequencyBuffer.length - 1
          ? ((i + 1) * beatStep * 4.0).round() / 4.0
          : totalBeats;
      final double beatSpan = (nextPos - quantizedPos).clamp(0.25, 4.0);

      final note = _solveGuitarCoordinate(frequency, quantizedPos);
      if (note != null) {
        batchNotes.add(TabNote(
          stringIndex: note.stringIndex,
          fret: note.fret,
          position: quantizedPos,
          duration: NoteDuration.fromBeatSpan(beatSpan),
        ));
      }
    }

    // Process ghost note timestamps (seconds) -> convert to beat positions
    for (final timestamp in _ghostNoteTimestamps) {
      final double beatPos = (timestamp * state.currentBpm) / 60.0;
      final double quantizedPos = ((beatPos * 4.0).round() / 4.0).clamp(0.0, totalBeats);
      batchNotes.add(TabNote(
        stringIndex: 4, // D string default for ghost notes
        fret: 0,
        position: quantizedPos,
        duration: NoteDuration.eighth,
        isGhost: true,
      ));
    }

    // Sort all notes by position
    batchNotes.sort((a, b) => a.position.compareTo(b.position));

    // Auto-detect hammer-ons and pull-offs between same-string consecutive notes
    for (int i = 0; i < batchNotes.length - 1; i++) {
      if (batchNotes[i].isGhost || batchNotes[i + 1].isGhost) continue;
      if (batchNotes[i].stringIndex != batchNotes[i + 1].stringIndex) continue;

      final double gap = batchNotes[i + 1].position - batchNotes[i].position;
      if (gap > 0.01 && gap < 0.6) {
        if (batchNotes[i + 1].fret > batchNotes[i].fret) {
          batchNotes[i] = TabNote(
            stringIndex: batchNotes[i].stringIndex,
            fret: batchNotes[i].fret,
            position: batchNotes[i].position,
            duration: batchNotes[i].duration,
            articulation: Articulation.hammerOn,
          );
        } else if (batchNotes[i + 1].fret < batchNotes[i].fret) {
          batchNotes[i] = TabNote(
            stringIndex: batchNotes[i].stringIndex,
            fret: batchNotes[i].fret,
            position: batchNotes[i].position,
            duration: batchNotes[i].duration,
            articulation: Articulation.pullOff,
          );
        }
      }
    }

    if (batchNotes.isNotEmpty) {
      final detectedKey = _detectMusicalKey(batchNotes);
      final measureCount = (totalBeats / 4.0).ceil().clamp(1, 100).toInt();
      final updatedMeasures = List<TabMeasure>.generate(measureCount, (i) {
        final startBeat = i * 4.0;
        final endBeat = startBeat + 4.0;
        return TabMeasure(
          number: i + 1,
          notes: batchNotes.where((n) => n.position >= startBeat && n.position < endBeat).toList(),
        );
      });
      state = state.copyWith(
        measures: updatedMeasures,
        totalMeasures: measureCount,
        detectedKey: detectedKey,
      );
      saveSessionToDevice();
    }
  }

  DetectedKey? _detectMusicalKey(List<TabNote> notes) {
    if (notes.isEmpty) return null;

    final pitchClassCounts = List<int>.filled(12, 0);
    for (final note in notes) {
      if (note.isGhost) continue;
      final frequency = _getFrequencyFromTabNote(note);
      if (frequency == null) continue;
      final pitchClass = _frequencyToPitchClass(frequency);
      pitchClassCounts[pitchClass]++;
    }

    final totalNotes = pitchClassCounts.fold<int>(0, (sum, c) => sum + c);
    if (totalNotes < 3) return null;

    final majorProfile = [0.77, 0.08, 0.14, 0.5, 0.04, 0.09, 0.12, 0.09, 0.02, 0.31, 0.05, 0.46];
    final minorProfile = [0.75, 0.06, 0.11, 0.39, 0.02, 0.16, 0.15, 0.19, 0.08, 0.12, 0.02, 0.13];

    double bestScore = -1.0;
    MusicalKey? bestTonic;
    KeyMode? bestMode;

    for (int i = 0; i < 12; i++) {
      final majorScore = _calculateKeyFit(pitchClassCounts, majorProfile, i);
      final minorScore = _calculateKeyFit(pitchClassCounts, minorProfile, i);

      if (majorScore > bestScore) {
        bestScore = majorScore;
        bestTonic = MusicalKey.fromSemitones(i);
        bestMode = KeyMode.major;
      }
      if (minorScore > bestScore) {
        bestScore = minorScore;
        bestTonic = MusicalKey.fromSemitones(i);
        bestMode = KeyMode.minor;
      }
    }

    if (bestTonic == null || bestScore < 0.3) return null;

    return DetectedKey(
      tonic: bestTonic!,
      mode: bestMode!,
      confidence: bestScore.clamp(0.0, 1.0),
      pitchClassHistogram: pitchClassCounts,
    );
  }

  double _calculateKeyFit(List<int> counts, List<double> profile, int transpose) {
    double sum = 0.0;
    final totalCounts = counts.fold<int>(0, (sum, c) => sum + c);
    if (totalCounts == 0) return 0.0;

    for (int i = 0; i < 12; i++) {
      final pitchClass = (i + transpose) % 12;
      final observed = counts[i] / totalCounts;
      final expected = profile[pitchClass];
      sum += observed * expected;
    }
    return sum;
  }

  double? _getFrequencyFromTabNote(TabNote note) {
    final openStringFreqs = {6: 82.41, 5: 110.0, 4: 146.83, 3: 196.0, 2: 246.94, 1: 329.63};
    final openFreq = openStringFreqs[note.stringIndex];
    if (openFreq == null) return null;
    return openFreq * math.pow(2, note.fret / 12);
  }

  int _frequencyToPitchClass(double frequency) {
    const a4 = 440.0;
    final semitonesFromA4 = 12 * math.log(frequency / a4) / math.ln2;
    final midiNote = (69 + semitonesFromA4).round();
    return (midiNote % 12 + 12) % 12;
  }

  /// 3. PERSISTENCE & PLAYBACK SYNCHRONIZATION FLOW
  Future<void> saveSessionToDevice() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/recorded_tab_session.json');
      final sessionData = {
        'version': '1.0',
        'bpm': state.currentBpm,
        'totalMeasures': state.totalMeasures,
        'timestamp': DateTime.now().toIso8601String(),
        'measures': state.measures.map((m) => m.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(sessionData));
    } catch (_) {}
  }

  Future<bool> loadSessionFromDevice() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/recorded_tab_session.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final loadedMeasures = (json['measures'] as List)
            .map((m) => TabMeasure.fromJson(m as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          currentBpm: (json['bpm'] as num).toDouble(),
          totalMeasures: json['totalMeasures'] as int,
          measures: loadedMeasures,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  void pushWaveformLevel(double rmsLevel) {
    if (state.isRecording || state.isLiveMicMode) {
      final updatedWaveform = List<double>.from(state.waveformLevels)..add(rmsLevel);
      if (updatedWaveform.length > 30) {
        updatedWaveform.removeAt(0);
      }
      state = state.copyWith(waveformLevels: updatedWaveform);
    }
  }

  void togglePlayPause() {
    final bool newIsPlaying = !state.isPlaying;
    if (!newIsPlaying) {
      _triggeredBeatPositions.clear();
      _synthAudioPlayer.stop();
    } else if (state.isLiveMicMode) {
      // Audio playback and Live Mic can conflict, ensure live mic is disabled
      state = state.copyWith(isLiveMicMode: false);
    }
    
    state = state.copyWith(
      isPlaying: newIsPlaying,
      isLiveMicMode: newIsPlaying ? false : state.isLiveMicMode,
    );
  }

  void setBpm(double bpm) {
    state = state.copyWith(currentBpm: bpm);
  }

  void seekTo(double position) {
    if (position < state.playheadPosition) {
      _triggeredBeatPositions.clear();
    }

    final double totalBeats = state.totalMeasures * 4.0;

    // Clamp the position to prevent out-of-bounds indexing
    final clampedPosition = position.clamp(0.0, totalBeats);

    // Debounce widget rebuilds by setting threshold to 0.05 beats
    if ((clampedPosition - state.playheadPosition).abs() >= 0.05) {
      state = state.copyWith(playheadPosition: clampedPosition);
    }

    // Synchronous playback trigger check as playhead crosses beat markers
    if (state.isPlaying) {
      for (var measure in state.measures) {
        for (var note in measure.notes) {
          if ((position - note.position).abs() < 0.20 && !_triggeredBeatPositions.contains(note.position)) {
            _triggeredBeatPositions.add(note.position);
            if (!note.isGhost) {
              _playNoteSynthAudio(note);
            }
          }
        }
      }
    }
  }

  void _playNoteSynthAudio(TabNote note) async {
    final stringNames = ['E4', 'B3', 'G3', 'D3', 'A2', 'E2'];
    if (note.stringIndex >= 1 && note.stringIndex <= 6) {
      final String soundFile = stringNames[note.stringIndex - 1];
      try {
        await _synthAudioPlayer.play(AssetSource('sounds/$soundFile.wav'));
      } catch (_) {}
    }
  }

  void toggleLoop() {
    state = state.copyWith(isLooping: !state.isLooping);
  }

  /// Reset tab to empty state with a single empty measure
  void clearTab() {
    _triggeredBeatPositions.clear();
    _recordedFrequencyBuffer.clear();
    _ghostNoteTimestamps.clear();
    _synthAudioPlayer.stop();
    _recordingTimer?.cancel();
    _recordingTimer = null;
    state = state.copyWith(
      isPlaying: false,
      isRecording: false,
      isLiveMicMode: false,
      playheadPosition: 0.0,
      totalMeasures: 4,
      measures: List.generate(4, (i) => TabMeasure(number: i + 1, notes: const [])),
    );
  }

  /// Add a note manually at the given beat position (used for tap-to-add on score)
  void addNoteManually(int stringIndex, int fret, double position) {
    if (stringIndex < 1 || stringIndex > 6 || fret < 0 || fret > 24) return;

    final note = TabNote(
      stringIndex: stringIndex,
      fret: fret,
      position: position,
      duration: state.selectedDuration,
      articulation: state.selectedArticulation,
    );
    _appendOrUpdateNote(note);
  }

  /// Cycle through note duration options
  void cycleSelectedDuration() {
    final durations = NoteDuration.values;
    final currentIndex = durations.indexOf(state.selectedDuration);
    final nextIndex = (currentIndex + 1) % durations.length;
    state = state.copyWith(selectedDuration: durations[nextIndex]);
  }

  void setSelectedDuration(NoteDuration duration) {
    state = state.copyWith(selectedDuration: duration);
  }

  /// Cycle through articulation options
  void cycleSelectedArticulation() {
    final articulations = Articulation.values;
    final currentIndex = articulations.indexOf(state.selectedArticulation);
    final nextIndex = (currentIndex + 1) % articulations.length;
    state = state.copyWith(selectedArticulation: articulations[nextIndex]);
  }

  void setSelectedArticulation(Articulation articulation) {
    state = state.copyWith(selectedArticulation: articulation);
  }

  /// Register a tap for BPM calculation
  void registerTapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final updatedHistory = List<double>.from(state.tapTempoHistory)..add(now);

    // Keep only last 8 taps
    while (updatedHistory.length > 8) {
      updatedHistory.removeAt(0);
    }

    // Calculate BPM from tap intervals if we have at least 2 taps
    double? newBpm;
    if (updatedHistory.length >= 2) {
      double totalInterval = 0;
      for (int i = 1; i < updatedHistory.length; i++) {
        totalInterval += updatedHistory[i] - updatedHistory[i - 1];
      }
      final avgInterval = totalInterval / (updatedHistory.length - 1);
      if (avgInterval > 0.1) {
        newBpm = (60.0 / avgInterval).clamp(40.0, 280.0).roundToDouble();
      }
    }

    state = state.copyWith(
      tapTempoHistory: updatedHistory,
      currentBpm: newBpm ?? state.currentBpm,
    );
  }

  /// Delete a note at the given position on a specific string
  void deleteNoteAt(int stringIndex, double position) {
    final updatedMeasures = List<TabMeasure>.from(state.measures);
    final tolerance = 0.15;
    final int measureIndex = (position / 4.0).floor().clamp(0, updatedMeasures.length - 1);
    final currentNotes = List<TabNote>.from(updatedMeasures[measureIndex].notes);

    currentNotes.removeWhere((n) =>
        n.stringIndex == stringIndex &&
        (n.position - position).abs() < tolerance);

    updatedMeasures[measureIndex] = TabMeasure(
      number: updatedMeasures[measureIndex].number,
      notes: currentNotes,
    );
    state = state.copyWith(measures: updatedMeasures);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _synthAudioPlayer.dispose();
    super.dispose();
  }

  static List<TabMeasure> _generateSampleTab() {
    return [
      const TabMeasure(
        number: 1,
        notes: [
          TabNote(stringIndex: 6, fret: 0, position: 0.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 5, fret: 2, position: 1.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 5, fret: 3, position: 1.5, duration: NoteDuration.eighth, articulation: Articulation.hammerOn),
          TabNote(stringIndex: 5, fret: 2, position: 2.0, duration: NoteDuration.eighth, articulation: Articulation.pullOff),
          TabNote(stringIndex: 4, fret: 2, position: 2.5, duration: NoteDuration.quarter, articulation: Articulation.slideUp),
          TabNote(stringIndex: 4, fret: 5, position: 3.5, duration: NoteDuration.eighth, articulation: Articulation.vibrato),
        ],
      ),
      const TabMeasure(
        number: 2,
        notes: [
          TabNote(stringIndex: 1, fret: 3, position: 4.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 2, fret: 0, position: 5.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 3, fret: 0, position: 6.0, duration: NoteDuration.half),
          TabNote(stringIndex: 4, fret: 2, position: 7.5, duration: NoteDuration.eighth),
        ],
      ),
      const TabMeasure(
        number: 3,
        notes: [
          TabNote(stringIndex: 5, fret: 3, position: 8.0, duration: NoteDuration.quarter, articulation: Articulation.slideDown),
          TabNote(stringIndex: 5, fret: 0, position: 9.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 4, fret: 2, position: 10.0, duration: NoteDuration.quarter, articulation: Articulation.hammerOn),
          TabNote(stringIndex: 4, fret: 4, position: 10.5, duration: NoteDuration.eighth),
          TabNote(stringIndex: 3, fret: 0, position: 11.0, duration: NoteDuration.quarter),
        ],
      ),
      const TabMeasure(
        number: 4,
        notes: [
          TabNote(stringIndex: 6, fret: 3, position: 12.0, duration: NoteDuration.half),
          TabNote(stringIndex: 5, fret: 2, position: 14.0, duration: NoteDuration.quarter, articulation: Articulation.bend),
          TabNote(stringIndex: 1, fret: 3, position: 15.0, duration: NoteDuration.quarter),
        ],
      ),
    ];
  }
}

final tabPlayerProvider =
    StateNotifierProvider<TabPlayerNotifier, TabPlayerState>((ref) {
  return TabPlayerNotifier();
});
