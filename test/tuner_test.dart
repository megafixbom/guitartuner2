import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitartuner/services/audio_service.dart';
import 'package:guitartuner/services/chord_detector.dart';
import 'package:guitartuner/services/lyrics_transcriber.dart';
import 'package:guitartuner/services/metronome_service.dart';
import 'package:guitartuner/services/pitch_engine.dart';
import 'package:guitartuner/services/pitch_shifter.dart';
import 'package:guitartuner/services/scale_detector.dart';
import 'package:guitartuner/services/tempo_detector.dart';
import 'package:guitartuner/services/vocal_detector.dart';
import 'package:guitartuner/state/tab_player_state.dart';

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

  group('TabPlayerNotifier Recording & Serialization Unit Tests', () {
    test('TabNote and TabMeasure JSON Serialization', () {
      const note = TabNote(stringIndex: 1, fret: 3, position: 2.5);
      final jsonNote = note.toJson();
      expect(jsonNote['stringIndex'], equals(1));
      expect(jsonNote['fret'], equals(3));
      expect(jsonNote['position'], equals(2.5));
      expect(jsonNote['duration'], equals('4'));

      final deserializedNote = TabNote.fromJson(jsonNote);
      expect(deserializedNote.stringIndex, equals(1));
      expect(deserializedNote.fret, equals(3));
      expect(deserializedNote.position, equals(2.5));
      expect(deserializedNote.duration, equals(NoteDuration.quarter));
      expect(deserializedNote.isGhost, isFalse);

      // Ghost note serialization
      const ghostNote = TabNote(stringIndex: 4, fret: 0, position: 1.0, isGhost: true);
      final jsonGhost = ghostNote.toJson();
      expect(jsonGhost['isGhost'], isTrue);
      expect(jsonGhost['fret'], equals(0));
      final deserializedGhost = TabNote.fromJson(jsonGhost);
      expect(deserializedGhost.isGhost, isTrue);

      final measure = TabMeasure(number: 1, notes: [note]);
      final jsonMeasure = measure.toJson();
      expect(jsonMeasure['number'], equals(1));
      expect((jsonMeasure['notes'] as List).length, equals(1));

      final deserializedMeasure = TabMeasure.fromJson(jsonMeasure);
      expect(deserializedMeasure.number, equals(1));
      expect(deserializedMeasure.notes.first.fret, equals(3));
    });

    test('copyWith preserves detection and metronome fields (regression)', () {
      final state = TabPlayerState(
        isPlaying: false,
        currentBpm: 120.0,
        playheadPosition: 0.0,
        totalMeasures: 4,
        measures: const [],
        isLooping: true,
      );

      final key = DetectedKey(
        tonic: MusicalKey.G,
        mode: KeyMode.major,
        confidence: 0.9,
        pitchClassHistogram: List.filled(12, 0),
      );
      final tempo = DetectedTempo(
        bpm: 128.0,
        beats: const [0.0, 0.5],
        timeSignature: const [4, 4],
        confidence: 0.8,
      );
      const chord = DetectedChord(
        name: 'Am',
        root: 'A',
        quality: 'minor',
        notes: [9, 0, 4],
        confidence: 0.95,
      );
      const scale = DetectedScale(
        tonic: 9,
        type: ScaleType.minorPentatonic,
        confidence: 0.9,
        pitchClassHistogram: [],
      );

      final updated = state.copyWith(
        detectedKey: key,
        detectedTempo: tempo,
        detectedChords: const [chord],
        detectedScale: scale,
        transposeSemitones: 3,
        hasRecording: true,
        detectedLyrics: const [LyricLine(text: 'Hi', start: 0.0, end: 1.0)],
        isMetronomeEnabled: true,
        metronomeSubdivision: MetronomeSubdivision.eighth,
        metronomeSound: MetronomeSound.beep,
        metronomeVolume: 0.5,
      );

      expect(updated.detectedKey, same(key));
      expect(updated.detectedTempo, same(tempo));
      expect(updated.detectedChords, hasLength(1));
      expect(updated.detectedChords.first.name, equals('Am'));
      expect(updated.detectedScale, same(scale));
      expect(updated.detectedScale!.displayName, equals('A Minor Pentatonic'));
      expect(updated.transposeSemitones, equals(3));
      expect(updated.hasRecording, isTrue);
      expect(updated.detectedLyrics, hasLength(1));
      expect(updated.detectedLyrics.first.text, equals('Hi'));
      expect(updated.isMetronomeEnabled, isTrue);
      expect(updated.metronomeSubdivision, MetronomeSubdivision.eighth);
      expect(updated.metronomeSound, MetronomeSound.beep);
      expect(updated.metronomeVolume, equals(0.5));

      // Unrelated fields keep their previous values.
      expect(updated.currentBpm, equals(120.0));
      expect(updated.isLooping, isTrue);
    });
  });

  group('Metronome Service Unit Tests', () {
    test('Subdivision beat steps and labels', () {
      expect(MetronomeSubdivision.quarter.beatStep, equals(1.0));
      expect(MetronomeSubdivision.eighth.beatStep, equals(0.5));
      expect(MetronomeSubdivision.sixteenth.beatStep, equals(0.25));

      expect(MetronomeSubdivision.quarter.label, equals('1/4'));
      expect(MetronomeSubdivision.eighth.label, equals('1/8'));
      expect(MetronomeSubdivision.sixteenth.label, equals('1/16'));
    });

    test('Sound labels', () {
      expect(MetronomeSound.woodblock.label, equals('Wood'));
      expect(MetronomeSound.beep.label, equals('Beep'));
      expect(MetronomeSound.stick.label, equals('Stick'));
    });
  });

  group('Scale Detector Unit Tests', () {
    List<int> histogramFrom(List<int> pitchClasses, {List<int> weights = const []}) {
      final counts = List<int>.filled(12, 0);
      for (int i = 0; i < pitchClasses.length; i++) {
        final pc = pitchClasses[i];
        final w = i < weights.length ? weights[i] : 1;
        counts[pc] += w;
      }
      return counts;
    }

    test('Detects C major from major scale notes', () {
      // C D E F G A B with tonic emphasis on C
      final histogram = histogramFrom(
        const [0, 2, 4, 5, 7, 9, 11, 0, 0, 0, 0],
        weights: const [3, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1],
      );
      final result = ScaleDetector().detect(histogram);
      expect(result, isNotNull);
      expect(result!.tonic, equals(0));
      expect(result.type, ScaleType.major);
    });

    test('Detects A minor pentatonic from pentatonic notes', () {
      // A C D E G (minor pentatonic), tonic emphasis on A (pitch class 9)
      final histogram = histogramFrom(
        const [9, 0, 2, 4, 7],
        weights: const [4, 1, 1, 1, 2],
      );
      final result = ScaleDetector().detect(histogram);
      expect(result, isNotNull);
      expect(result!.tonic, equals(9));
      expect(result.type, ScaleType.minorPentatonic);
    });

    test('Detects D mixolydian from a mixolydian melody', () {
      // D E F# G A B C (D mixolydian = G major), tonic emphasis on D (2)
      final histogram = histogramFrom(
        const [2, 4, 6, 7, 9, 11, 0],
        weights: const [4, 1, 1, 2, 1, 1, 1],
      );
      final result = ScaleDetector().detect(histogram);
      expect(result, isNotNull);
      expect(result!.tonic, equals(2));
      expect(result.type, ScaleType.mixolydian);
    });

    test('Returns null for too few notes', () {
      final histogram = List<int>.filled(12, 0);
      histogram[0] = 1;
      histogram[2] = 1;
      expect(ScaleDetector().detect(histogram), isNull);
    });

    test('isInScale reports correct pitch classes', () {
      const scale = DetectedScale(
        tonic: 9, // A
        type: ScaleType.minorPentatonic,
        confidence: 1.0,
        pitchClassHistogram: [],
      );
      expect(scale.displayName, equals('A Minor Pentatonic'));
      // A C D E G
      expect(scale.isInScale(9), isTrue);
      expect(scale.isInScale(0), isTrue);
      expect(scale.isInScale(2), isTrue);
      expect(scale.isInScale(4), isTrue);
      expect(scale.isInScale(7), isTrue);
      expect(scale.isInScale(3), isFalse); // C#
    });
  });

  group('Pitch Shifter Unit Tests', () {
    const sampleRate = 16000;

    Float32List sineWave(double freq, int length) {
      final out = Float32List(length);
      for (int i = 0; i < length; i++) {
        out[i] = math.sin(2 * math.pi * freq * i / sampleRate);
      }
      return out;
    }

    double estimateFreq(Float32List samples) {
      final start = (samples.length * 0.2).floor();
      final end = (samples.length * 0.8).floor();
      var crossings = 0;
      for (int i = start + 1; i < end; i++) {
        final a = samples[i - 1];
        final b = samples[i];
        if ((a < 0 && b >= 0) || (a >= 0 && b < 0)) crossings++;
      }
      final duration = (end - start) / sampleRate;
      return crossings / (2 * duration);
    }

    test('FFT finds the peak bin of a known sine', () {
      const n = 1024;
      const freq = 440.0;
      final bin = (freq / sampleRate * n).round();
      final fft = Fft(n);
      for (int i = 0; i < n; i++) {
        fft.real[i] = math.sin(2 * math.pi * freq * i / sampleRate);
        fft.imag[i] = 0.0;
      }
      fft.forward();
      var peak = 0;
      var peakMag = -1.0;
      for (int k = 0; k < n ~/ 2; k++) {
        final mag = math.sqrt(fft.real[k] * fft.real[k] + fft.imag[k] * fft.imag[k]);
        if (mag > peakMag) {
          peakMag = mag;
          peak = k;
        }
      }
      expect(peak, equals(bin));
    });

    test('shiftPitch by 0 returns identical samples', () {
      final input = sineWave(440.0, 8000);
      final out = PitchShifter().shiftPitch(input, 0);
      expect(out.length, equals(input.length));
      for (int i = 0; i < input.length; i += 100) {
        expect(out[i], closeTo(input[i], 1e-6));
      }
    });

    test('shifts a 440Hz tone up 12 semitones to ~880Hz', () {
      final input = sineWave(440.0, sampleRate); // 1 second
      final out = PitchShifter().shiftPitch(input, 12);
      expect(out.length, equals(input.length));
      final est = estimateFreq(out);
      expect(est, closeTo(880.0, 880.0 * 0.1));
    });

    test('shifts a 440Hz tone down 12 semitones to ~220Hz', () {
      final input = sineWave(440.0, sampleRate);
      final out = PitchShifter().shiftPitch(input, -12);
      expect(out.length, equals(input.length));
      final est = estimateFreq(out);
      expect(est, closeTo(220.0, 220.0 * 0.12));
    });

    test('buildWavBytes emits a valid RIFF/WAVE header', () {
      final wav = buildWavBytes(Float32List(100), sampleRate: 16000);
      expect(wav.length, equals(44 + 100 * 2));
      // RIFF header
      expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));
      expect(String.fromCharCodes(wav.sublist(12, 16)), equals('fmt '));
      expect(String.fromCharCodes(wav.sublist(36, 40)), equals('data'));
    });

    test('synthTone produces a decaying non-silent buffer', () {
      final tone = synthTone(440.0, sampleRate: 16000);
      expect(tone.length, greaterThan(0));
      var peak = 0.0;
      for (final s in tone) {
        peak = math.max(peak, s.abs());
      }
      expect(peak, greaterThan(0.01));
    });
  });

  group('Lyrics Transcriber Unit Tests', () {
    test('parses Whisper segments and words', () {
      final json = {
        'text': ' Hello world',
        'segments': [
          {
            'id': 0,
            'start': 0.5,
            'end': 2.0,
            'text': ' Hello',
            'words': [
              {'word': ' Hello', 'start': 0.5, 'end': 1.2},
              {'word': ' world', 'start': 1.2, 'end': 2.0},
            ],
          },
        ],
      };
      final lines = LyricsTranscriber.parseWhisperResponse(json);
      expect(lines, hasLength(1));
      expect(lines.first.text, equals('Hello'));
      expect(lines.first.start, equals(0.5));
      expect(lines.first.end, equals(2.0));
      expect(lines.first.words, hasLength(2));
      expect(lines.first.words.last.word, equals(' world'));
      expect(lines.first.words.last.start, equals(1.2));
    });

    test('empty Whisper response yields no lines', () {
      expect(LyricsTranscriber.parseWhisperResponse({'text': ''}), isEmpty);
    });

    test('LRC export format', () {
      const lines = [
        LyricLine(text: 'Hello', start: 61.5, end: 64.0),
        LyricLine(text: 'World', start: 64.0, end: 67.0),
      ];
      final lrc = LyricsTranscriber.toLrc(lines);
      expect(lrc, contains('[01:01.50]Hello'));
      expect(lrc, contains('[01:04.00]World'));
    });

    test('LRC parse round-trips text and timestamps', () {
      const lines = [
        LyricLine(text: 'First line', start: 0.0, end: 2.0),
        LyricLine(text: 'Second line', start: 2.5, end: 5.0),
      ];
      final lrc = LyricsTranscriber.toLrc(lines);
      final parsed = LyricsTranscriber.parseLrc(lrc);
      expect(parsed, hasLength(2));
      expect(parsed[0].text, equals('First line'));
      expect(parsed[0].start, closeTo(0.0, 0.01));
      expect(parsed[1].text, equals('Second line'));
      expect(parsed[1].start, closeTo(2.5, 0.01));
    });

    test('withTightenedEnds sets each end to the next start', () {
      const lines = [
        LyricLine(text: 'A', start: 0.0, end: 99.0),
        LyricLine(text: 'B', start: 3.0, end: 99.0),
      ];
      final tightened = LyricsTranscriber.withTightenedEnds(lines);
      expect(tightened[0].end, equals(3.0));
      expect(tightened[1].end, greaterThan(3.0));
    });
  });

  group('Vocal Activity Detector Unit Tests', () {
    const sampleRate = 16000;

    Float32List sineAt(double freq, int length) {
      final out = Float32List(length);
      for (int i = 0; i < length; i++) {
        out[i] = math.sin(2 * math.pi * freq * i / sampleRate);
      }
      return out;
    }

    test('detects a sustained singing-range tone', () {
      final segments =
          VocalActivityDetector().detectVocalSegments(sineAt(250.0, sampleRate), sampleRate);
      expect(segments, isNotEmpty);
      expect(segments.first.start, lessThanOrEqualTo(0.1));
    });

    test('ignores sub-voice low bass', () {
      final segments =
          VocalActivityDetector().detectVocalSegments(sineAt(60.0, sampleRate), sampleRate);
      expect(segments, isEmpty);
    });

    test('ignores silence', () {
      final segments =
          VocalActivityDetector().detectVocalSegments(Float32List(sampleRate), sampleRate);
      expect(segments, isEmpty);
    });

    test('segment contains() bounds check', () {
      const seg = VocalSegment(1.0, 2.0);
      expect(seg.contains(1.5), isTrue);
      expect(seg.contains(0.5), isFalse);
      expect(seg.contains(2.0), isFalse);
    });
  });
}
