import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitartuner/services/audio_service.dart';
import 'package:guitartuner/services/pitch_engine.dart';

void main() {
  group('FloatRingBuffer Tests', () {
    test('Initialization status and capacity', () {
      final buffer = FloatRingBuffer(10);
      expect(buffer.capacity, equals(10));
      expect(buffer.size, equals(0));
    });

    test('Writing samples increases size without overflow', () {
      final buffer = FloatRingBuffer(5);
      
      buffer.writeSample(1.0);
      expect(buffer.size, equals(1));
      
      buffer.writeSample(2.0);
      buffer.writeSample(3.0);
      expect(buffer.size, equals(3));
      
      final output = Float64List(3);
      buffer.read(output, 3);
      expect(output, equals([1.0, 2.0, 3.0]));
    });

    test('Buffer overflow drops oldest samples (Circular Wrapping)', () {
      final buffer = FloatRingBuffer(4);
      
      // Fill to capacity
      buffer.writeSample(10.0);
      buffer.writeSample(20.0);
      buffer.writeSample(30.0);
      buffer.writeSample(40.0);
      expect(buffer.size, equals(4));

      // Writing 5th sample should trigger overflow and drop 10.0 (the oldest)
      buffer.writeSample(50.0);
      expect(buffer.size, equals(4));

      final output1 = Float64List(4);
      buffer.read(output1, 4);
      expect(output1, equals([20.0, 30.0, 40.0, 50.0]));

      // Writing 6th sample should drop 20.0
      buffer.writeSample(60.0);
      expect(buffer.size, equals(4));

      final output2 = Float64List(4);
      buffer.read(output2, 4);
      expect(output2, equals([30.0, 40.0, 50.0, 60.0]));
    });

    test('Reading does not advance read index', () {
      final buffer = FloatRingBuffer(4);
      buffer.writeSample(1.5);
      buffer.writeSample(2.5);

      final output1 = Float64List(2);
      buffer.read(output1, 2);
      expect(output1, equals([1.5, 2.5]));

      final output2 = Float64List(2);
      buffer.read(output2, 2);
      expect(output2, equals([1.5, 2.5])); // Values must remain identical
    });

    test('Advance updates size and read pointer', () {
      final buffer = FloatRingBuffer(4);
      buffer.writeSample(1.0);
      buffer.writeSample(2.0);
      buffer.writeSample(3.0);
      buffer.writeSample(4.0);

      // Advance by 2 samples
      buffer.advance(2);
      expect(buffer.size, equals(2));

      final output = Float64List(2);
      buffer.read(output, 2);
      expect(output, equals([3.0, 4.0]));

      // Write another sample after advance
      buffer.writeSample(5.0);
      expect(buffer.size, equals(3));

      final output2 = Float64List(3);
      buffer.read(output2, 3);
      expect(output2, equals([3.0, 4.0, 5.0]));
    });

    test('Clear resets size, write/read indices, and zero-fills buffer', () {
      final buffer = FloatRingBuffer(4);
      buffer.writeSample(1.0);
      buffer.writeSample(2.0);
      buffer.writeSample(3.0);

      buffer.clear();
      expect(buffer.size, equals(0));

      // After clearing, writing starts again at index 0
      buffer.writeSample(9.9);
      expect(buffer.size, equals(1));

      final output = Float64List(1);
      buffer.read(output, 1);
      expect(output[0], equals(9.9));
    });
  });

  group('YIN Pitch Cents Conversion Formulas & Mathematical Logic', () {
    double calculateCentsOffset(double smoothedFrequency, double targetHz) {
      return 1200 * (math.log(smoothedFrequency / targetHz) / math.ln2);
    }

    bool isWithinDeadZone(double centsOffset, double threshold) {
      return centsOffset.abs() <= threshold;
    }

    double getLockedCents(double centsOffset, bool isPerfect) {
      return isPerfect ? 0.0 : centsOffset;
    }

    double getClampedCents(double centsOffset) {
      return centsOffset.clamp(-50.0, 50.0);
    }

    test('Cents conversion formula calculates correct pitch deviations', () {
      const targetHz = 329.63;

      // 0 cents offset
      expect(calculateCentsOffset(329.63, targetHz), closeTo(0.0, 1e-5));

      // Exactly +10 cents offset: F = T * 2^(10/1200)
      final sharpPitch = targetHz * math.pow(2, 10 / 1200);
      expect(calculateCentsOffset(sharpPitch, targetHz), closeTo(10.0, 1e-5));

      // Exactly -10 cents offset: F = T * 2^(-10/1200)
      final flatPitch = targetHz * math.pow(2, -10 / 1200);
      expect(calculateCentsOffset(flatPitch, targetHz), closeTo(-10.0, 1e-5));

      // Sharp out of dial range (+60 cents)
      final verySharpPitch = targetHz * math.pow(2, 60 / 1200);
      expect(calculateCentsOffset(verySharpPitch, targetHz), closeTo(60.0, 1e-5));
    });

    test('In-tune dead-zone lock logic (1.5 cents threshold)', () {
      const double threshold = 1.5;

      // Case 1: Exactly 0.0 cents
      expect(isWithinDeadZone(0.0, threshold), isTrue);
      expect(getLockedCents(0.0, true), equals(0.0));

      // Case 2: Within dead-zone (e.g. 1.0 cents sharp)
      expect(isWithinDeadZone(1.0, threshold), isTrue);
      expect(getLockedCents(1.0, true), equals(0.0));

      // Case 3: Within dead-zone (e.g. -1.0 cents flat)
      expect(isWithinDeadZone(-1.0, threshold), isTrue);
      expect(getLockedCents(-1.0, true), equals(0.0));

      // Case 4: Exactly on the positive boundary (1.5 cents)
      expect(isWithinDeadZone(1.5, threshold), isTrue);
      expect(getLockedCents(1.5, true), equals(0.0));

      // Case 5: Exactly on the negative boundary (-1.5 cents)
      expect(isWithinDeadZone(-1.5, threshold), isTrue);
      expect(getLockedCents(-1.5, true), equals(0.0));

      // Case 6: Just outside the dead-zone sharp (1.6 cents)
      expect(isWithinDeadZone(1.6, threshold), isFalse);
      expect(getLockedCents(1.6, false), equals(1.6));

      // Case 7: Just outside the dead-zone flat (-1.6 cents)
      expect(isWithinDeadZone(-1.6, threshold), isFalse);
      expect(getLockedCents(-1.6, false), equals(-1.6));
    });

    test('Cents clamping to [-50.0, 50.0] for dial rendering', () {
      expect(getClampedCents(30.0), equals(30.0));
      expect(getClampedCents(-30.0), equals(-30.0));
      expect(getClampedCents(55.0), equals(50.0));
      expect(getClampedCents(-55.0), equals(-50.0));
      expect(getClampedCents(0.0), equals(0.0));
    });
  });

  group('PitchEngine End-to-End DSP & Processing Validation', () {
    late PitchEngine engine;

    setUp(() {
      engine = PitchEngine(
        sampleRate: 16000,
        bufferSize: 2048,
      );
    });

    List<double> generateSineWave(double frequency, double sampleRate, int length, {double amplitude = 0.5}) {
      final samples = List<double>.filled(length, 0.0);
      for (int i = 0; i < length; i++) {
        samples[i] = amplitude * math.sin(2 * math.pi * frequency * i / sampleRate);
      }
      return samples;
    }

    test('Noise floor RMS gating: silence', () {
      final silence = List<double>.filled(2048, 0.0);
      final status = engine.processAudioBuffer(silence, isAutoMode: true);
      
      expect(status.volumeLevel, equals(0.0));
      expect(status.detectedFrequency, isNull);
      expect(status.message, equals('Pluck a string'));
      expect(status.isPerfect, isFalse);
    });

    test('Noise floor RMS gating: low-level noise below floor', () {
      final lowNoise = generateSineWave(440.0, 16000.0, 2048, amplitude: 0.004);
      final status = engine.processAudioBuffer(lowNoise, isAutoMode: true);
      
      expect(status.volumeLevel, lessThan(PitchEngine.noiseFloorRms));
      expect(status.detectedFrequency, isNull);
      expect(status.message, equals('Pluck a string'));
    });

    test('Pitch detection, target string identification, and cents locking on High E (329.63 Hz)', () {
      const targetHz = 329.63;

      // Case A: Perfect tune (329.63 Hz)
      final perfectBuffer = generateSineWave(targetHz, 16000.0, 2048, amplitude: 0.5);
      final statusPerfect = engine.processAudioBuffer(perfectBuffer, isAutoMode: true);
      
      expect(statusPerfect.volumeLevel, greaterThan(PitchEngine.noiseFloorRms));
      expect(statusPerfect.detectedFrequency, isNotNull);
      expect(statusPerfect.targetString?.noteName, equals('E'));
      expect(statusPerfect.targetString?.index, equals(1));
      expect(statusPerfect.isPerfect, isTrue);
      expect(statusPerfect.centsOffset, equals(0.0));
      expect(statusPerfect.message, equals('In Tune'));

      engine = PitchEngine(sampleRate: 16000, bufferSize: 2048);

      // Case B: Slightly sharp but within dead-zone (e.g. 329.8 Hz => ~0.89 cents)
      final withinDeadZoneBuffer = generateSineWave(329.8, 16000.0, 2048, amplitude: 0.5);
      final statusDeadZone = engine.processAudioBuffer(withinDeadZoneBuffer, isAutoMode: true);
      
      expect(statusDeadZone.isPerfect, isTrue);
      expect(statusDeadZone.centsOffset, equals(0.0));
      expect(statusDeadZone.message, equals('In Tune'));

      engine = PitchEngine(sampleRate: 16000, bufferSize: 2048);

      // Case C: Sharp and outside dead-zone (e.g. 331.0 Hz => ~7.18 cents)
      final sharpBuffer = generateSineWave(331.0, 16000.0, 2048, amplitude: 0.5);
      final statusSharp = engine.processAudioBuffer(sharpBuffer, isAutoMode: true);
      
      expect(statusSharp.isPerfect, isFalse);
      expect(statusSharp.centsOffset, greaterThan(1.5));
      expect(statusSharp.message, equals('Too Sharp'));

      engine = PitchEngine(sampleRate: 16000, bufferSize: 2048);

      // Case D: Flat and outside dead-zone (e.g. 328.0 Hz => ~-8.59 cents)
      final flatBuffer = generateSineWave(328.0, 16000.0, 2048, amplitude: 0.5);
      final statusFlat = engine.processAudioBuffer(flatBuffer, isAutoMode: true);
      
      expect(statusFlat.isPerfect, isFalse);
      expect(statusFlat.centsOffset, lessThan(-1.5));
      expect(statusFlat.message, equals('Too Flat'));
    });

    test('EMA Smoothing Logic over sequential samples', () {
      final buffer1 = generateSineWave(329.63, 16000.0, 2048, amplitude: 0.5);
      final status1 = engine.processAudioBuffer(buffer1, isAutoMode: true);
      final double? p1 = status1.detectedFrequency;
      expect(p1, isNotNull);
      expect(status1.smoothedFrequency, equals(p1));

      final buffer2 = generateSineWave(331.54, 16000.0, 2048, amplitude: 0.5);
      final status2 = engine.processAudioBuffer(buffer2, isAutoMode: true);
      final double? p2 = status2.detectedFrequency;
      expect(p2, isNotNull);

      final double expectedSmoothed = (PitchEngine.emaAlpha * p2!) + ((1.0 - PitchEngine.emaAlpha) * p1!);
      expect(status2.smoothedFrequency, closeTo(expectedSmoothed, 1e-4));
    });
  });
}
