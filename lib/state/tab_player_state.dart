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

/// Represents a single note on a guitar tab staff (fret position & string index)
class TabNote {
  final int stringIndex; // 1 to 6 (1 is High E, 6 is Low E)
  final int fret;        // 0 (open) to 24
  final double position; // Beat position in track timeline
  final NoteDuration duration; // Note duration type

  const TabNote({
    required this.stringIndex,
    required this.fret,
    required this.position,
    this.duration = NoteDuration.quarter,
  });

  Map<String, dynamic> toJson() => {
        'stringIndex': stringIndex,
        'fret': fret,
        'position': position,
        'duration': duration.label,
      };

  factory TabNote.fromJson(Map<String, dynamic> json) => TabNote(
        stringIndex: json['stringIndex'] as int,
        fret: json['fret'] as int,
        position: (json['position'] as num).toDouble(),
        duration: _parseDuration((json['duration'] as String?) ?? '4'),
      );

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
  final double playheadPosition; // Current beat position
  final int totalMeasures;
  final List<TabMeasure> measures;
  final bool isLooping;
  final bool isLiveMicMode;
  final NoteDuration selectedDuration; // Currently selected note duration for manual entry
  final List<double> tapTempoHistory; // BPM tap tempo samples

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
    this.tapTempoHistory = const [],
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
    List<double>? tapTempoHistory,
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

  void toggleRecording() {
    final bool newRecordingState = !state.isRecording;
    if (newRecordingState) {
      _recordedFrequencyBuffer.clear();
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
    if (_recordedFrequencyBuffer.isEmpty) return;

    final List<TabNote> batchNotes = [];
    final double totalBeats = (state.recordingDurationSeconds * state.currentBpm) / 60.0;
    final double beatStep = totalBeats / math.max(1, _recordedFrequencyBuffer.length);

    for (int i = 0; i < _recordedFrequencyBuffer.length; i++) {
      final double frequency = _recordedFrequencyBuffer[i];
      final double rawPos = i * beatStep;
      final double quantizedPos = ((rawPos * 4.0).round() / 4.0).clamp(0.0, totalBeats);

      // Infer duration from beat step between consecutive notes
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

    if (batchNotes.isNotEmpty) {
      final measureCount = (totalBeats / 4.0).ceil().clamp(1, 16).toInt();
      final updatedMeasures = List<TabMeasure>.generate(measureCount, (i) {
        final startBeat = i * 4.0;
        final endBeat = startBeat + 4.0;
        return TabMeasure(
          number: i + 1,
          notes: batchNotes.where((n) => n.position >= startBeat && n.position < endBeat).toList(),
        );
      });
      state = state.copyWith(measures: updatedMeasures, totalMeasures: measureCount);
      saveSessionToDevice();
    }
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
            _playNoteSynthAudio(note);
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
          TabNote(stringIndex: 4, fret: 2, position: 2.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 3, fret: 1, position: 3.0, duration: NoteDuration.quarter),
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
          TabNote(stringIndex: 5, fret: 3, position: 8.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 4, fret: 2, position: 9.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 3, fret: 0, position: 10.0, duration: NoteDuration.quarter),
          TabNote(stringIndex: 2, fret: 1, position: 11.0, duration: NoteDuration.quarter),
        ],
      ),
      const TabMeasure(
        number: 4,
        notes: [
          TabNote(stringIndex: 6, fret: 3, position: 12.0, duration: NoteDuration.half),
          TabNote(stringIndex: 5, fret: 2, position: 14.0, duration: NoteDuration.quarter),
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
