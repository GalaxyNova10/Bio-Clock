import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// The Chrono-Seed — Emerald Diamond Hero
///
/// Motion-active + flicker-proof architecture:
///  • Golden ring: full 360° orbital rotation every 4s via RotationTransition
///  • Gem core: breathing scale (1.0→1.05) + glow pulse via ScaleTransition
///  • Petals: staggered opacity breathing via FadeTransition
///  • All wrapped in RepaintBoundary with pre-allocated Paint objects
class ChronoSeed extends StatefulWidget {
  final double size;

  const ChronoSeed({
    super.key,
    this.size = 280,
  });

  @override
  State<ChronoSeed> createState() => _ChronoSeedState();
}

class _ChronoSeedState extends State<ChronoSeed> with TickerProviderStateMixin {
  // Golden Ring: full 360° rotation every 4 seconds
  late final AnimationController _ringRotCtrl;

  // Gem Core: breathing scale 1.0 → 1.05 + glow pulse
  late final AnimationController _gemBreathCtrl;
  late final Animation<double> _gemScale;
  late final Animation<double> _gemGlow;

  // Petals: staggered opacity breathing
  final List<AnimationController> _petalCtrls = [];
  final List<Animation<double>> _petalOpacities = [];

  @override
  void initState() {
    super.initState();

    // ── Ring Rotation (4s full 360° orbit) ──
    _ringRotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // Explicit repeat() — never stops

    // ── Gem Breathing (3s cycle, reverse) ──
    _gemBreathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true); // Explicit repeat(reverse) — never stops

    _gemScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _gemBreathCtrl, curve: Curves.easeInOut),
    );

    _gemGlow = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _gemBreathCtrl, curve: Curves.easeInOut),
    );

    // ── 8 Staggered Petal Opacities ──
    for (int i = 0; i < 8; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2800 + (i * 120)),
      );
      _petalCtrls.add(ctrl);

      _petalOpacities.add(
        Tween<double>(begin: 0.45, end: 1.0).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
        ),
      );

      // Stagger start so petals don't breathe in unison
      Future.delayed(Duration(milliseconds: i * 250), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _ringRotCtrl.dispose();
    _gemBreathCtrl.dispose();
    for (final c in _petalCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background soft glow (static — never repaints)
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.emeraldCore : const Color(0xFFEAA196))
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
            ),

            // Layer 1: Golden Time-Halo — ROTATING 360° every 4s
            Positioned.fill(
              child: RotationTransition(
                turns: _ringRotCtrl,
                child: CustomPaint(
                  isComplex: true,
                  willChange: false, // Shape is static; RotationTransition handles transform
                  painter: _StaticHaloPainter(isDark: isDark),
                ),
              ),
            ),

            // Layer 2: 8 Vein-Petals — staggered opacity breathing
            ...List.generate(8, (i) {
              return Positioned.fill(
                child: FadeTransition(
                  opacity: _petalOpacities[i],
                  child: CustomPaint(
                    isComplex: true,
                    willChange: false, // Static shape; only opacity animates
                    painter: _StaticPetalPainter(
                      index: i,
                      totalPetals: 8,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            }),

            // Layer 3: Emerald Gem Core — breathing scale + glow pulse
            SizedBox(
              width: s * 0.35,
              height: s * 0.35,
              child: ScaleTransition(
                scale: _gemScale,
                child: AnimatedBuilder(
                  animation: _gemGlow,
                  builder: (_, __) => CustomPaint(
                    isComplex: true,
                    willChange: true, // Glow intensity changes each frame
                    painter: _GemCorePainter(
                      glowIntensity: _gemGlow.value,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAINTERS (Pre-allocated Paint/Path objects for flicker-free rendering)
// ══════════════════════════════════════════════════════════════

/// Golden ring with shimmer highlight — painted once statically.
/// The RotationTransition above handles the orbital sweep.
class _StaticHaloPainter extends CustomPainter {
  final bool isDark;
  final Paint _basePaint;
  final Paint _shimmerPaint;
  final Paint _glowPaint;
  final Color _goldenColor;

  _StaticHaloPainter({required this.isDark})
      : _goldenColor = isDark ? const Color(0xFFFFD700) : const Color(0xFFD4AF37),
        _basePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
        _shimmerPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
        _glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0) {
    _basePaint.color = _goldenColor.withValues(alpha: isDark ? 0.25 : 0.15);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.9;

    // Full base ring
    canvas.drawCircle(center, r, _basePaint);

    // Static shimmer highlight (90° arc at the top)
    final shader = SweepGradient(
      colors: [
        _goldenColor.withValues(alpha: 0.0),
        _goldenColor.withValues(alpha: 1.0),
        _goldenColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: r));

    _shimmerPaint.shader = shader;
    _glowPaint.shader = shader;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi * 0.75,
      math.pi / 2,
      false,
      _shimmerPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi * 0.75,
      math.pi / 2,
      false,
      _glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StaticHaloPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Single petal — painted once; FadeTransition handles breathing.
class _StaticPetalPainter extends CustomPainter {
  final int index;
  final int totalPetals;
  final bool isDark;
  final Paint _fillPaint;
  final Paint _outlinePaint;
  final Paint _vPaint;
  final Paint _branchPaint;
  final Path _p;
  final Color _petalBase;
  final Color _veinColor;

  _StaticPetalPainter({
    required this.index,
    required this.totalPetals,
    required this.isDark,
  })  : _petalBase = isDark ? const Color(0xFF50C878) : const Color(0xFFEAA196),
        _veinColor = isDark ? const Color(0xFF00FF7F) : const Color(0xFF8A9A5B),
        _fillPaint = Paint()..style = PaintingStyle.fill,
        _outlinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
        _vPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
        _branchPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
        _p = Path() {
    _outlinePaint.color = _petalBase.withValues(alpha: isDark ? 0.4 : 0.3);
    _vPaint.color = _veinColor.withValues(alpha: isDark ? 0.8 : 0.65);
    _branchPaint.color = _veinColor.withValues(alpha: isDark ? 0.5 : 0.4);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final angle = (index * 2 * math.pi) / totalPetals;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final maxLen = (size.width / 2) * 0.68;
    final width = maxLen * 0.45;

    _p.reset();
    _p.moveTo(0, 0);
    _p.quadraticBezierTo(width * 0.8, -maxLen * 0.4, 0, -maxLen);
    _p.quadraticBezierTo(-width * 0.8, -maxLen * 0.4, 0, 0);

    _fillPaint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        _petalBase.withValues(alpha: isDark ? 0.05 : 0.08),
        _petalBase.withValues(alpha: isDark ? 0.3 : 0.25),
      ],
    ).createShader(_p.getBounds());

    canvas.drawPath(_p, _fillPaint);
    canvas.drawPath(_p, _outlinePaint);

    canvas.drawLine(Offset.zero, Offset(0, -maxLen * 0.95), _vPaint);

    for (int v = 1; v <= 4; v++) {
      final startY = -maxLen * (v / 6.0);
      final outX = width * 0.5 * (1.0 - (v / 6.0));
      final endY = startY - (maxLen * 0.15);
      canvas.drawLine(Offset(0, startY), Offset(outX, endY), _branchPaint);
      canvas.drawLine(Offset(0, startY), Offset(-outX, endY), _branchPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StaticPetalPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Emerald gem facets at a fixed 3D angle; only glow intensity animates.
class _GemCorePainter extends CustomPainter {
  final double glowIntensity;
  final bool isDark;
  final Paint _glowPaint;
  final Paint _fillPaintTop;
  final Paint _fillPaintBot;
  final Paint _outlineP;
  final Paint _spotPaint;
  final Path _facePathTop;
  final Path _facePathBot;
  final Color _color1;
  final Color _color2;

  static const double _fixedRotY = 0.4;
  static const List<List<double>> _vertices = [
    [0.0, -1.0, 0.0],
    [0.0, 1.0, 0.0],
    [1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0],
    [-1.0, 0.0, 0.0],
    [0.0, 0.0, -1.0],
  ];

  _GemCorePainter({required this.glowIntensity, required this.isDark})
      : _color1 = isDark ? const Color(0xFF39FF14) : const Color(0xFF8A9A5B),
        _color2 = isDark ? const Color(0xFF0F4C3A) : const Color(0xFFEAA196),
        _glowPaint = Paint(),
        _fillPaintTop = Paint()..style = PaintingStyle.fill,
        _fillPaintBot = Paint()..style = PaintingStyle.fill,
        _outlineP = Paint()..style = PaintingStyle.stroke,
        _spotPaint = Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
        _facePathTop = Path(),
        _facePathBot = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    _glowPaint.shader = RadialGradient(
      colors: [
        _color1.withValues(alpha: glowIntensity),
        _color2.withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.5));
    canvas.drawCircle(Offset(cx, cy), r * 1.5, _glowPaint);

    final cosR = math.cos(_fixedRotY);
    final sinR = math.sin(_fixedRotY);

    final projected2D = <Offset>[];
    for (final v in _vertices) {
      double dx = v[0] * cosR - v[2] * sinR;
      double dy = v[1];
      projected2D.add(Offset(cx + dx * r, cy + dy * r));
    }

    final top = projected2D[0];
    final bot = projected2D[1];

    final zRotated = [
      _vertices[2][0] * sinR + _vertices[2][2] * cosR,
      _vertices[3][0] * sinR + _vertices[3][2] * cosR,
      _vertices[4][0] * sinR + _vertices[4][2] * cosR,
      _vertices[5][0] * sinR + _vertices[5][2] * cosR,
    ];

    final equatorIndices = [2, 3, 4, 5];
    equatorIndices.sort((a, b) => zRotated[a - 2].compareTo(zRotated[b - 2]));

    for (final idx in equatorIndices) {
      final isFront = zRotated[idx - 2] >= 0;
      final nextIdxMap = {2: 3, 3: 4, 4: 5, 5: 2};
      final nextIdx = nextIdxMap[idx]!;

      final pCur = projected2D[idx];
      final pNext = projected2D[nextIdx];

      _facePathTop.reset();
      _facePathTop.moveTo(top.dx, top.dy);
      _facePathTop.lineTo(pCur.dx, pCur.dy);
      _facePathTop.lineTo(pNext.dx, pNext.dy);
      _facePathTop.close();

      _facePathBot.reset();
      _facePathBot.moveTo(bot.dx, bot.dy);
      _facePathBot.lineTo(pCur.dx, pCur.dy);
      _facePathBot.lineTo(pNext.dx, pNext.dy);
      _facePathBot.close();

      double lightFactor(double dx, double dy) => ((dx.abs() + dy.abs() + 1.0) / 3.0);
      double lTop = lightFactor(pCur.dx - top.dx, pCur.dy - top.dy + pNext.dx);
      double lBot = lightFactor(pCur.dx - bot.dx, pCur.dy - bot.dy + pNext.dx);

      lTop = (lTop % 1.0) * (isFront ? 1.0 : 0.4);
      lBot = (lBot % 1.0) * (isFront ? 1.0 : 0.4);

      _fillPaintTop.color =
          Color.lerp(_color2, _color1, lTop)!.withValues(alpha: isFront ? 0.9 : 0.5);
      _fillPaintBot.color =
          Color.lerp(_color2, _color1, lBot)!.withValues(alpha: isFront ? 0.9 : 0.5);

      _outlineP.color = isDark
          ? Colors.white.withValues(alpha: isFront ? 0.4 : 0.1)
          : Colors.white.withValues(alpha: isFront ? 0.7 : 0.3);
      _outlineP.strokeWidth = isFront ? 1.5 : 0.5;

      canvas.drawPath(_facePathTop, _fillPaintTop);
      canvas.drawPath(_facePathBot, _fillPaintBot);
      canvas.drawPath(_facePathTop, _outlineP);
      canvas.drawPath(_facePathBot, _outlineP);
    }

    _spotPaint.color = Colors.white.withValues(alpha: glowIntensity);
    canvas.drawCircle(Offset(cx, cy - r * 0.3), r * 0.2, _spotPaint);
  }

  @override
  bool shouldRepaint(covariant _GemCorePainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity || oldDelegate.isDark != isDark;
}
