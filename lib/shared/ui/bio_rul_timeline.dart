import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The Bio-RUL Timeline
/// A world-class biological chronometer visualization.
class BioRULTimeline extends StatefulWidget {
  final double size;

  const BioRULTimeline({
    super.key,
    this.size = 280,
  });

  @override
  State<BioRULTimeline> createState() => _BioRULTimelineState();
}

class _BioRULTimelineState extends State<BioRULTimeline>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;

  // Temperature simulation
  double _currentTemp = 20.0; // Base temp 20°C

  // Animation phases
  double _pulsePhase = 0.0;
  double _helixRotation = 0.0;
  double _sweepPhase = 0.0;
  double _bgPhase = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick!).inMicroseconds / 1e6; // seconds
    _lastTick = elapsed;

    // Q10 Mathematics: rate changes by 2.0x for every 10°C
    final q10Multiplier = math.pow(2.0, (_currentTemp - 20.0) / 10.0).toDouble();

    setState(() {
      _pulsePhase += dt * 0.5 * q10Multiplier; // Pulse frequency
      _helixRotation += dt * 0.3 * q10Multiplier; // Helix rotation speed
      _sweepPhase += dt * 0.15 * q10Multiplier; // Bio-Hand sweep speed
      _bgPhase += dt * 0.1; // Background drifts slowly (independent of temperature)
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.size;

    // Determine helix color based on temperature
    Color helixColor;
    if (_currentTemp <= 25) {
      helixColor = Color.lerp(const Color(0xFF10B981), const Color(0xFF50C878), (_currentTemp - 0) / 25)!; 
    } else if (_currentTemp <= 35) {
      helixColor = Color.lerp(const Color(0xFF50C878), const Color(0xFFF59E0B), (_currentTemp - 25) / 10)!;
    } else {
      helixColor = Color.lerp(const Color(0xFFF59E0B), const Color(0xFFEF4444), (_currentTemp - 35) / 10)!;
    }

    // Breathing scale via sin wave
    final breatheScale = 1.0 + (math.sin(_pulsePhase * 2 * math.pi) * 0.04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Real-Time Math Output
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Simulated Env: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${_currentTemp.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: helixColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: helixColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q₁₀ = ${math.pow(2.0, (_currentTemp - 20.0) / 10.0).toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: helixColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // The Container Guard
        SizedBox(
          width: s,
          height: s,
          child: Transform.scale(
            scale: breatheScale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Container glow
                Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: helixColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        blurRadius: 40,
                        spreadRadius: 4,
                      )
                    ],
                  ),
                ),

                // Layer 1: AI Nexus (Neural Network Cluster)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BioNexusPainter(
                      bgPhase: _bgPhase,
                      isDark: isDark,
                    ),
                  ),
                ),

                // Layer 3: Chronometer Ring
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChronometerRingPainter(
                      sweepPhase: _sweepPhase,
                      isDark: isDark,
                      handColor: helixColor,
                    ),
                  ),
                ),

                // Layer 2: Bio-Helix (Center)
                SizedBox(
                  width: s * 0.45,
                  height: s * 0.65,
                  child: CustomPaint(
                    painter: _BioHelixPainter(
                      rotation: _helixRotation,
                      helixColor: helixColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Interactive Temp Slider bridging user and simulation
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
              activeTrackColor: helixColor.withValues(alpha: 0.5),
              inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              thumbColor: helixColor,
            ),
            child: Slider(
              value: _currentTemp,
              min: 0.0,
              max: 45.0,
              onChanged: (val) {
                setState(() {
                  _currentTemp = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAINTERS
// ══════════════════════════════════════════════════════════════

/// Layer 1: Abstract Forest-Green Neural Web
class _BioNexusPainter extends CustomPainter {
  final double bgPhase;
  final bool isDark;

  _BioNexusPainter({required this.bgPhase, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    final baseColor = isDark ? const Color(0xFF228B22) : const Color(0xFF0F4C3A); // Forest Green
    final paint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.3 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.5 : 0.4)
      ..style = PaintingStyle.fill;

    // Generate stable but drifting nodes
    final rng = math.Random(101);
    final nodes = <Offset>[];
    for (int i = 0; i < 18; i++) {
        final r = radius * (0.3 + 0.6 * rng.nextDouble());
        final a = (rng.nextDouble() * 2 * math.pi) + (bgPhase * (rng.nextDouble() > 0.5 ? 1 : -1));
        nodes.add(Offset(cx + r * math.cos(a), cy + r * math.sin(a)));
    }

    // Connect nodes that are close to each other
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < radius * 0.7) {
            canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw node dots
    for (final node in nodes) {
      canvas.drawCircle(node, 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BioNexusPainter oldDelegate) => 
      oldDelegate.bgPhase != bgPhase || oldDelegate.isDark != isDark;
}

/// Layer 2: Stylized Double-Helix
class _BioHelixPainter extends CustomPainter {
  final double rotation;
  final Color helixColor;
  final bool isDark;

  _BioHelixPainter({required this.rotation, required this.helixColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;

    final strandWidth = size.width * 0.4;
    const rungs = 8;
    
    final paint1 = Paint()
      ..color = helixColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = helixColor.withValues(alpha: 0.4) // Back strand darker/fainter
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
      
    final rungPaint = Paint()
      ..color = helixColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path1 = Path();
    final path2 = Path();

    // 3D projection logic
    final phaseOffset = rotation * 2 * math.pi;

    for (int i = 0; i <= 40; i++) {
      final t = i / 40.0;
      final y = t * h;
      
      // Strand 1
      final x1 = cx + math.sin((t * math.pi * 2) + phaseOffset) * strandWidth;
      
      // Strand 2
      final x2 = cx + math.sin((t * math.pi * 2) + phaseOffset + math.pi) * strandWidth;

      if (i == 0) {
        path1.moveTo(x1, y);
        path2.moveTo(x2, y);
      } else {
        path1.lineTo(x1, y);
        path2.lineTo(x2, y);
      }
    }

    // Draw back strand first
    canvas.drawPath(path2, paint2);

    // Draw rungs
    for (int i = 0; i <= rungs; i++) {
      final t = i / rungs.toDouble();
      final y = t * h;
      final x1 = cx + math.sin((t * math.pi * 2) + phaseOffset) * strandWidth;
      final x2 = cx + math.sin((t * math.pi * 2) + phaseOffset + math.pi) * strandWidth;
      
      // Determine if rung is "facing" front or back by Z depth
      final z1 = math.cos((t * math.pi * 2) + phaseOffset); 
      // If z1 is positive, strand 1 is in front
      
      canvas.drawLine(Offset(x1, y), Offset(x2, y), rungPaint);
    }

    // Draw front strand
    canvas.drawPath(path1, paint1);
    
    // Core glow
    final glowPaint = Paint()
      ..color = helixColor.withValues(alpha: isDark ? 0.3 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(Rect.fromLTWH(0, h * 0.1, size.width, h * 0.8), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _BioHelixPainter oldDelegate) => 
      oldDelegate.rotation != rotation || 
      oldDelegate.helixColor != helixColor ||
      oldDelegate.isDark != isDark;
}

/// Layer 3: 24 Segment Chronometer Ring
class _ChronometerRingPainter extends CustomPainter {
  final double sweepPhase;
  final bool isDark;
  final Color handColor;

  _ChronometerRingPainter({
    required this.sweepPhase,
    required this.isDark,
    required this.handColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) * 0.95; // slightly inset

    // Deep forest-green in Light Mode, cyber-emerald in Dark Mode
    final baseRingColor = isDark ? const Color(0xFF50C878) /* Cyber Emerald */ : const Color(0xFF0F4C3A) /* Forest Green */;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final handAngle = sweepPhase * 2 * math.pi;

    const segments = 24;
    const sweep = (2 * math.pi) / segments;
    const gap = sweep * 0.3; // 30% gap

    for (int i = 0; i < segments; i++) {
      final startAngle = (i * sweep) - (math.pi / 2); // Start at top
      
      // Check distance to hand to create sweeping glow
      // Normalizing angle difference to [-pi, pi]
      double diff = (startAngle - handAngle) % (2 * math.pi);
      if (diff > math.pi) diff -= 2 * math.pi;
      
      // Glow intensity based on proximity to the sweeping hand
      final distance = diff.abs();
      double intensity = 0.0;
      if (distance < math.pi / 2) {
          intensity = 1.0 - (distance / (math.pi / 2));
      }

      // Base alpha is 0.2 (dim segment), peaks at 1.0 near hand
      final segmentAlpha = 0.15 + (0.85 * intensity);
      
      // If very close, color shifts to the active hand color (e.g. Amber/Red if hot)
      final segmentColor = Color.lerp(
        baseRingColor.withValues(alpha: segmentAlpha), 
        handColor, 
        math.pow(intensity, 3).toDouble(), // sharp peak
      )!;

      ringPaint.color = segmentColor;
      
      // Draw segment with slight stroke widening near hand
      ringPaint.strokeWidth = 2.0 + (3.0 * math.pow(intensity, 2));

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle + (gap / 2),
        sweep - gap,
        false,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChronometerRingPainter oldDelegate) => 
      oldDelegate.sweepPhase != sweepPhase || 
      oldDelegate.isDark != isDark ||
      oldDelegate.handColor != handColor;
}
