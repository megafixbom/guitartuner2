import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../services/audio_service.dart';
import '../services/pitch_engine.dart';

/// Request structure sent to the background DSP Isolate.
class TunerIsolateRequest {
  final Float64List samples;
  final bool isAutoMode;
  final GuitarString? manualTargetString;
  final int sequenceNumber;

  TunerIsolateRequest({
    required this.samples,
    required this.isAutoMode,
    this.manualTargetString,
    required this.sequenceNumber,
  });
}

/// Response structure received from the background DSP Isolate.
class TunerIsolateResponse {
  final TunerStatus status;
  final int sequenceNumber;

  TunerIsolateResponse(this.status, this.sequenceNumber);
}

/// Top-level entrypoint for the background audio processing Isolate.
/// Must be top-level or static to be spawned by Isolate.spawn.
void _tunerIsolateEntryPoint(SendPort mainSendPort) {
  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  // Initialize PitchEngine in the isolated thread context
  final pitchEngine = PitchEngine(
    sampleRate: AudioService.sampleRate,
    bufferSize: AudioService.windowSizeSamples,
  );

  isolateReceivePort.listen((message) {
    if (message is TunerIsolateRequest) {
      final status = pitchEngine.processAudioBuffer(
        message.samples,
        isAutoMode: message.isAutoMode,
        manualTargetString: message.manualTargetString,
      );
      mainSendPort.send(TunerIsolateResponse(status, message.sequenceNumber));
    } else if (message == 'close') {
      isolateReceivePort.close();
    }
  });
}

/// The overall State of the Tuner Page
class TunerAppState {
  final TunerStatus status;
  final bool isAutoMode;
  final GuitarString activeString;
  final bool isRecording;
  final String errorMessage;

  const TunerAppState({
    required this.status,
    required this.isAutoMode,
    required this.activeString,
    required this.isRecording,
    this.errorMessage = '',
  });

  TunerAppState copyWith({
    TunerStatus? status,
    bool? isAutoMode,
    GuitarString? activeString,
    bool? isRecording,
    String? errorMessage,
  }) {
    return TunerAppState(
      status: status ?? this.status,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      activeString: activeString ?? this.activeString,
      isRecording: isRecording ?? this.isRecording,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TunerStateNotifier extends StateNotifier<TunerAppState> {
  final AudioService _audioService = AudioService();
  StreamSubscription<Float64List>? _audioSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Isolate tracking variables
  Isolate? _tunerIsolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  int _nextSequenceNumber = 0;
  int _latestProcessedSequence = -1;

  // Track whether we played the "in tune" chime to avoid playing it continuously
  bool _hasPlayedInTuneChime = false;
  int? _lastTunedPegIndex;

  TunerStateNotifier()
      : super(TunerAppState(
          status: const TunerStatus.searching(0.0),
          isAutoMode: true,
          activeString: PitchEngine.standardGuitarTuning.last, // E2 (6th string)
          isRecording: false,
        ));

  /// Initialize, spawn the background Isolate and start microphone streaming
  Future<void> startTuning() async {
    if (state.isRecording) return;

    try {
      final stream = await _audioService.startRecordStream();
      
      // Reset sequence tracking
      _nextSequenceNumber = 0;
      _latestProcessedSequence = -1;

      // 1. Spawning long-running background isolate worker
      _mainReceivePort = ReceivePort();
      _tunerIsolate = await Isolate.spawn(
        _tunerIsolateEntryPoint,
        _mainReceivePort!.sendPort,
      );

      final Completer<SendPort> portCompleter = Completer<SendPort>();
      
      _mainReceivePort!.listen((message) {
        if (message is SendPort) {
          portCompleter.complete(message);
        } else if (message is TunerIsolateResponse) {
          _onIsolateResponse(message);
        }
      });

      _isolateSendPort = await portCompleter.future;
      state = state.copyWith(isRecording: true, errorMessage: '');

      // 2. Pipe raw float buffers from AudioService to the Isolate
      _audioSubscription = stream.listen(
        (Float64List doubleSamples) {
          if (_isolateSendPort != null) {
            _isolateSendPort!.send(TunerIsolateRequest(
              samples: doubleSamples,
              isAutoMode: state.isAutoMode,
              manualTargetString: state.activeString,
              sequenceNumber: _nextSequenceNumber++,
            ));
          }
        },
        onError: (err) {
          state = state.copyWith(
            isRecording: false,
            errorMessage: 'Audio error: ${err.toString()}',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        errorMessage: e.toString().contains('permission')
            ? 'Please grant microphone access in settings.'
            : 'Error starting tuner: $e',
      );
      await stopTuning();
    }
  }

  /// Stop microphone streaming and terminate Isolate thread
  Future<void> stopTuning() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    
    await _audioService.stopRecordStream();

    // Safely stop background thread event loop
    _isolateSendPort?.send('close');
    _isolateSendPort = null;

    _tunerIsolate?.kill(priority: Isolate.beforeNextEvent);
    _tunerIsolate = null;

    _mainReceivePort?.close();
    _mainReceivePort = null;

    state = state.copyWith(
      isRecording: false,
      status: const TunerStatus.searching(0.0),
    );
  }

  /// Switch between Auto and Manual tuning modes
  void toggleAutoMode() {
    state = state.copyWith(
      isAutoMode: !state.isAutoMode,
      status: const TunerStatus.searching(0.0),
    );
    _hasPlayedInTuneChime = false;
  }

  /// Select a target string manually (forces Manual Mode)
  void selectString(GuitarString string) {
    state = state.copyWith(
      isAutoMode: false,
      activeString: string,
      status: const TunerStatus.searching(0.0),
    );
    _hasPlayedInTuneChime = false;
    _playReferenceTone(string);
  }

  /// Handler for processed responses returned from the background Isolate
  void _onIsolateResponse(TunerIsolateResponse response) {
    // Drop outdated frames to prevent needle jitter if frames arrive out of order
    if (response.sequenceNumber < _latestProcessedSequence) {
      return;
    }
    _latestProcessedSequence = response.sequenceNumber;

    final status = response.status;

    // Coordinate the active string with what the engine detects in Auto mode
    GuitarString currentTarget = state.activeString;
    if (state.isAutoMode && status.targetString != null) {
      currentTarget = status.targetString!;
    }

    state = state.copyWith(
      status: status,
      activeString: currentTarget,
    );

    // Audio & Haptics Feedback for "In Tune" lock
    if (status.isPerfect) {
      if (!_hasPlayedInTuneChime || _lastTunedPegIndex != currentTarget.index) {
        _playInTuneFeedback();
        _hasPlayedInTuneChime = true;
        _lastTunedPegIndex = currentTarget.index;
      }
    } else {
      // If we drift out of tune, allow feedback to trigger next time it locks in
      if (status.centsOffset.abs() > 6.0) {
        _hasPlayedInTuneChime = false;
      }
    }
  }

  /// Play a synthetic string tone or preloaded WAV for manual tuning reference
  Future<void> _playReferenceTone(GuitarString string) async {
    try {
      await _audioPlayer.stop();
      // Production path for reference tones:
      // await _audioPlayer.play(AssetSource('sounds/${string.noteName}${string.octave}.wav'));
    } catch (_) {}
  }

  /// Play clean high-register visual chime and short device vibration
  Future<void> _playInTuneFeedback() async {
    try {
      final canVibrate = await Vibration.hasVibrator() ?? false;
      if (canVibrate) {
        Vibration.vibrate(duration: 80, amplitude: 128);
      }
      // Production path for lock chime:
      // await _audioPlayer.play(AssetSource('sounds/in_tune_chime.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioService.dispose();
    _audioPlayer.dispose();
    
    _isolateSendPort?.send('close');
    _tunerIsolate?.kill(priority: Isolate.beforeNextEvent);
    _mainReceivePort?.close();
    
    super.dispose();
  }
}

// Global provider for tuner state
final tunerStateProvider =
    StateNotifierProvider<TunerStateNotifier, TunerAppState>((ref) {
  return TunerStateNotifier();
});
