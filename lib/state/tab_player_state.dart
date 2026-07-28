import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Represents a single note on a guitar tab staff (fret position & string index)
class TabNote {
  final int stringIndex; // 1 to 6 (1 is High E, 6 is Low E)
  final int fret;        // 0 (open) to 24
  final double position; // Beat position in track timeline

  const TabNote({
    required this.stringIndex,
    required this.fret,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'stringIndex': stringIndex,
        'fret': fret,
        'position': position,
      };

  factory TabNote.fromJson(Map<String, dynamic> json) => TabNote(
        stringIndex: json['stringIndex'] as int,
        fret: json['fret'] as int,
        position: (json['position'] as num).toDouble(),
      );
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

  void toggleLiveMicMode() {
    state = state.copyWith(isLiveMicMode: !state.isLiveMicMode);
  }

  final List<double> _recordedFrequencyBuffer = [];

  void recordRawFrequencySample(double frequency) {
    if (state.isRecording && frequency > 70.0 && frequency < 400.0) {
      _recordedFrequencyBuffer.add(frequency);
    }
  }

  void toggleRecording() {
    final bool newRecordingState = !state.isRecording;
    if (newRecordingState) {
      _recordedFrequencyBuffer.clear();
      state = state.copyWith(
        isRecording: true,
        isPlaying: true,
        isLiveMicMode: true,
        recordingDurationSeconds: 0.0,
        waveformLevels: [],
      );
    } else {
      // Upon hitting "Stop Recording", instantly process recorded frequency list through mapping algorithm
      _processBatchRecordedFrequencies();
      state = state.copyWith(
        isRecording: false,
        isPlaying: false,
      );
    }
  }

  void _processBatchRecordedFrequencies() {
    if (_recordedFrequencyBuffer.isEmpty) return;

    final stringBaseHz = [329.63, 246.94, 196.00, 146.83, 110.00, 82.41];
    final List<TabNote> batchNotes = [];

    // Step through recorded frequencies and map into string (1-6) and fret (0-24) coordinates
    final double beatStep = 16.0 / math.max(1, _recordedFrequencyBuffer.length);
    for (int i = 0; i < _recordedFrequencyBuffer.length; i++) {
      final double frequency = _recordedFrequencyBuffer[i];
      int bestStringIndex = 6;
      int bestFret = 0;
      double minCentsDiff = double.infinity;

      for (int s = 0; s < 6; s++) {
        final double baseHz = stringBaseHz[s];
        final double fretCalc = 12.0 * (math.log(frequency / baseHz) / math.ln2);
        final int fretRounded = fretCalc.round();

        if (fretRounded >= 0 && fretRounded <= 24) {
          final double exactFretHz = baseHz * math.pow(2.0, fretRounded / 12.0);
          final double centsDiff = (1200.0 * (math.log(frequency / exactFretHz) / math.ln2)).abs();

          if (centsDiff < minCentsDiff) {
            minCentsDiff = centsDiff;
            bestStringIndex = s + 1; // 1 to 6
            bestFret = fretRounded;
          }
        }
      }

      if (minCentsDiff < 45.0) {
        final double notePos = (i * beatStep).clamp(0.0, 15.5);
        batchNotes.add(TabNote(stringIndex: bestStringIndex, fret: bestFret, position: notePos));
      }
    }

    if (batchNotes.isNotEmpty) {
      // Quantize and group into 4 measures
      final updatedMeasures = [
        TabMeasure(number: 1, notes: batchNotes.where((n) => n.position < 4.0).toList()),
        TabMeasure(number: 2, notes: batchNotes.where((n) => n.position >= 4.0 && n.position < 8.0).toList()),
        TabMeasure(number: 3, notes: batchNotes.where((n) => n.position >= 8.0 && n.position < 12.0).toList()),
        TabMeasure(number: 4, notes: batchNotes.where((n) => n.position >= 12.0).toList()),
      ];
      state = state.copyWith(measures: updatedMeasures);
      saveSessionToDevice();
    }
  }

  /// Serializes the current tab session measures & notes into JSON and saves to local device storage
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

  /// Loads a serialized JSON tab session from local device storage
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

  void updateRecordingTimer(double elapsedSeconds) {
    if (state.isRecording) {
      state = state.copyWith(recordingDurationSeconds: elapsedSeconds);
    }
  }

  void pushWaveformLevel(double rmsLevel) {
    if (state.isRecording) {
      final updatedWaveform = List<double>.from(state.waveformLevels)..add(rmsLevel);
      if (updatedWaveform.length > 30) {
        updatedWaveform.removeAt(0);
      }
      state = state.copyWith(waveformLevels: updatedWaveform);
    }
  }

  final AudioPlayer _synthAudioPlayer = AudioPlayer();
  final Set<double> _triggeredBeatPositions = {};

  void togglePlayPause() {
    final bool newIsPlaying = !state.isPlaying;
    if (!newIsPlaying) {
      _triggeredBeatPositions.clear();
    }
    state = state.copyWith(isPlaying: newIsPlaying);
  }

  void setBpm(double bpm) {
    state = state.copyWith(currentBpm: bpm);
  }

  void seekTo(double position) {
    if (position < state.playheadPosition) {
      _triggeredBeatPositions.clear();
    }
    
    // Only update state if position has shifted by at least 0.02 beats to reduce UI rebuild churn
    if ((position - state.playheadPosition).abs() >= 0.02) {
      state = state.copyWith(playheadPosition: position);
    }
    
    // Trigger synth note audio as playhead advances across beat positions
    if (state.isPlaying) {
      for (var measure in state.measures) {
        for (var note in measure.notes) {
          if ((position - note.position).abs() < 0.25 && !_triggeredBeatPositions.contains(note.position)) {
            _triggeredBeatPositions.add(note.position);
            _playNoteSynthAudio(note);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _synthAudioPlayer.dispose();
    super.dispose();
  }

  void _playNoteSynthAudio(TabNote note) async {
    // Map stringIndex (1..6) to corresponding reference sound asset name
    final stringNames = ['E4', 'B3', 'G3', 'D3', 'A2', 'E2'];
    if (note.stringIndex >= 1 && note.stringIndex <= 6) {
      final String soundFile = stringNames[note.stringIndex - 1];
      try {
        await _synthAudioPlayer.play(AssetSource('sounds/$soundFile.wav'));
      } catch (_) {}
    }
  }

  /// Converts a detected fundamental frequency (Hz) into exact Guitar String & Fret index (0-24)
  void recordTranscribedPitch(double frequency) {
    if (!state.isLiveMicMode || frequency < 70.0 || frequency > 400.0) return;

    // Guitar string fundamental target frequencies (E4: 329.63Hz, B3: 246.94Hz, G3: 196Hz, D3: 146.83Hz, A2: 110Hz, E2: 82.41Hz)
    final stringBaseHz = [329.63, 246.94, 196.00, 146.83, 110.00, 82.41];

    int bestStringIndex = 6;
    int bestFret = 0;
    double minCentsDiff = double.infinity;

    for (int s = 0; s < 6; s++) {
      final double baseHz = stringBaseHz[s];
      // Calculate fret position for frequency: fret = 12 * log2(F / Base)
      final double fretCalc = 12.0 * (math.log(frequency / baseHz) / math.ln2);
      final int fretRounded = fretCalc.round();

      if (fretRounded >= 0 && fretRounded <= 15) {
        final double exactFretHz = baseHz * math.pow(2.0, fretRounded / 12.0);
        final double centsDiff = (1200.0 * (math.log(frequency / exactFretHz) / math.ln2)).abs();

        if (centsDiff < minCentsDiff) {
          minCentsDiff = centsDiff;
          bestStringIndex = s + 1; // 1 to 6
          bestFret = fretRounded;
        }
      }
    }

    // Append transcribed note to current measure in live recording mode
    if (minCentsDiff < 45.0) {
      final double currentPos = state.playheadPosition;
      final newNote = TabNote(stringIndex: bestStringIndex, fret: bestFret, position: currentPos);

      final updatedMeasures = List<TabMeasure>.from(state.measures);
      if (updatedMeasures.isNotEmpty) {
        final lastMeasureIndex = updatedMeasures.length - 1;
        final currentNotes = List<TabNote>.from(updatedMeasures[lastMeasureIndex].notes);

        // Replace or append note at current beat position
        currentNotes.removeWhere((n) => (n.position - currentPos).abs() < 0.35);
        currentNotes.add(newNote);

        updatedMeasures[lastMeasureIndex] = TabMeasure(
          number: updatedMeasures[lastMeasureIndex].number,
          notes: currentNotes,
        );

        state = state.copyWith(measures: updatedMeasures);
      }
    }
  }

  void toggleLoop() {
    state = state.copyWith(isLooping: !state.isLooping);
  }

  static List<TabMeasure> _generateSampleTab() {
    return [
      const TabMeasure(
        number: 1,
        notes: [
          TabNote(stringIndex: 6, fret: 0, position: 0.0),
          TabNote(stringIndex: 5, fret: 2, position: 1.0),
          TabNote(stringIndex: 4, fret: 2, position: 2.0),
          TabNote(stringIndex: 3, fret: 1, position: 3.0),
        ],
      ),
      const TabMeasure(
        number: 2,
        notes: [
          TabNote(stringIndex: 1, fret: 3, position: 4.0),
          TabNote(stringIndex: 2, fret: 0, position: 5.0),
          TabNote(stringIndex: 3, fret: 0, position: 6.0),
          TabNote(stringIndex: 4, fret: 0, position: 7.0),
        ],
      ),
      const TabMeasure(
        number: 3,
        notes: [
          TabNote(stringIndex: 5, fret: 3, position: 8.0),
          TabNote(stringIndex: 4, fret: 2, position: 9.0),
          TabNote(stringIndex: 3, fret: 0, position: 10.0),
          TabNote(stringIndex: 2, fret: 1, position: 11.0),
        ],
      ),
      const TabMeasure(
        number: 4,
        notes: [
          TabNote(stringIndex: 6, fret: 3, position: 12.0),
          TabNote(stringIndex: 5, fret: 2, position: 13.0),
          TabNote(stringIndex: 1, fret: 3, position: 14.0),
          TabNote(stringIndex: 2, fret: 3, position: 15.0),
        ],
      ),
    ];
  }
}

final tabPlayerProvider =
    StateNotifierProvider<TabPlayerNotifier, TabPlayerState>((ref) {
  return TabPlayerNotifier();
});
