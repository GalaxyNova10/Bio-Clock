import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Vitality Orb — a multi-layered, 3D holographic animation 
/// representing biological intelligence.
class VitalityOrb extends StatefulWidget {
  final double size;

  const VitalityOrb({
    super.key,
    this.size = 250,
  });

  @override
  State<VitalityOrb> createState() => _VitalityOrbState();
}

class _VitalityOrbState extends State<VitalityOrb>
    with TickerProviderStateMixin {
  late final AnimationController _corePulseCtrl;
  late final AnimationController _ringRotationCtrl;
  late final AnimationController _veinSparkCtrl;
  late final AnimationController _scanLaserCtrl;

  @override
  void initState() {
    super.initState();

    // Core breathing animation (scale 1.0 to 1.1)
    _corePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Continuous ring rotation
    _ringRotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    // Sparks firing along neural veins
    _veinSparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Laser sweep every 3 seconds
    _scanLaserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _corePulseCtrl.dispose();
    _ringRotationCtrl.dispose();
    _veinSparkCtrl.dispose();
    _scanLaserCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow based on theme
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppTheme.emeraldCore.withValues(alpha: 0.15),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFF0F4C3A).withValues(alpha: 0.08), // deep forest-green accent
                        Colors.transparent,
                      ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),

          // Layer 3: Neural Veins
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _veinSparkCtrl,
              builder: (_, __) => CustomPaint(
                painter: _NeuralVeinPainter(
                  sparkProgress: _veinSparkCtrl.value,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // Layer 2: Data Rings
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ringRotationCtrl,
              builder: (_, __) => CustomPaint(
                painter: _DataRingsPainter(
                  rotationProgress: _ringRotationCtrl.value,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // Layer 1: The Bio-Core
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.1).animate(
              CurvedAnimation(parent: _corePulseCtrl, curve: Curves.easeInOut),
            ),
            child: Container(
              width: s * 0.25,
              height: s * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF50C878), // emerald sphere
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF50C878).withValues(alpha: isDark ? 0.6 : 0.4),
                    blurRadius: 20,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),
          ),

          // Laser Sweep & Ghost Trail
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanLaserCtrl,
              builder: (_, __) => CustomPaint(
                painter: _LaserSweepPainter(
                  progress: _scanLaserCtrl.value,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LAYER PAINTERS
// ══════════════════════════════════════════════════════════════

class _DataRingsPainter extends CustomPainter {
  final double rotationProgress;
  final bool isDark;

  _DataRingsPainter({required this.rotationProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final maxRadius = math.min(cx, cy);
    final outerRadius = maxRadius * 0.85;
    final innerRadius = maxRadius * 0.65;

    final baseColor = isDark ? AppTheme.emeraldCore : const Color(0xFF0F4C3A);
    final alphaMultiplier = isDark ? 1.0 : 0.6;

    canvas.save();
    canvas.translate(cx, cy);

    // Inner Ring (Dashed 'radar' texture rotating clockwise)
    canvas.save();
    canvas.rotate(rotationProgress * 2 * math.pi);
    
    final innerPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.4 * alphaMultiplier)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashCount = 36;
    final sweepAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: innerRadius),
          i * sweepAngle,
          sweepAngle * 0.8,
          false,
          innerPaint,
        );
      }
    }
    canvas.restore();

    // Outer Ring (Solid line with gaps rotating counter-clockwise)
    canvas.save();
    canvas.rotate(-rotationProgress * 2 * math.pi * 0.6); // Slower
    
    final outerPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.6 * alphaMultiplier)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final outerSegments = 4;
    final outerSweep = (2 * math.pi) / outerSegments;
    for (int i = 0; i < outerSegments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: outerRadius),
        i * outerSweep,
        outerSweep * 0.85, // 15% gap
        false,
        outerPaint,
      );
    }
    
    // Outer dots
    final dotPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.8 * alphaMultiplier)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < outerSegments; i++) {
      final angle = i * outerSweep + (outerSweep * 0.925);
      canvas.drawCircle(
        Offset(outerRadius * math.cos(angle), outerRadius * math.sin(angle)),
        2.5,
        dotPaint,
      );
    }
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DataRingsPainter oldDelegate) =>
      oldDelegate.rotationProgress != rotationProgress || oldDelegate.isDark != isDark;
}

class _NeuralVeinPainter extends CustomPainter {
  final double sparkProgress;
  final bool isDark;

  _NeuralVeinPainter({required this.sparkProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final baseColor = isDark ? AppTheme.emeraldCore : const Color(0xFF0F4C3A);
    final alphaMultiplier = isDark ? 1.0 : 0.5;

    final veinPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.15 * alphaMultiplier)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final sparkPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.8 * alphaMultiplier)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

    final paths = <Path>[];
    
    // Create 8 radiating organic vein paths
    final rng = math.Random(12345); // Deterministic for stability
    for (int i = 0; i < 8; i++) {
      final baseAngle = (i * math.pi / 4);
      final p = Path();
      p.moveTo(cx, cy);
      
      var currentX = cx;
      var currentY = cy;
      final maxRad = size.width * 0.45;
      
      for (int step = 1; step <= 3; step++) {
        final rad = maxRad * (step / 3.0);
        final angleOffset = (rng.nextDouble() - 0.5) * 0.5;
        final targetX = cx + rad * math.cos(baseAngle + angleOffset);
        final targetY = cy + rad * math.sin(baseAngle + angleOffset);
        
        final cp1X = currentX + (targetX - currentX) * 0.5 + (rng.nextDouble() - 0.5) * 20;
        final cp1Y = currentY + (targetY - currentY) * 0.5 + (rng.nextDouble() - 0.5) * 20;
        
        p.quadraticBezierTo(cp1X, cp1Y, targetX, targetY);
        currentX = targetX;
        currentY = targetY;
      }
      paths.add(p);
    }

    // Draw veins
    for (final p in paths) {
      canvas.drawPath(p, veinPaint);
    }

    // Draw sparks along paths
    // Dash path to simulate a traveling spark
    for (int i = 0; i < paths.length; i++) {
        // Stagger spark progress
        final p = paths[i];
        final offset = (i * 0.125);
        final t = (sparkProgress + offset) % 1.0;
        
        // We need path metrics to extract segment
        final metrics = p.computeMetrics().toList();
        if (metrics.isEmpty) continue;
        
        final metric = metrics.first;
        final sparkLength = metric.length * 0.1;
        final start = metric.length * t;
        final end = math.min(metric.length, start + sparkLength);
        
        final sparkSegment = metric.extractPath(start, end);
        canvas.drawPath(sparkSegment, sparkPaint);
        
        // Handle wrap-around
        if (start + sparkLength > metric.length) {
            final wrapEnd = (start + sparkLength) - metric.length;
            final wrapSegment = metric.extractPath(0, wrapEnd);
            canvas.drawPath(wrapSegment, sparkPaint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralVeinPainter oldDelegate) =>
      oldDelegate.sparkProgress != sparkProgress || oldDelegate.isDark != isDark;
}

class _LaserSweepPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _LaserSweepPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep vertically top to bottom, with slight pause at ends
    // Use sine wave mapping to create sweep
    // progress goes 0 to 1
    final sweepPos = (math.sin((progress * 2 * math.pi) - math.pi / 2) + 1) / 2; // 0 to 1, smooth in out
    
    final y = sweepPos * size.height;
    
    final laserColor = isDark ? const Color(0xFF50C878) : const Color(0xFF0F4C3A);

    // Main laser line
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          laserColor.withValues(alpha: isDark ? 0.8 : 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // Ghost trail (above or below depending on direction)
    // We can just use a simple vertical gradient that spans a bit of height
    // Since sweepPos goes back and forth, let's just create a bidirectional blur
    
    final trailHeight = size.height * 0.15;
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          laserColor.withValues(alpha: isDark ? 0.15 : 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - trailHeight/2, size.width, trailHeight));

    canvas.drawRect(
      Rect.fromLTWH(0, y - trailHeight/2, size.width, trailHeight),
      trailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LaserSweepPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
