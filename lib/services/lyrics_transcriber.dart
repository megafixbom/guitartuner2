/// Lyric transcription via the OpenAI Whisper speech-to-text API.
///
/// Sends the unified recording buffer (as a WAV) to the Whisper
/// `transcriptions` endpoint and converts the timestamped words/segments into
/// [LyricLine]s that can be rendered karaoke-style and exported as LRC.
///
/// The API key is user-provided at build time via
/// `--dart-define=USER_WHISPER_API_KEY=...` (see the project README / guide).
///
/// TODO (Future): On-device transcription via TFLite Whisper for offline use.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'pitch_shifter.dart' show buildWavBytes;

/// A single timestamped lyric word.
class LyricWord {
  final String word;
  final double start;
  final double end;

  const LyricWord({
    required this.word,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() =>
      {'word': word, 'start': start, 'end': end};

  factory LyricWord.fromJson(Map<String, dynamic> json) => LyricWord(
        word: json['word'] as String? ?? '',
        start: (json['start'] as num?)?.toDouble() ?? 0.0,
        end: (json['end'] as num?)?.toDouble() ?? 0.0,
      );
}

/// A single timestamped lyric line (usually one sung phrase).
class LyricLine {
  final String text;
  final double start; // seconds
  final double end; // seconds
  final List<LyricWord> words;

  const LyricLine({
    required this.text,
    required this.start,
    required this.end,
    this.words = const [],
  });

  String get lrcTimestamp {
    final mm = (start ~/ 60).toString().padLeft(2, '0');
    final ss = (start % 60).floor().toString().padLeft(2, '0');
    final cc = ((start * 100) % 100).round().toString().padLeft(2, '0');
    return '[$mm:$ss.$cc]';
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'start': start,
        'end': end,
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
        text: json['text'] as String? ?? '',
        start: (json['start'] as num?)?.toDouble() ?? 0.0,
        end: (json['end'] as num?)?.toDouble() ?? 0.0,
        words: ((json['words'] as List?) ?? const [])
            .map((w) => LyricWord.fromJson(w as Map<String, dynamic>))
            .toList(),
      );
}

/// Thrown when the Whisper endpoint returns a non-success status.
class LyricsTranscriptionException implements Exception {
  final int statusCode;
  final String message;

  const LyricsTranscriptionException(this.statusCode, this.message);

  @override
  String toString() => 'Lyrics transcription failed ($statusCode): $message';
}

/// Transcribes recorded audio into timestamped lyrics using Whisper.
class LyricsTranscriber {
  static const String _endpoint =
      'https://api.openai.com/v1/audio/transcriptions';

  final http.Client _client;

  LyricsTranscriber({http.Client? client}) : _client = client ?? http.Client();

  /// Transcribe [samples] (mono float audio) into timestamped lyric lines.
  ///
  /// [apiKey] is the user-provided Whisper API key. If omitted, the
  /// compile-time `USER_WHISPER_API_KEY` dart-define is used.
  Future<List<LyricLine>> transcribeAudio(
    Float32List samples, {
    String? apiKey,
    int sampleRate = 16000,
    String model = 'whisper-1',
  }) async {
    final key = apiKey ?? const String.fromEnvironment('USER_WHISPER_API_KEY');
    if (key.isEmpty) {
      throw const LyricsTranscriptionException(
          0, 'No Whisper API key configured.');
    }

    final wav = buildWavBytes(samples, sampleRate: sampleRate);
    final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
      ..headers['Authorization'] = 'Bearer $key'
      ..fields['model'] = model
      ..fields['response_format'] = 'json'
      ..fields['timestamp_granularities[]'] = 'word'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        wav,
        filename: 'recording.wav',
      ));

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw LyricsTranscriptionException(
          response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return parseWhisperResponse(json);
  }

  /// Convert a Whisper transcription JSON payload into lyric lines.
  static List<LyricLine> parseWhisperResponse(Map<String, dynamic> json) {
    final segments = (json['segments'] as List?) ?? const [];
    if (segments.isNotEmpty) {
      return segments.map((raw) {
        final s = raw as Map<String, dynamic>;
        final words = ((s['words'] as List?) ?? const [])
            .map((w) => LyricWord.fromJson(w as Map<String, dynamic>))
            .toList();
        return LyricLine(
          text: (s['text'] as String? ?? '').trim(),
          start: (s['start'] as num?)?.toDouble() ?? 0.0,
          end: (s['end'] as num?)?.toDouble() ?? 0.0,
          words: words,
        );
      }).toList();
    }

    // Fallback: a single line from the plain text field.
    final text = (json['text'] as String? ?? '').trim();
    if (text.isEmpty) return const [];
    return [LyricLine(text: text, start: 0.0, end: 0.0)];
  }

  /// Serialize lyric lines to the LRC (LyRiCs) subtitle format.
  static String toLrc(List<LyricLine> lines) {
    final buffer = StringBuffer();
    buffer.writeln('[ti:GuitarTuner Recording]');
    buffer.writeln('[ar:Recorded Guitar]');
    buffer.writeln('[by:GuitarTuner]');
    for (final line in lines) {
      final clean = line.text.replaceAll('\n', ' ').trim();
      if (clean.isEmpty) continue;
      buffer.writeln('${line.lrcTimestamp}$clean');
    }
    return buffer.toString();
  }

  static final RegExp _lrcTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:\.(\d{1,3}))?\]');

  /// Parse an LRC string back into lyric lines.
  static List<LyricLine> parseLrc(String lrc) {
    final lines = <LyricLine>[];
    for (final rawLine in lrc.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final matches = _lrcTag.allMatches(line).toList();
      if (matches.isEmpty) continue;

      // Text after the last timestamp tag.
      final lastMatch = matches.last;
      final text = line.substring(lastMatch.end).trim();
      if (text.isEmpty) continue;

      for (final m in matches) {
        final mm = int.parse(m.group(1)!);
        final ss = int.parse(m.group(2)!);
        final cc = m.group(3) != null
            ? int.parse(m.group(3)!.padRight(2, '0').substring(0, 2))
            : 0;
        final start = mm * 60.0 + ss + cc / 100.0;
        lines.add(LyricLine(text: text, start: start, end: start));
      }
    }
    lines.sort((a, b) => a.start.compareTo(b.start));
    return lines;
  }

  /// Align lyric lines so each line's [end] equals the next line's [start]
  /// (or a fixed minimum duration when it is the last line).
  static List<LyricLine> withTightenedEnds(List<LyricLine> lines,
      {double fallbackDuration = 4.0}) {
    if (lines.isEmpty) return lines;
    final sorted = List<LyricLine>.from(lines)..sort((a, b) => a.start.compareTo(b.start));
    final result = <LyricLine>[];
    for (int i = 0; i < sorted.length; i++) {
      final next = i + 1 < sorted.length ? sorted[i + 1] : null;
      final end = next != null && next.start > sorted[i].start
          ? next.start
          : sorted[i].start + fallbackDuration;
      result.add(LyricLine(
        text: sorted[i].text,
        start: sorted[i].start,
        end: end,
        words: sorted[i].words,
      ));
    }
    return result;
  }
}
