import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/tab_player_state.dart';

/// Guitar Pro-style Interactive Tablature Workspace
class TabPlayerScreen extends ConsumerStatefulWidget {
  const TabPlayerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TabPlayerScreen> createState() => _TabPlayerScreenState();
}

class _TabPlayerScreenState extends ConsumerState<TabPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _playheadController;

  @override
  void initState() {
    super.initState();
    _playheadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _playheadController.addListener(() {
      if (mounted) {
        final state = ref.read(tabPlayerProvider);
        if (state.isPlaying) {
          final double newPos = _playheadController.value * 16.0;
          ref.read(tabPlayerProvider.notifier).seekTo(newPos);
        }
      }
    });
  }

  @override
  void dispose() {
    _playheadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabPlayerProvider);

    final double durationSeconds = (16.0 / (tabState.currentBpm / 60.0));
    _playheadController.duration = Duration(milliseconds: (durationSeconds * 1000).round());

    // Sync playhead animation controller state
    if (tabState.isPlaying && !_playheadController.isAnimating) {
      _playheadController.repeat();
    } else if (!tabState.isPlaying && _playheadController.isAnimating) {
      _playheadController.stop();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        title: Text(
          'TAB WORKSPACE',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Color(0xFF38BDF8)),
            tooltip: 'Save Session',
            onPressed: () async {
              await ref.read(tabPlayerProvider.notifier).saveSessionToDevice();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tab Session Saved to Device Storage')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Color(0xFF38BDF8)),
            tooltip: 'Load Session',
            onPressed: () async {
              final loaded = await ref.read(tabPlayerProvider.notifier).loadSessionFromDevice();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loaded ? 'Tab Session Loaded' : 'No Saved Session Found'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              tabState.isLooping ? Icons.repeat : Icons.repeat_one,
              color: tabState.isLooping ? const Color(0xFF10B981) : const Color(0xFF64748B),
            ),
            onPressed: () {
              ref.read(tabPlayerProvider.notifier).toggleLoop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Control Toolbar (Tactile Minimalist Toolbar: Play / Pause / Stop / BPM / Live Mic Toggle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Playback Mode vs Live Mic Mode Toggle Pill
                  InkWell(
                    onTap: () {
                      ref.read(tabPlayerProvider.notifier).toggleLiveMicMode();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tabState.isLiveMicMode
                            ? const Color(0xFFF43F5E).withValues(alpha: 0.2)
                            : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tabState.isLiveMicMode ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tabState.isLiveMicMode ? Icons.mic : Icons.graphic_eq,
                            color: tabState.isLiveMicMode ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tabState.isLiveMicMode ? 'LIVE MIC' : 'PLAYBACK',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: tabState.isLiveMicMode ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // BPM Counter Control
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${tabState.currentBpm.round()} BPM',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),

                  // Transport Controls (Record / Play / Pause / Stop)
                  Row(
                    children: [
                      // Red Record Button
                      InkWell(
                        onTap: () {
                          ref.read(tabPlayerProvider.notifier).toggleRecording();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tabState.isRecording ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFEF4444), width: 2.0),
                            boxShadow: tabState.isRecording
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            tabState.isRecording ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
                            color: tabState.isRecording ? Colors.white : const Color(0xFFEF4444),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Play/Pause Button
                      InkWell(
                        onTap: () {
                          ref.read(tabPlayerProvider.notifier).togglePlayPause();
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tabState.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Stop Button
                      InkWell(
                        onTap: () {
                          if (tabState.isRecording) {
                            ref.read(tabPlayerProvider.notifier).toggleRecording();
                          } else if (tabState.isPlaying) {
                            ref.read(tabPlayerProvider.notifier).togglePlayPause();
                          }
                          _playheadController.reset();
                          ref.read(tabPlayerProvider.notifier).seekTo(0.0);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF475569)),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Recording Timer & Audio Waveform Visualizer Indicator Bar
            if (tabState.isRecording)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Color(0xFFEF4444), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'REC  ${tabState.recordingDurationSeconds.toStringAsFixed(1)}s',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    // Live Waveform Visualizer Bars
                    Row(
                      children: List.generate(16, (i) {
                        final double level = tabState.waveformLevels.length > i
                            ? tabState.waveformLevels[i]
                            : 0.2;
                        final double barHeight = (level * 20.0).clamp(4.0, 20.0);
                        return Container(
                          width: 3,
                          height: barHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

            // 2. Guitar Pro Paper Score Sheet View (Parchment White Sheet Music Canvas)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: TabNotationPainter(
                    measures: tabState.measures,
                    playheadPosition: tabState.playheadPosition,
                  ),
                  child: Container(),
                ),
              ),
            ),

            // 3. Interactive Fretboard Visualizer Section
            Container(
              height: 140,
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FRETBOARD VISUALIZER',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: FretboardPainter(
                        playheadPosition: tabState.playheadPosition,
                        measures: tabState.measures,
                      ),
                      child: Container(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders 6-line Guitar Tablature Notation & Moving Playhead
/// Renders Dual Standard 5-Line Musical Notation & 6-Line Guitar Tablature Staff
/// Renders Authentic Guitar Pro Paper Score Music Sheet (Parchment White Background & Crisp Black Engraving)
class TabNotationPainter extends CustomPainter {
  final List<TabMeasure> measures;
  final double playheadPosition;

  TabNotationPainter({
    required this.measures,
    required this.playheadPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double startX = 50.0;
    final double availableWidth = size.width - startX;
    final double measureWidth = availableWidth / 4;

    // --- Section 1: Standard 5-Line Musical Notation Staff (Black Engraving) ---
    final notationLinePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.2;

    final double notationTopY = 25.0;
    final double notationSpacing = 10.0;

    // Draw Treble Clef Label symbol "🎼" / "Standard Notation"
    final trebleSpan = TextSpan(
      text: '🎼',
      style: const TextStyle(fontSize: 22, color: Color(0xFF0F172A)),
    );
    final treblePainter = TextPainter(text: trebleSpan, textDirection: TextDirection.ltr);
    treblePainter.layout();
    treblePainter.paint(canvas, const Offset(12, 22));

    for (int i = 0; i < 5; i++) {
      final y = notationTopY + (i * notationSpacing);
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), notationLinePaint);
    }

    // --- Section 2: Traditional 6-Line Guitar Tablature Staff ---
    final tabLinePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.2;

    final double tabTopY = notationTopY + (5 * notationSpacing) + 30.0; // Seam divider
    final double tabSpacing = 13.0;

    final stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];
    final stringStyle = const TextStyle(
      color: Color(0xFF0F172A),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < 6; i++) {
      final y = tabTopY + (i * tabSpacing);
      canvas.drawLine(Offset(startX, y), Offset(size.width, y), tabLinePaint);

      final textSpan = TextSpan(text: stringNames[i], style: stringStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(24, y - 7));
    }

    // Draw Guitar Pro TAB Logo Text
    final tabLogoSpan = const TextSpan(
      text: 'T\nA\nB',
      style: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        height: 0.9,
      ),
    );
    final tabLogoPainter = TextPainter(text: tabLogoSpan, textDirection: TextDirection.ltr);
    tabLogoPainter.layout();
    tabLogoPainter.paint(canvas, Offset(35, tabTopY + 12));

    // Draw TAB Vertical Bracket Connecting Line
    final bracketPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(startX, notationTopY), Offset(startX, tabTopY + (5 * tabSpacing)), bracketPaint);

    // --- Section 3: Measure Barlines & Bar Numbers ---
    final barlinePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.8;

    final barNumberStyle = const TextStyle(
      color: Color(0xFF2563EB),
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    for (int m = 0; m <= 4; m++) {
      final x = startX + (m * measureWidth);
      canvas.drawLine(Offset(x, notationTopY), Offset(x, tabTopY + (5 * tabSpacing)), barlinePaint);

      if (m < 4) {
        final barSpan = TextSpan(text: '${m + 1}', style: barNumberStyle);
        final barPainter = TextPainter(text: barSpan, textDirection: TextDirection.ltr);
        barPainter.layout();
        barPainter.paint(canvas, Offset(x + 6, notationTopY - 18));
      }
    }

    // --- Section 4: Notes & Fret Engraving (Crisp Black Paper Sheet Style) ---
    final fretStyle = const TextStyle(
      color: Color(0xFF0F172A),
      fontSize: 14,
      fontWeight: FontWeight.w900,
    );

    final noteHeadPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final noteStemPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.8;

    for (var measure in measures) {
      for (var note in measure.notes) {
        final double noteX = startX + (note.position * (measureWidth / 4)) + 18;
        
        // TAB Fret Position (White background cutout behind fret number)
        final double tabY = tabTopY + ((note.stringIndex - 1) * tabSpacing);
        final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawRect(Rect.fromCenter(center: Offset(noteX, tabY), width: 14, height: 12), bgPaint);

        final fretSpan = TextSpan(text: '${note.fret}', style: fretStyle);
        final fretPainter = TextPainter(text: fretSpan, textDirection: TextDirection.ltr);
        fretPainter.layout();
        fretPainter.paint(canvas, Offset(noteX - 4, tabY - 8));

        // Standard Musical Notation Head & Stem
        final double notationY = notationTopY + (3 * notationSpacing) - (note.stringIndex * 3.5);
        canvas.drawCircle(Offset(noteX, notationY), 4.5, noteHeadPaint);
        canvas.drawLine(Offset(noteX + 4, notationY), Offset(noteX + 4, notationY - 18), noteStemPaint);
      }
    }

    // --- Section 5: Guitar Pro Red Playhead Bar ---
    final double playheadX = startX + (playheadPosition * (measureWidth / 4));
    
    final playheadPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(playheadX, notationTopY - 10), Offset(playheadX, tabTopY + (5 * tabSpacing) + 10), playheadPaint);

    // Playhead Top Arrow Pointer
    final arrowPath = Path()
      ..moveTo(playheadX - 6, notationTopY - 16)
      ..lineTo(playheadX + 6, notationTopY - 16)
      ..lineTo(playheadX, notationTopY - 10)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant TabNotationPainter oldDelegate) {
    return oldDelegate.playheadPosition != playheadPosition ||
        oldDelegate.measures != measures;
  }
}

/// Renders 15-Fret Realistic Guitar Fretboard & Dynamic Glowing Finger Placement Dots
class FretboardPainter extends CustomPainter {
  final double playheadPosition;
  final List<TabMeasure> measures;

  FretboardPainter({
    required this.playheadPosition,
    required this.measures,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Wooden Rosewood Fretboard Background
    final neckPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF271A12), Color(0xFF19100B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
      neckPaint,
    );

    const int totalFrets = 15;
    final double availableWidth = size.width - 30; // 30px for nut

    // 2. Draw Bone Nut (Fret 0 divider)
    final nutPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..strokeWidth = 6.0;
    canvas.drawLine(const Offset(30, 0), Offset(30, size.height), nutPaint);

    // 3. Calculate Proportional Fret X Positions (12-TET scale formula)
    final List<double> fretPositions = [30.0];
    for (int f = 1; f <= totalFrets; f++) {
      final double fretRatio = (1.0 - (1.0 / math.pow(2, f / 12)));
      final double x = 30.0 + (availableWidth * (fretRatio / 0.58)); // Normalized for 15 frets
      fretPositions.add(x);
    }

    // Draw Silver Nickel Fret Wires
    final fretWirePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0;

    for (int f = 1; f <= totalFrets; f++) {
      final x = fretPositions[f];
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fretWirePaint);
    }

    // 4. Draw Inlay Fret Position Dot Markers (3, 5, 7, 9, 12, 15)
    final markerPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final singleDotFrets = [3, 5, 7, 9, 15];
    final double midY = size.height / 2;

    for (int fretNum in singleDotFrets) {
      final double startX = fretPositions[fretNum - 1];
      final double endX = fretPositions[fretNum];
      final double dotX = (startX + endX) / 2;
      canvas.drawCircle(Offset(dotX, midY), 4.5, markerPaint);
    }

    // Double dot marker for 12th Fret
    if (totalFrets >= 12) {
      final double startX = fretPositions[11];
      final double endX = fretPositions[12];
      final double dotX = (startX + endX) / 2;
      canvas.drawCircle(Offset(dotX, midY - 14), 4.0, markerPaint);
      canvas.drawCircle(Offset(dotX, midY + 14), 4.0, markerPaint);
    }

    // 5. Draw 6 Steel Strings with Proportional Thickness (Low E to High E)
    final double stringSpacing = size.height / 7;
    for (int s = 1; s <= 6; s++) {
      final y = s * stringSpacing;
      // Proportional string gauge: Low E (6) is thickest, High E (1) is thinnest
      final double gauge = 1.0 + ((6 - s) * 0.4);

      final stringPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = gauge;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), stringPaint);
    }

    // 6. Find & Render Active Finger Placement Dots dynamically based on playhead position
    final activeNotes = _getActiveNotesAt(playheadPosition);

    for (var note in activeNotes) {
      if (note.fret >= 0 && note.fret <= totalFrets) {
        final double noteY = note.stringIndex * stringSpacing;
        double noteX;

        if (note.fret == 0) {
          noteX = 15.0; // Open string nut position
        } else {
          final double prevFretX = fretPositions[note.fret - 1];
          final double currFretX = fretPositions[note.fret];
          noteX = (prevFretX + currFretX) / 2;
        }

        // Outer LED Specular Glow
        final glowPaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(noteX, noteY), 12, glowPaint);

        // Core Finger Badge Circle
        final badgePaint = Paint()..color = const Color(0xFF10B981);
        canvas.drawCircle(Offset(noteX, noteY), 8, badgePaint);

        // Fret Number Text
        final textSpan = TextSpan(
          text: '${note.fret}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(noteX - 3.5, noteY - 6));
      }
    }
  }

  List<TabNote> _getActiveNotesAt(double position) {
    final List<TabNote> active = [];
    for (var measure in measures) {
      for (var note in measure.notes) {
        if ((position - note.position).abs() < 0.35) {
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
