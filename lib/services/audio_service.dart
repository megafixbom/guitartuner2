import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Preallocated circular ring buffer for float samples to eliminate garbage collection churn.
class FloatRingBuffer {
  final int capacity;
  final Float64List _buffer;
  int _writeIndex = 0;
  int _readIndex = 0;
  int _size = 0;

  FloatRingBuffer(this.capacity) : _buffer = Float64List(capacity);

  int get size => _size;

  /// Writes a single double sample to the ring buffer.
  void writeSample(double sample) {
    _buffer[_writeIndex] = sample;
    _writeIndex = (_writeIndex + 1) % capacity;
    if (_size < capacity) {
      _size++;
    } else {
      // Buffer overflow: drop oldest sample by advancing read index
      _readIndex = (_readIndex + 1) % capacity;
    }
  }

  /// Reads [count] samples into [output] buffer without advancing read pointer.
  void read(Float64List output, int count) {
    int tempRead = _readIndex;
    for (int i = 0; i < count; i++) {
      output[i] = _buffer[tempRead];
      tempRead = (tempRead + 1) % capacity;
    }
  }

  /// Advances the read pointer by [count].
  void advance(int count) {
    _readIndex = (_readIndex + count) % capacity;
    _size = math.max(0, _size - count);
  }

  /// Clear the buffer pointers
  void clear() {
    _writeIndex = 0;
    _readIndex = 0;
    _size = 0;
    _buffer.fillRange(0, capacity, 0.0);
  }
}

class AudioService {
  final _recorder = AudioRecorder();
  StreamController<Float64List>? _pcmFloatStreamController;
  StreamSubscription<Uint8List>? _micSubscription;

  // 16kHz audio configuration
  static const int sampleRate = 16000;
  // Window size of 2048 samples (128ms buffer) is ideal for YIN pitch detection down to E2 (82.4Hz)
  static const int windowSizeSamples = 2048;
  static const int bytesPerSample = 2; // PCM 16-bit (2 bytes per sample)

  // Preallocated buffer structures to eliminate garbage collection pressure
  late final FloatRingBuffer _ringBuffer;
  late final Float64List _outputWindow;

  AudioService() {
    // Capacity of 8192 samples provides ample buffer space (512ms)
    _ringBuffer = FloatRingBuffer(8192);
    _outputWindow = Float64List(windowSizeSamples);
  }

  /// Check and request microphone permission
  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Starts capturing microphone stream at 16kHz mono PCM
  Future<Stream<Float64List>> startRecordStream() async {
    if (_pcmFloatStreamController != null) {
      await stopRecordStream();
    }

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied.');
    }

    _pcmFloatStreamController = StreamController<Float64List>.broadcast();
    _ringBuffer.clear();

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1, // Mono
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    );

    try {
      final recordStream = await _recorder.startStream(config);
      
      _micSubscription = recordStream.listen(
        (Uint8List chunk) {
          _processRawBytes(chunk);
        },
        onError: (error) {
          _pcmFloatStreamController?.addError(error);
        },
        onDone: () {
          stopRecordStream();
        },
      );
    } catch (e) {
      _pcmFloatStreamController?.addError(e);
      await stopRecordStream();
    }

    return _pcmFloatStreamController!.stream;
  }

  /// Stop streaming and release microphone resources
  Future<void> stopRecordStream() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}

    await _pcmFloatStreamController?.close();
    _pcmFloatStreamController = null;
    _ringBuffer.clear();
  }

  /// Processes raw 16-bit PCM bytes, writes to circular buffer,
  /// and emits fixed window float packages.
  void _processRawBytes(Uint8List newBytes) {
    final int sampleCount = newBytes.length ~/ bytesPerSample;
    if (sampleCount == 0) return;

    final ByteData byteData = ByteData.sublistView(newBytes);
    
    // Write directly into circular buffer
    for (int i = 0; i < sampleCount; i++) {
      final int sampleValue = byteData.getInt16(i * bytesPerSample, Endian.little);
      final double doubleVal = sampleValue / 32768.0;
      _ringBuffer.writeSample(doubleVal);
    }

    // Emit windows with 50% overlap (step of 1024 samples)
    const int stepSamples = windowSizeSamples ~/ 2; 
    while (_ringBuffer.size >= windowSizeSamples) {
      _ringBuffer.read(_outputWindow, windowSizeSamples);
      
      // Emit a snapshot of the current window buffer
      _pcmFloatStreamController?.add(Float64List.fromList(_outputWindow));
      
      _ringBuffer.advance(stepSamples);
    }
  }

  /// Cleanup resources
  void dispose() {
    stopRecordStream();
    _recorder.dispose();
  }
}
