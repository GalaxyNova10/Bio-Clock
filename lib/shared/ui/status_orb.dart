import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Multi-layered pulsing emerald nexus
/// Three concentric rings pulse at staggered intervals with neon glow.
class StatusOrb extends StatefulWidget {
  final double size;
  final Color baseColor;
  final String? label;
  final String? sublabel;

  const StatusOrb({
    super.key,
    this.size = 140,
    this.baseColor = AppTheme.emeraldCore,
    this.label,
    this.sublabel,
  });

  @override
  State<StatusOrb> createState() => _StatusOrbState();
}

class _StatusOrbState extends State<StatusOrb> with TickerProviderStateMixin {
  late AnimationController _ring1;
  late AnimationController _ring2;
  late AnimationController _ring3;

  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _pulse3;

  @override
  void initState() {
    super.initState();

    _ring1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _ring2 = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _ring3 = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _pulse1 = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _ring1, curve: Curves.easeInOut),
    );
    _pulse2 = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ring2, curve: Curves.easeInOut),
    );
    _pulse3 = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ring3, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _ring3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.baseColor;
    final s = widget.size;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: s,
            height: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ring 3 — outermost (faint)
                AnimatedBuilder(
                  animation: _pulse3,
                  builder: (_, __) => _buildRing(
                    s * 0.95 * _pulse3.value,
                    color.withValues(alpha: 0.04),
                    color.withValues(alpha: 0.1),
                  ),
                ),
                // Ring 2 — middle
                AnimatedBuilder(
                  animation: _pulse2,
                  builder: (_, __) => _buildRing(
                    s * 0.65 * _pulse2.value,
                    color.withValues(alpha: 0.08),
                    color.withValues(alpha: 0.15),
                  ),
                ),
                // Ring 1 — inner bright
                AnimatedBuilder(
                  animation: _pulse1,
                  builder: (_, __) => _buildRing(
                    s * 0.4 * _pulse1.value,
                    AppTheme.emeraldGlow.withValues(alpha: 0.2),
                    AppTheme.emeraldBrite.withValues(alpha: 0.4),
                  ),
                ),
                // Core dot
                Container(
                  width: s * 0.22,
                  height: s * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.emeraldBrite,
                    boxShadow: AppTheme.clayGlowShadow,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.label != null)
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.emeraldBrite,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          if (widget.sublabel != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.sublabel!,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRing(double diameter, Color fill, Color stroke) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: stroke, width: 2.0),
      ),
    );
  }
}
