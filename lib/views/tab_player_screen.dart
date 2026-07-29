import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/tab_player_state.dart';
import '../state/tuner_state.dart';

class TabPlayerScreen extends ConsumerStatefulWidget {
  const TabPlayerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TabPlayerScreen> createState() => _TabPlayerScreenState();
}

class _TabPlayerScreenState extends ConsumerState<TabPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _playheadController;
  double _lastBpm = 0.0;
  int _lastTotalMeasures = 0;

  @override
  void initState() {
    super.initState();
    _playheadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _playheadController.addListener(() {
      if (mounted) {
        final tabState = ref.read(tabPlayerProvider);
        if (tabState.isPlaying) {
          final double totalBeats = tabState.totalMeasures * 4.0;
          final double newPos = _playheadController.value * totalBeats;
          ref.read(tabPlayerProvider.notifier).seekTo(newPos);
        }
      }
    });
  }

  void _updatePlayheadDuration(double bpm, int totalMeasures) {
    if (bpm != _lastBpm || totalMeasures != _lastTotalMeasures) {
      _lastBpm = bpm;
      _lastTotalMeasures = totalMeasures;
      final double totalBeats = totalMeasures * 4.0;
      final double durationSeconds = (totalBeats / (bpm / 60.0));
      _playheadController.duration =
          Duration(milliseconds: (durationSeconds * 1000).round());
    }
  }

  @override
  void dispose() {
    _playheadController.dispose();
    super.dispose();
  }

  static const Color _bgDark = Color(0xFF0A0E17);
  static const Color _surfaceDark = Color(0xFF141925);
  static const Color _accentCyan = Color(0xFF38BDF8);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentRed = Color(0xFFEF4444);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textPrimary = Color(0xFFE2E8F0);
  static const Color _borderSubtle = Color(0xFF1E293B);
  static const Color _parchment = Color(0xFFFAF8F0);

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(tabPlayerProvider.select((s) => s.isPlaying));
    final isLooping = ref.watch(tabPlayerProvider.select((s) => s.isLooping));
    final isLiveMicMode =
        ref.watch(tabPlayerProvider.select((s) => s.isLiveMicMode));
    final currentBpm =
        ref.watch(tabPlayerProvider.select((s) => s.currentBpm));
    final isRecording =
        ref.watch(tabPlayerProvider.select((s) => s.isRecording));
    final recordingDurationSeconds =
        ref.watch(tabPlayerProvider.select((s) => s.recordingDurationSeconds));
    final waveformLevels =
        ref.watch(tabPlayerProvider.select((s) => s.waveformLevels));
    final totalMeasures =
        ref.watch(tabPlayerProvider.select((s) => s.totalMeasures));
    final selectedDuration =
        ref.watch(tabPlayerProvider.select((s) => s.selectedDuration));
    final tapTempoHistory =
        ref.watch(tabPlayerProvider.select((s) => s.tapTempoHistory));

    _updatePlayheadDuration(currentBpm, totalMeasures);

    if (isPlaying && !_playheadController.isAnimating) {
      _playheadController.repeat();
    } else if (!isPlaying && _playheadController.isAnimating) {
      _playheadController.stop();
    }

    ref.listen<TunerAppState>(tunerStateProvider, (previous, next) {
      if (isLiveMicMode || isRecording) {
        if (next.status.detectedFrequency != null &&
            next.status.detectedFrequency! > 0) {
          ref
              .read(tabPlayerProvider.notifier)
              .recordTranscribedPitch(next.status.detectedFrequency!);
        }
        ref
            .read(tabPlayerProvider.notifier)
            .pushWaveformLevel(next.status.volumeLevel);
      }
    });

    ref.listen<bool>(
        tabPlayerProvider.select((s) => s.isLiveMicMode || s.isRecording),
        (previous, isMicNeeded) {
      if (isMicNeeded && previous != isMicNeeded) {
        ref.read(tunerStateProvider.notifier).startTuning();
      }
    });

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: _buildAppBar(isLooping, isLiveMicMode),
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(
              isPlaying: isPlaying,
              isRecording: isRecording,
              isLiveMicMode: isLiveMicMode,
              currentBpm: currentBpm,
              selectedDuration: selectedDuration,
              tapTempoHistory: tapTempoHistory,
            ),
            if (isRecording)
              _buildRecordingBanner(recordingDurationSeconds, waveformLevels),
            Expanded(
              child: _buildScoreCanvas(),
            ),
            _buildFretboardSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLooping, bool isLiveMicMode) {
    return AppBar(
      backgroundColor: _surfaceDark,
      elevation: 0,
      titleSpacing: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _textMuted),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'TAB WORKSPACE',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: _textPrimary,
        ),
      ),
      actions: [
        _appBarAction(
          icon: Icons.save_alt,
          tooltip: 'Save',
          onTap: () async {
            await ref.read(tabPlayerProvider.notifier).saveSessionToDevice();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session saved'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        _appBarAction(
          icon: Icons.folder_open,
          tooltip: 'Load',
          onTap: () async {
            final loaded =
                await ref.read(tabPlayerProvider.notifier).loadSessionFromDevice();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(loaded ? 'Session loaded' : 'No saved session'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        _appBarAction(
          icon: isLooping ? Icons.repeat : Icons.repeat_one,
          color: isLooping ? _accentGreen : _textMuted,
          tooltip: isLooping ? 'Looping ON' : 'Looping OFF',
          onTap: () => ref.read(tabPlayerProvider.notifier).toggleLoop(),
        ),
        _appBarAction(
          icon: Icons.delete_outline,
          color: _accentRed,
          tooltip: 'Clear tab',
          onTap: () => _confirmClearTab(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _appBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = _textMuted,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      onPressed: onTap,
    );
  }

  void _confirmClearTab() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceDark,
        title: Text('Clear Tab?',
            style: TextStyle(color: _textPrimary)),
        content: const Text('This will delete all notes.',
            style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tabPlayerProvider.notifier).clearTab();
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: TextStyle(color: _accentRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar({
    required bool isPlaying,
    required bool isRecording,
    required bool isLiveMicMode,
    required double currentBpm,
    required NoteDuration selectedDuration,
    required List<double> tapTempoHistory,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceDark,
        border: Border(bottom: BorderSide(color: _borderSubtle)),
      ),
      child: Row(
        children: [
          // Mode toggle
          _modePill(isLiveMicMode: isLiveMicMode),
          const Spacer(),
          // BPM section
          _bpmControl(currentBpm),
          const SizedBox(width: 12),
          // Duration selector
          _durationChip(selectedDuration),
          const SizedBox(width: 12),
          // Transport buttons
          _transportButtons(isPlaying: isPlaying, isRecording: isRecording),
        ],
      ),
    );
  }

  Widget _modePill({required bool isLiveMicMode}) {
    return GestureDetector(
      onTap: () => ref.read(tabPlayerProvider.notifier).toggleLiveMicMode(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isLiveMicMode
              ? _accentRed.withValues(alpha: 0.15)
              : _accentCyan.withValues(alpha: 0.12),
          border: Border.all(
            color: isLiveMicMode ? _accentRed : _accentCyan,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiveMicMode ? Icons.mic : Icons.graphic_eq,
              color: isLiveMicMode ? _accentRed : _accentCyan,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              isLiveMicMode ? 'LIVE' : 'PLAY',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isLiveMicMode ? _accentRed : _accentCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bpmControl(double currentBpm) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BPM down
        _smallIconButton(
          icon: Icons.remove,
          onTap: () {
            ref
                .read(tabPlayerProvider.notifier)
                .setBpm((currentBpm - 1).clamp(40, 280));
          },
        ),
        // Tap tempo area
        GestureDetector(
          onTap: () => ref.read(tabPlayerProvider.notifier).registerTapTempo(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentBpm.round()}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _accentCyan,
                    height: 1.0,
                  ),
                ),
                Text(
                  'BPM',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        // BPM up
        _smallIconButton(
          icon: Icons.add,
          onTap: () {
            ref
                .read(tabPlayerProvider.notifier)
                .setBpm((currentBpm + 1).clamp(40, 280));
          },
        ),
      ],
    );
  }

  Widget _smallIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderSubtle),
        ),
        child: Icon(icon, size: 14, color: _textMuted),
      ),
    );
  }

  Widget _durationChip(NoteDuration duration) {
    return GestureDetector(
      onTap: () => ref.read(tabPlayerProvider.notifier).cycleSelectedDuration(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderSubtle),
          color: _accentCyan.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, size: 14, color: _accentCyan),
            const SizedBox(width: 4),
            Text(
              '1/${duration.label}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _accentCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transportButtons({
    required bool isPlaying,
    required bool isRecording,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Record
        _transportButton(
          onTap: () => ref.read(tabPlayerProvider.notifier).toggleRecording(),
          isActive: isRecording,
          activeColor: _accentRed,
          icon: isRecording
              ? Icons.fiber_manual_record
              : Icons.fiber_manual_record_outlined,
          size: 36,
        ),
        const SizedBox(width: 6),
        // Play/Pause
        _transportButton(
          onTap: () => ref.read(tabPlayerProvider.notifier).togglePlayPause(),
          isActive: isPlaying,
          activeColor: _accentGreen,
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          size: 36,
        ),
        const SizedBox(width: 6),
        // Stop
        _transportButton(
          onTap: () {
            if (isRecording) {
              ref.read(tabPlayerProvider.notifier).toggleRecording();
            } else if (isPlaying) {
              ref.read(tabPlayerProvider.notifier).togglePlayPause();
            }
            _playheadController.reset();
            ref.read(tabPlayerProvider.notifier).seekTo(0.0);
          },
          isActive: false,
          activeColor: _textMuted,
          icon: Icons.stop,
          size: 34,
        ),
      ],
    );
  }

  Widget _transportButton({
    required VoidCallback onTap,
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required double size,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? activeColor : _bgDark,
          border: Border.all(
            color: isActive ? activeColor : _borderSubtle,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : activeColor.withValues(alpha: 0.6),
          size: size * 0.55,
        ),
      ),
    );
  }

  Widget _buildRecordingBanner(
      double recordingDurationSeconds, List<double> waveformLevels) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _pulsingDot(),
          const SizedBox(width: 8),
          Text(
            'Recording  ${recordingDurationSeconds.toStringAsFixed(1)}s',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _accentRed,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(12, (i) {
              final level = waveformLevels.length > i ? waveformLevels[i] : 0.1;
              final barH = (level * 18).clamp(3.0, 18.0);
              return Container(
                width: 2.5,
                height: barH,
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
                decoration: BoxDecoration(
                  color: _accentRed.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _pulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accentRed.withValues(alpha: value),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildScoreCanvas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          color: _parchment,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD6D3CC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Consumer(
            builder: (context, ref, child) {
              final measures =
                  ref.watch(tabPlayerProvider.select((s) => s.measures));
              final playheadPosition =
                  ref.watch(tabPlayerProvider.select((s) => s.playheadPosition));
              return GestureDetector(
                onTapUp: (details) {
                  _handleScoreTap(details.localPosition, measures,
                      context.size ?? Size.zero);
                },
                child: CustomPaint(
                  painter: TabNotationPainter(
                    measures: measures,
                    playheadPosition: playheadPosition,
                    showSelectionHint: false,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleScoreTap(
      Offset tapPos, List<TabMeasure> measures, Size canvasSize) {
    if (measures.isEmpty) return;

    const double startX = 50.0;
    final double availableWidth = canvasSize.width - startX;
    final int measureCount = measures.length;
    final double measureWidth = availableWidth / measureCount;
    const double tabTopY = 105.0;
    const double tabSpacing = 13.0;

    // Determine which measure and beat
    final double tapX = tapPos.dx;
    final double beatPos = ((tapX - startX) / measureWidth) * 4.0;
    final double quantizedBeat = (beatPos * 4.0).round() / 4.0;
    if (quantizedBeat < 0 || quantizedBeat >= measureCount * 4.0) return;

    // Determine which string was tapped
    final double relY = tapPos.dy - tabTopY;
    final int stringIndex = ((relY / tabSpacing).round()).clamp(1, 6);

    // Determine fret from tap position relative to staff
    final String? fretInput = _inferFretFromTap(tapPos, canvasSize);
    final int fret = fretInput != null ? int.tryParse(fretInput) ?? 0 : 0;

    ref
        .read(tabPlayerProvider.notifier)
        .addNoteManually(stringIndex, fret, quantizedBeat);
  }

  String? _inferFretFromTap(Offset tapPos, Size canvasSize) {
    // Return a default fret of 0 for open string notes
    return '0';
  }

  Widget _buildFretboardSection() {
    return Container(
      height: 130,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'FRETBOARD',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: _textMuted,
                ),
              ),
              const Spacer(),
              _fretNumberHint(),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final measures =
                    ref.watch(tabPlayerProvider.select((s) => s.measures));
                final playheadPosition =
                    ref.watch(tabPlayerProvider.select((s) => s.playheadPosition));
                return GestureDetector(
                  onTapUp: (details) {
                    _handleFretboardTap(
                        details.localPosition,
                        context.size ?? Size.zero);
                  },
                  child: CustomPaint(
                    painter: FretboardPainter(
                      playheadPosition: playheadPosition,
                      measures: measures,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _fretNumberHint() {
    return Text(
      'TAP TO ADD NOTE',
      style: GoogleFonts.outfit(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: _textMuted.withValues(alpha: 0.5),
        letterSpacing: 1.0,
      ),
    );
  }

  void _handleFretboardTap(Offset tapPos, Size canvasSize) {
    const int totalFrets = 15;
    final double availableWidth = canvasSize.width - 30;
    final double stringSpacing = canvasSize.height / 7;

    final List<double> fretPositions = [30.0];
    for (int f = 1; f <= totalFrets; f++) {
      final double fretRatio = (1.0 - (1.0 / math.pow(2, f / 12)));
      final double x = 30.0 + (availableWidth * (fretRatio / 0.58));
      fretPositions.add(x);
    }

    // Determine fret from X position
    int tappedFret = 0;
    for (int f = totalFrets; f >= 0; f--) {
      if (tapPos.dx >= fretPositions[f]) {
        tappedFret = f;
        break;
      }
    }

    // Determine string from Y position
    final int stringIndex =
        (tapPos.dy / stringSpacing).round().clamp(1, 6);

    // Add note at current playhead position
    final playheadPos = ref.read(tabPlayerProvider).playheadPosition;
    final double quantizedBeat = (playheadPos * 4.0).round() / 4.0;

    ref
        .read(tabPlayerProvider.notifier)
        .addNoteManually(stringIndex, tappedFret, quantizedBeat);
  }
}

/// Renders dual standard notation + guitar tablature with proper engraving
class TabNotationPainter extends CustomPainter {
  final List<TabMeasure> measures;
  final double playheadPosition;
  final bool showSelectionHint;

  TabNotationPainter({
    required this.measures,
    required this.playheadPosition,
    this.showSelectionHint = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (measures.isEmpty) return;

    const double startX = 50.0;
    final double availableWidth = size.width - startX;
    final int measureCount = measures.length;
    final double measureWidth = availableWidth / measureCount;
    const double notationTopY = 22.0;
    const double notationSpacing = 9.0;
    const double tabTopY = 88.0;
    const double tabSpacing = 12.5;
    const double beatTickHeight = 4.0;

    // Draw staff lines
    final staffLinePaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 5; i++) {
      final y = notationTopY + (i * notationSpacing);
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), staffLinePaint);
    }

    final tabLinePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 0.8;

    const stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];
    final stringLabelStyle = TextStyle(
      color: const Color(0xFF1E293B),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < 6; i++) {
      final y = tabTopY + (i * tabSpacing);
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), tabLinePaint);
      final span = TextSpan(text: stringNames[i], style: stringLabelStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(26, y - 6));
    }

    // TAB logo
    final tabLogo = TextPainter(
      text: const TextSpan(
        text: 'T\nA\nB',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 0.9,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tabLogo.layout();
    tabLogo.paint(canvas, Offset(37, tabTopY + 14));

    // Bracket line
    canvas.drawLine(
      Offset(startX, notationTopY),
      Offset(startX, tabTopY + (5 * tabSpacing)),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 2.5,
    );

    // Measure barlines
    final barlinePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.5;
    final barNumberStyle = TextStyle(
      color: const Color(0xFF3B82F6),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    for (int m = 0; m <= measureCount; m++) {
      final x = startX + (m * measureWidth);
      canvas.drawLine(
        Offset(x, notationTopY),
        Offset(x, tabTopY + (5 * tabSpacing)),
        barlinePaint,
      );
      if (m < measureCount) {
        final span = TextSpan(text: '${m + 1}', style: barNumberStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x + 5, notationTopY - 16));
      }
    }

    // Beat subdivision ticks
    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 0.5;
    for (int m = 0; m < measureCount; m++) {
      for (int beat = 1; beat < 4; beat++) {
        final tx = startX + (m * measureWidth) + (beat * measureWidth / 4);
        canvas.drawLine(
          Offset(tx, tabTopY),
          Offset(tx, tabTopY + (5 * tabSpacing) - beatTickHeight),
          tickPaint,
        );
      }
    }

    // Draw notes
    _drawNotes(canvas, startX, measureWidth, notationTopY,
        notationSpacing, tabTopY, tabSpacing);

    // Playhead
    final double playheadX =
        startX + (playheadPosition * (measureWidth / 4));
    final playheadPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(playheadX, notationTopY - 8),
      Offset(playheadX, tabTopY + (5 * tabSpacing) + 8),
      playheadPaint,
    );

    final arrowPath = Path()
      ..moveTo(playheadX - 5, notationTopY - 13)
      ..lineTo(playheadX + 5, notationTopY - 13)
      ..lineTo(playheadX, notationTopY - 8)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFFEF4444));
  }

  void _drawNotes(Canvas canvas, double startX, double measureWidth,
      double notationTopY, double notationSpacing,
      double tabTopY, double tabSpacing) {
    final fretStyle = TextStyle(
      color: const Color(0xFF1E293B),
      fontSize: 12,
      fontWeight: FontWeight.w900,
    );

    for (var measure in measures) {
      for (var note in measure.notes) {
        final double noteX =
            startX + (note.position * (measureWidth / 4.0));
        final double tabY = tabTopY + ((note.stringIndex - 1) * tabSpacing);

        // White background behind fret number
        canvas.drawRect(
          Rect.fromCenter(center: Offset(noteX, tabY), width: 16, height: 11),
          Paint()..color = const Color(0xFFFAF8F0),
        );

        final fretSpan =
            TextSpan(text: '${note.fret}', style: fretStyle);
        final fretPainter =
            TextPainter(text: fretSpan, textDirection: TextDirection.ltr);
        fretPainter.layout();
        fretPainter.paint(canvas, Offset(noteX - 5, tabY - 7));

        // Standard notation head with duration-based engraving
        final double notationY =
            notationTopY + (note.stringIndex * 3.2);
        final headPaint = Paint()
          ..color = const Color(0xFF1E293B)
          ..style = PaintingStyle.fill;

        switch (note.duration) {
          case NoteDuration.whole:
          case NoteDuration.half:
            // Open note head (ellipse)
            canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(noteX, notationY),
                  width: 7,
                  height: 5.5),
              Paint()
                ..color = const Color(0xFFFAF8F0)
                ..style = PaintingStyle.fill,
            );
            canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(noteX, notationY),
                  width: 7,
                  height: 5.5),
              Paint()
                ..color = const Color(0xFF1E293B)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2,
            );
            if (note.duration != NoteDuration.whole) {
              canvas.drawLine(
                Offset(noteX + 3.5, notationY),
                Offset(noteX + 3.5, notationY - 16),
                Paint()
                  ..color = const Color(0xFF1E293B)
                  ..strokeWidth = 1.2,
              );
            }
            break;
          case NoteDuration.quarter:
            canvas.drawCircle(Offset(noteX, notationY), 4, headPaint);
            canvas.drawLine(
              Offset(noteX + 3.5, notationY),
              Offset(noteX + 3.5, notationY - 16),
              Paint()
                ..color = const Color(0xFF1E293B)
                ..strokeWidth = 1.2,
            );
            break;
          case NoteDuration.eighth:
          case NoteDuration.sixteenth:
            canvas.drawCircle(Offset(noteX, notationY), 4, headPaint);
            canvas.drawLine(
              Offset(noteX + 3.5, notationY),
              Offset(noteX + 3.5, notationY - 16),
              Paint()
                ..color = const Color(0xFF1E293B)
                ..strokeWidth = 1.2,
            );
            // Flag
            final flagPath = Path()
              ..moveTo(noteX + 3.5, notationY - 16)
              ..quadraticBezierTo(noteX + 10, notationY - 12,
                  noteX + 10, notationY - 6);
            canvas.drawPath(
              flagPath,
              Paint()
                ..color = const Color(0xFF1E293B)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0,
            );
            if (note.duration == NoteDuration.sixteenth) {
              final flag2 = Path()
                ..moveTo(noteX + 3.5, notationY - 12)
                ..quadraticBezierTo(noteX + 10, notationY - 8,
                    noteX + 10, notationY - 3);
              canvas.drawPath(
                flag2,
                Paint()
                  ..color = const Color(0xFF1E293B)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.0,
              );
            }
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TabNotationPainter oldDelegate) {
    return oldDelegate.playheadPosition != playheadPosition ||
        oldDelegate.measures != measures;
  }
}

/// Renders fretboard with string/fret labels and tap hint
class FretboardPainter extends CustomPainter {
  final double playheadPosition;
  final List<TabMeasure> measures;

  FretboardPainter({
    required this.playheadPosition,
    required this.measures,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rosewood neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D1F14), Color(0xFF1A100A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    const int totalFrets = 15;
    final double availableWidth = size.width - 30;
    final double stringSpacing = size.height / 7;

    // Bone nut
    canvas.drawLine(
      const Offset(30, 0),
      Offset(30, size.height),
      Paint()
        ..color = const Color(0xFFF8FAFC)
        ..strokeWidth = 5.0,
    );

    // Fret positions
    final List<double> fretPositions = [30.0];
    for (int f = 1; f <= totalFrets; f++) {
      final double fretRatio = (1.0 - (1.0 / math.pow(2, f / 12)));
      final double x =
          30.0 + (availableWidth * (fretRatio / 0.58));
      fretPositions.add(x);
    }

    // Fret wires
    final fretWirePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.5;
    for (int f = 1; f <= totalFrets; f++) {
      canvas.drawLine(
        Offset(fretPositions[f], 0),
        Offset(fretPositions[f], size.height),
        fretWirePaint,
      );
    }

    // Fret markers
    final markerPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.3);
    final double midY = size.height / 2;

    for (int fretNum in [3, 5, 7, 9, 15]) {
      final double sx = fretPositions[fretNum - 1];
      final double ex = fretPositions[fretNum];
      canvas.drawCircle(Offset((sx + ex) / 2, midY), 3.5, markerPaint);
    }
    // Double dot at 12
    if (totalFrets >= 12) {
      final double sx = fretPositions[11];
      final double ex = fretPositions[12];
      final double dx = (sx + ex) / 2;
      canvas.drawCircle(Offset(dx, midY - 10), 3.0, markerPaint);
      canvas.drawCircle(Offset(dx, midY + 10), 3.0, markerPaint);
    }

    // Strings
    for (int s = 1; s <= 6; s++) {
      final y = s * stringSpacing;
      final gauge = 1.0 + ((6 - s) * 0.35);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = gauge,
      );
    }

    // String labels on the nut area
    const stringLabels = ['e', 'B', 'G', 'D', 'A', 'E'];
    for (int s = 1; s <= 6; s++) {
      final labelSpan = TextSpan(
        text: stringLabels[s - 1],
        style: TextStyle(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.7),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(4, s * stringSpacing - 5));
    }

    // Fret number labels
    for (int f in [1, 3, 5, 7, 9, 12, 15]) {
      final prevX = fretPositions[f - 1];
      final currX = fretPositions[f];
      final labelSpan = TextSpan(
        text: '$f',
        style: TextStyle(
          color: const Color(0xFF64748B).withValues(alpha: 0.5),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      final tp = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas,
          Offset((prevX + currX) / 2 - 3, size.height - 14));
    }

    // Active notes
    final activeNotes = _getActiveNotesAt(playheadPosition);
    for (var note in activeNotes) {
      if (note.fret >= 0 && note.fret <= totalFrets) {
        final double noteY = note.stringIndex * stringSpacing;
        final double noteX = note.fret == 0
            ? 15.0
            : (fretPositions[note.fret - 1] + fretPositions[note.fret]) / 2;

        canvas.drawCircle(
          Offset(noteX, noteY),
          10,
          Paint()
            ..color = const Color(0xFF10B981).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        canvas.drawCircle(
          Offset(noteX, noteY),
          7,
          Paint()..color = const Color(0xFF10B981),
        );

        final textSpan = TextSpan(
          text: '${note.fret}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(noteX - 3, noteY - 5));
      }
    }
  }

  List<TabNote> _getActiveNotesAt(double position) {
    final List<TabNote> active = [];
    for (var measure in measures) {
      for (var note in measure.notes) {
        final endPos = note.position + note.duration.beatValue;
        if (position >= note.position - 0.05 && position < endPos) {
          active.add(note);
        }
      }
    }
    return active;
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return oldDelegate.playheadPosition != playheadPosition ||
        oldDelegate.measures != measures;
  }
}
