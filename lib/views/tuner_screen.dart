import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pitch_engine.dart';
import '../state/tuner_state.dart';

/// Renders a beautiful background grid matching GuitarTuna's interface
class TuningGridBackground extends StatelessWidget {
  final Widget child;

  const TuningGridBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F1524),
            Color(0xFF070B12),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.15)
      ..strokeWidth = 1.0;

    const double gridSpacing = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw central vertical axis indicator
    final axisPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A premium radial/linear dial that uses spring physics for responsive tuning needles
class SpringCenteringMeter extends StatefulWidget {
  final double targetCents; // -50.0 to +50.0
  final bool isPerfect;
  final bool isSearching;

  const SpringCenteringMeter({
    Key? key,
    required this.targetCents,
    required this.isPerfect,
    required this.isSearching,
  }) : super(key: key);

  @override
  State<SpringCenteringMeter> createState() => _SpringCenteringMeterState();
}

class _SpringCenteringMeterState extends State<SpringCenteringMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentCents = 0.0;

  @override
  void initState() {
    super.initState();
    // Allow unbounded values for spring physics simulation
    _controller = AnimationController.unbounded(vsync: this);
    _controller.addListener(() {
      setState(() {
        _currentCents = _controller.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant SpringCenteringMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSearching) {
      // Return to center slowly
      _animateToTarget(0.0, stiffness: 40.0, damping: 8.0);
    } else if (oldWidget.targetCents != widget.targetCents) {
      _animateToTarget(widget.targetCents);
    }
  }

  void _animateToTarget(double target, {double stiffness = 160.0, double damping = 15.0}) {
    final spring = SpringDescription(
      mass: 0.8,
      stiffness: stiffness,
      damping: damping,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value, // current offset
      target,            // target offset
      0.0,               // initial velocity
    );
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double normalizedCents = _currentCents.clamp(-50.0, 50.0);
    
    // Choose neon accent color based on status
    Color accentColor;
    if (widget.isSearching) {
      accentColor = const Color(0xFF475569); // Neutral slate gray
    } else if (widget.isPerfect) {
      accentColor = const Color(0xFF10B981); // Bright green
    } else if (normalizedCents < 0) {
      accentColor = const Color(0xFFEF4444); // Red for flat
    } else {
      accentColor = const Color(0xFFF59E0B); // Orange/Amber for sharp
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: widget.isPerfect && !widget.isSearching
            ? const Color(0xFF10B981).withOpacity(0.06) // soft green flash background
            : Colors.transparent,
      ),
      child: CustomPaint(
        painter: MeterPainter(
          cents: normalizedCents,
          isSearching: widget.isSearching,
          isPerfect: widget.isPerfect,
          themeColor: accentColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 25),
              // Big visual read-out circle
              AnimatedContainer(
                duration: const duration200ms(),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSearching ? const Color(0xFF475569) : accentColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isSearching ? Colors.transparent : accentColor).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isSearching
                      ? const Icon(Icons.mic, color: Color(0xFF64748B), size: 32)
                      : Text(
                          widget.isPerfect
                              ? 'OK'
                              : '${normalizedCents.toStringAsFixed(0)}c',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: widget.isSearching ? const Color(0xFF64748B) : accentColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper duration
class duration200ms extends Duration {
  const duration200ms() : super(milliseconds: 200);
}

class MeterPainter extends CustomPainter {
  final double cents; // -50 to +50
  final bool isSearching;
  final bool isPerfect;
  final Color themeColor;

  MeterPainter({
    required this.cents,
    required this.isSearching,
    required this.isPerfect,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height - 20;

    // Draw central base arc
    final arcPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    final rect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: 120,
    );
    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint);

    // Draw ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 2.0;

    // 11 ticks from -50 to +50
    for (int i = 0; i <= 10; i++) {
      final double angle = math.pi + (i * math.pi / 10);
      final double startRadius = i == 5 ? 128.0 : 124.0;
      final double endRadius = 112.0;

      // Color the active cents region ticks
      if (!isSearching) {
        final double tickCents = (i - 5) * 10.0;
        final bool isTickActive = (cents < 0 && tickCents >= cents && tickCents <= 0) ||
                                  (cents > 0 && tickCents <= cents && tickCents >= 0);
        
        tickPaint.color = isTickActive ? themeColor : const Color(0xFF475569);
        tickPaint.strokeWidth = isTickActive ? 3.0 : 2.0;
      } else {
        tickPaint.color = const Color(0xFF334155);
        tickPaint.strokeWidth = 1.5;
      }

      final Offset start = Offset(
        centerX + startRadius * math.cos(angle),
        centerY + startRadius * math.sin(angle),
      );
      final Offset end = Offset(
        centerX + endRadius * math.cos(angle),
        centerY + endRadius * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Draw dynamic needle indicator (if not searching)
    if (!isSearching) {
      final double targetAngle = math.pi + math.pi / 2 + (cents * (math.pi / 2) / 50.0);
      
      // Shadow glow for the needle
      final needleShadowPaint = Paint()
        ..color = themeColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(
          centerX + 115 * math.cos(targetAngle),
          centerY + 115 * math.sin(targetAngle),
        ),
        needleShadowPaint,
      );

      final needlePaint = Paint()
        ..color = themeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(
          centerX + 115 * math.cos(targetAngle),
          centerY + 115 * math.sin(targetAngle),
        ),
        needlePaint,
      );

      // Draw center pivot
      final pivotPaint = Paint()..color = themeColor;
      canvas.drawCircle(Offset(centerX, centerY), 6.0, pivotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MeterPainter oldDelegate) {
    return oldDelegate.cents != cents ||
        oldDelegate.isSearching != isSearching ||
        oldDelegate.isPerfect != isPerfect ||
        oldDelegate.themeColor != themeColor;
  }
}

/// Custom headstock design containing interactive glowing peg buttons
class InteractiveHeadstock extends StatelessWidget {
  final GuitarString activeString;
  final bool isPerfect;
  final bool isSearching;
  final Function(GuitarString) onPegTapped;

  const InteractiveHeadstock({
    Key? key,
    required this.activeString,
    required this.isPerfect,
    required this.isSearching,
    required this.onPegTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      width: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Draw carbon/metallic headstock background vector
          Positioned.fill(
            child: CustomPaint(
              painter: HeadstockPainter(),
            ),
          ),
          
          // 2. Map the 6 Pegs to screen layout coordinates
          // Left side pegs (Strings 6, 5, 4 - bottom to top)
          _buildPegButton(
            string: PitchEngine.standardGuitarTuning[5], // E2 (6)
            bottomOffset: 60,
            leftOffset: 12,
            isRightSide: false,
          ),
          _buildPegButton(
            string: PitchEngine.standardGuitarTuning[4], // A2 (5)
            bottomOffset: 160,
            leftOffset: 12,
            isRightSide: false,
          ),
          _buildPegButton(
            string: PitchEngine.standardGuitarTuning[3], // D3 (4)
            bottomOffset: 260,
            leftOffset: 12,
            isRightSide: false,
          ),

          // Right side pegs (Strings 3, 2, 1 - top to bottom)
          _buildPegButton(
            string: PitchEngine.standardGuitarTuning[2], // G3 (3)
            bottomOffset: 260,
            rightOffset: 12,
            isRightSide: true,
          ),
          _buildPegButton(
            string: PitchEngine.standardGuitarTuning[1], // B3 (2)
            bottomOffset: 160,
            rightOffset: 12,
            isRightSide: true,
          ),
          _buildPegButton(
            string: PitchEngine.standardGuitarTuning[0], // E4 (1)
            bottomOffset: 60,
            rightOffset: 12,
            isRightSide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPegButton({
    required GuitarString string,
    double? leftOffset,
    double? rightOffset,
    required double bottomOffset,
    required bool isRightSide,
  }) {
    final bool isActive = activeString.index == string.index;
    
    Color glowColor = const Color(0xFFF59E0B); // Active bright orange/yellow (GuitarTuna color)
    if (isActive) {
      if (isPerfect && !isSearching) {
        glowColor = const Color(0xFF10B981); // Bright green
      }
    } else {
      glowColor = Colors.transparent;
    }

    return Positioned(
      bottom: bottomOffset,
      left: leftOffset,
      right: rightOffset,
      child: GestureDetector(
        onTap: () => onPegTapped(string),
        child: AnimatedContainer(
          duration: const duration200ms(),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFF1E293B).withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? glowColor : const Color(0xFF475569),
              width: isActive ? 2.5 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  string.noteName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? glowColor : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  '${string.index}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isActive ? glowColor.withOpacity(0.7) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeadstockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rectPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF27272A), Color(0xFF18181B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final borderPaint = Paint()
      ..color = const Color(0xFF3F3F46)
      ..strokeWidth = 2.0;

    final path = Path();
    
    // Draw stylish symmetrical acoustic guitar headstock
    // Bottom neck connector width
    const double neckWidth = 60.0;
    final double leftBase = (size.width - neckWidth) / 2;
    final double rightBase = (size.width + neckWidth) / 2;

    path.moveTo(leftBase, size.height);
    // Left flare out
    path.quadraticBezierTo(25, size.height * 0.8, 30, size.height * 0.5);
    // Left peg bay
    path.quadraticBezierTo(20, size.height * 0.25, 45, 10);
    // Tip profile crown
    path.quadraticBezierTo(size.width / 2, -10, size.width - 45, 10);
    // Right peg bay
    path.quadraticBezierTo(size.width - 20, size.height * 0.25, size.width - 30, size.height * 0.5);
    // Right flare out
    path.quadraticBezierTo(size.width - 25, size.height * 0.8, rightBase, size.height);

    path.close();

    // Draw the main wooden body shadow
    canvas.drawShadow(path, Colors.black, 12, true);

    // Draw body fill
    canvas.drawPath(path, rectPaint);

    // Draw thin elegant silver edge highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF52525B).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw vertical strings going down the center
    final stringPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..strokeWidth = 1.5;

    // Draw decorative gold tuners core layout circles
    final tunerMetalPaint = Paint()
      ..color = const Color(0xFFCA8A04) // Brass/Gold pegs
      ..style = PaintingStyle.fill;

    // Left peg post holes
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.82), 5, tunerMetalPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.58), 5, tunerMetalPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.32), 5, tunerMetalPaint);

    // Right peg post holes
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.82), 5, tunerMetalPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.58), 5, tunerMetalPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.32), 5, tunerMetalPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The main tuner page coordinating all elements
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Proactively start recording on page mount
    Future.microtask(() {
      ref.read(tunerStateProvider.notifier).startTuning();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Respect device resources: stop tracking when backgrounded
    if (state == AppLifecycleState.paused) {
      ref.read(tunerStateProvider.notifier).stopTuning();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(tunerStateProvider.notifier).startTuning();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tunerStateProvider);
    final isSearching = state.status.detectedFrequency == null;
    
    // Choose status label color
    Color statusColor = const Color(0xFF64748B);
    if (!isSearching) {
      if (state.status.isPerfect) {
        statusColor = const Color(0xFF10B981);
      } else if (state.status.centsOffset < 0) {
        statusColor = const Color(0xFFEF4444); // Red for Flat
      } else {
        statusColor = const Color(0xFFF59E0B); // Orange/Amber for Sharp
      }
    }

    return Scaffold(
      body: TuningGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Settings, Brand, and Auto Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF94A3B8)),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      'TUNER',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    
                    // Auto-manual toggle pill
                    GestureDetector(
                      onTap: () => ref.read(tunerStateProvider.notifier).toggleAutoMode(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: state.isAutoMode 
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : const Color(0xFF475569).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: state.isAutoMode 
                              ? const Color(0xFF10B981)
                              : const Color(0xFF475569),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.isAutoMode ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.isAutoMode ? 'AUTO' : 'MANUAL',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: state.isAutoMode ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Feedback banner for permissions/failures
              if (state.errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    state.errorMessage,
                    style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 15),

              // Spring centering Dial Meter
              SpringCenteringMeter(
                targetCents: state.status.centsOffset,
                isPerfect: state.status.isPerfect,
                isSearching: isSearching,
              ),

              // Subtext detail read-out
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(
                      state.status.message.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isSearching)
                      Text(
                        '${state.status.smoothedFrequency!.toStringAsFixed(1)} Hz  /  Target: ${state.activeString.targetHz.toStringAsFixed(1)} Hz',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Guitar Headstock containing responsive peg nodes
              InteractiveHeadstock(
                activeString: state.activeString,
                isPerfect: state.status.isPerfect,
                isSearching: isSearching,
                onPegTapped: (GuitarString string) {
                  ref.read(tunerStateProvider.notifier).selectString(string);
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
