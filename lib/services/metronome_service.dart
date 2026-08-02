import 'package:audioplayers/audioplayers.dart';

/// Selectable metronome click timbres.
enum MetronomeSound {
  woodblock,
  beep,
  stick;

  String get label => switch (this) {
        MetronomeSound.woodblock => 'Wood',
        MetronomeSound.beep => 'Beep',
        MetronomeSound.stick => 'Stick',
      };
}

/// Metronome subdivision level (clicks per beat).
enum MetronomeSubdivision {
  quarter(1.0, '1/4'),
  eighth(0.5, '1/8'),
  sixteenth(0.25, '1/16');

  final double beatStep;
  final String label;

  const MetronomeSubdivision(this.beatStep, this.label);
}

enum _ClickRole { downbeat, beat, subdivision }

/// Smart metronome click engine.
///
/// Plays strong/weak/subdivision clicks synchronized to the current tempo and
/// time signature. Beat 1 of each measure gets the strong click (downbeat
/// accent), the remaining beats get the weak click, and off-beat subdivisions
/// (eighths/sixteenths) get a lighter subdivision click.
///
/// Sounds are synthesized WAV assets:
/// - `metronome_{sound}_{role}.wav` where sound = woodblock|beep|stick and
///   role = strong|weak|sub.
///
/// TODO (Future - v2.0.0): Lyric transcription; scale detection reuses the
/// shared audio buffer (see scale_detector.dart).
class MetronomeService {
  final AudioPlayer _downbeatPlayer = AudioPlayer();
  final AudioPlayer _beatPlayer = AudioPlayer();
  final AudioPlayer _subdivisionPlayer = AudioPlayer();

  MetronomeSound _sound = MetronomeSound.woodblock;
  double _volume = 0.8;

  void updateSettings({MetronomeSound? sound, double? volume}) {
    if (sound != null) _sound = sound;
    if (volume != null) _volume = volume.clamp(0.0, 1.0);
  }

  String _assetFor(MetronomeSound sound, _ClickRole role) {
    final family = switch (sound) {
      MetronomeSound.woodblock => 'woodblock',
      MetronomeSound.beep => 'beep',
      MetronomeSound.stick => 'stick',
    };
    final suffix = switch (role) {
      _ClickRole.downbeat => 'strong',
      _ClickRole.beat => 'weak',
      _ClickRole.subdivision => 'sub',
    };
    return 'sounds/metronome_${family}_$suffix.wav';
  }

  _ClickRole _roleFor(double beatInMeasure) {
    final mod = beatInMeasure % 1.0;
    if (mod < 0.001 || (1.0 - mod) < 0.001) {
      if (beatInMeasure.abs() < 0.001) return _ClickRole.downbeat;
      return _ClickRole.beat;
    }
    return _ClickRole.subdivision;
  }

  /// Play a single click at the given position within the measure.
  ///
  /// [beatInMeasure] is the position of the click within the current measure
  /// (0.0 = downbeat). [beatsPerMeasure] is the time signature numerator.
  Future<void> playClick({
    required double beatInMeasure,
    required int beatsPerMeasure,
  }) async {
    final normalized = beatInMeasure % beatsPerMeasure.toDouble();
    final role = _roleFor(normalized);
    final player = switch (role) {
      _ClickRole.downbeat => _downbeatPlayer,
      _ClickRole.beat => _beatPlayer,
      _ClickRole.subdivision => _subdivisionPlayer,
    };
    try {
      await player.setVolume(_volume);
      await player.play(AssetSource(_assetFor(_sound, role)));
    } catch (_) {}
  }

  Future<void> stopAll() async {
    try {
      await _downbeatPlayer.stop();
      await _beatPlayer.stop();
      await _subdivisionPlayer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopAll();
    await _downbeatPlayer.dispose();
    await _beatPlayer.dispose();
    await _subdivisionPlayer.dispose();
  }
}
