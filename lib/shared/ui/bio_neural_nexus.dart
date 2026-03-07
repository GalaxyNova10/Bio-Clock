import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Bio-Neural Nexus — a world-class animated AI visualizer.
///
/// Features three synchronized animations:
///  1. Neural network heartbeat pulse (opacity, 1.5s)
///  2. Horizontal scan line sweep (top→bottom, 4s)
///  3. Microscopic particle flow along data lines (continuous)
class BioNeuralNexus extends StatefulWidget {
  final double size;
  final String label;
  final String sublabel;

  const BioNeuralNexus({
    super.key,
    this.size = 220,
    this.label = 'Bio-Clock AI Ready',
    this.sublabel = 'Claude 4.5 Haiku Active',
  });

  @override
  State<BioNeuralNexus> createState() => _BioNeuralNexusState();
}

class _BioNeuralNexusState extends State<BioNeuralNexus>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _particleCtrl;

  // Neural node positions (normalized 0-1)
  static const List<Offset> _nodes = [
    Offset(0.50, 0.15), // top center
    Offset(0.28, 0.22), // top-left
    Offset(0.72, 0.22), // top-right
    Offset(0.15, 0.38), // mid-left outer
    Offset(0.35, 0.35), // mid-left inner
    Offset(0.65, 0.35), // mid-right inner
    Offset(0.85, 0.38), // mid-right outer
    Offset(0.22, 0.55), // lower-left
    Offset(0.50, 0.50), // center core
    Offset(0.78, 0.55), // lower-right
    Offset(0.30, 0.72), // bottom-left
    Offset(0.50, 0.70), // bottom center
    Offset(0.70, 0.72), // bottom-right
    Offset(0.40, 0.85), // base-left
    Offset(0.60, 0.85), // base-right
    Offset(0.50, 0.92), // stem tip
  ];

  // Edge connections (indices into _nodes)
  static const List<List<int>> _edges = [
    [0, 1], [0, 2], // top fan
    [1, 4], [2, 5], // upper diagonal
    [1, 3], [2, 6], // outer reach
    [3, 4], [5, 6], // mid horizontal
    [4, 8], [5, 8], // inner to core
    [3, 7], [6, 9], // outer to lower
    [7, 8], [8, 9], // lower mid
    [7, 10], [8, 11], [9, 12], // lower fan
    [10, 13], [11, 13], [11, 14], [12, 14], // base lattice
    [13, 15], [14, 15], // to stem
    [4, 7], [5, 9], // long diagonals
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final s = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── The Nexus Container ──
        Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? const Color(0xFF0A0F14).withValues(alpha: 0.6)
                : const Color(0xFFE8F5E9).withValues(alpha: 0.5),
            border: Border.all(
              color: AppTheme.emeraldCore.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.emeraldCore.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              if (isDark)
                BoxShadow(
                  color: const Color(0xFF0A0F14).withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Background radial glow
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BackgroundGlowPainter(isDark: isDark),
                  ),
                ),

                // Avocado silhouette
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AvocadoSilhouettePainter(isDark: isDark),
                  ),
                ),

                // Neural network with pulse
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _NeuralNetworkPainter(
                        pulseValue: _pulseCtrl.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // Scan line
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scanCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ScanLinePainter(
                        progress: _scanCtrl.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // Particles
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particleCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ParticlePainter(
                        progress: _particleCtrl.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // Center core emblem
                Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.emeraldCore.withValues(alpha: 0.9),
                          AppTheme.emeraldCore.withValues(alpha: 0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emeraldCore.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Labels ──
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.emeraldCore,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.sublabel,
          style: TextStyle(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAINTERS
// ══════════════════════════════════════════════════════════════

/// Soft radial background glow
class _BackgroundGlowPainter extends CustomPainter {
  final bool isDark;
  _BackgroundGlowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF50C878).withValues(alpha: 0.12),
                const Color(0xFF50C878).withValues(alpha: 0.03),
                Colors.transparent,
              ]
            : [
                const Color(0xFF50C878).withValues(alpha: 0.08),
                const Color(0xFF50C878).withValues(alpha: 0.02),
                Colors.transparent,
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stylized avocado cross-section silhouette
class _AvocadoSilhouettePainter extends CustomPainter {
  final bool isDark;
  _AvocadoSilhouettePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Outer shell
    final shellPath = Path();
    shellPath.moveTo(cx, h * 0.12);
    shellPath.cubicTo(cx + w * 0.30, h * 0.12, cx + w * 0.38, h * 0.35, cx + w * 0.32, h * 0.55);
    shellPath.cubicTo(cx + w * 0.25, h * 0.72, cx + w * 0.10, h * 0.85, cx, h * 0.90);
    shellPath.cubicTo(cx - w * 0.10, h * 0.85, cx - w * 0.25, h * 0.72, cx - w * 0.32, h * 0.55);
    shellPath.cubicTo(cx - w * 0.38, h * 0.35, cx - w * 0.30, h * 0.12, cx, h * 0.12);
    shellPath.close();

    final shellPaint = Paint()
      ..color = const Color(0xFF50C878).withValues(alpha: isDark ? 0.08 : 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shellPath, shellPaint);

    // Shell outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF50C878).withValues(alpha: isDark ? 0.25 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(shellPath, outlinePaint);

    // Seed (pit) — the inner circle
    final seedCenter = Offset(cx, h * 0.52);
    final seedRadius = w * 0.12;

    final seedPaint = Paint()
      ..color = const Color(0xFF50C878).withValues(alpha: isDark ? 0.12 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(seedCenter, seedRadius, seedPaint);

    final seedOutlinePaint = Paint()
      ..color = const Color(0xFF50C878).withValues(alpha: isDark ? 0.30 : 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(seedCenter, seedRadius, seedOutlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Neural network with heartbeat pulse
class _NeuralNetworkPainter extends CustomPainter {
  final double pulseValue;
  final bool isDark;
  _NeuralNetworkPainter({required this.pulseValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _BioNeuralNexusState._nodes;
    final edges = _BioNeuralNexusState._edges;

    // Pulsing opacity: oscillate between 0.3 and 0.8
    final baseAlpha = 0.3 + (pulseValue * 0.5);
    final edgeAlpha = 0.15 + (pulseValue * 0.25);

    // Draw edges
    final edgePaint = Paint()
      ..color = const Color(0xFF50C878).withValues(alpha: edgeAlpha * (isDark ? 1.0 : 0.7))
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final a = Offset(nodes[edge[0]].dx * size.width, nodes[edge[0]].dy * size.height);
      final b = Offset(nodes[edge[1]].dx * size.width, nodes[edge[1]].dy * size.height);
      canvas.drawLine(a, b, edgePaint);
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final pos = Offset(nodes[i].dx * size.width, nodes[i].dy * size.height);
      final isCore = i == 8; // center core node

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF50C878).withValues(
            alpha: baseAlpha * (isCore ? 0.6 : 0.3) * (isDark ? 1.0 : 0.6))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos, isCore ? 6 : 4, glowPaint);

      // Solid dot
      final dotPaint = Paint()
        ..color = const Color(0xFF50C878).withValues(
            alpha: baseAlpha * (isDark ? 1.0 : 0.8));
      canvas.drawCircle(pos, isCore ? 3.5 : 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralNetworkPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue;
}

/// Horizontal scan line sweeping top to bottom
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _ScanLinePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;

    // Scan line with gradient fade
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF50C878).withValues(alpha: isDark ? 0.6 : 0.4),
          const Color(0xFF50C878).withValues(alpha: isDark ? 0.8 : 0.5),
          const Color(0xFF50C878).withValues(alpha: isDark ? 0.6 : 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.15, y), Offset(size.width * 0.85, y), paint);

    // Trail fade (subtle glow behind the scan line)
    final trailHeight = size.height * 0.06;
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF50C878).withValues(alpha: isDark ? 0.06 : 0.03),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.15, y - trailHeight, size.width * 0.7, trailHeight));

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, y - trailHeight, size.width * 0.7, trailHeight),
      trailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Microscopic particles flowing along edges toward center
class _ParticlePainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _ParticlePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _BioNeuralNexusState._nodes;
    final edges = _BioNeuralNexusState._edges;
    final rng = Random(42); // deterministic seed for stable positions

    final particlePaint = Paint()
      ..color = const Color(0xFF50C878).withValues(alpha: isDark ? 0.7 : 0.5);

    // Each edge gets 1-2 particles traveling along it
    for (int i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final a = Offset(nodes[edge[0]].dx * size.width, nodes[edge[0]].dy * size.height);
      final b = Offset(nodes[edge[1]].dx * size.width, nodes[edge[1]].dy * size.height);

      // Stagger particles by edge index
      final offset = (rng.nextDouble() * 0.7);
      final t = ((progress + offset) % 1.0);

      final pos = Offset(
        a.dx + (b.dx - a.dx) * t,
        a.dy + (b.dy - a.dy) * t,
      );

      canvas.drawCircle(pos, 1.2, particlePaint);

      // Second particle on every other edge, offset by 0.5
      if (i.isEven) {
        final t2 = ((progress + offset + 0.5) % 1.0);
        final pos2 = Offset(
          a.dx + (b.dx - a.dx) * t2,
          a.dy + (b.dy - a.dy) * t2,
        );
        canvas.drawCircle(pos2, 0.8, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
