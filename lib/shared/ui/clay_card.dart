import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';

class ClayCard extends StatefulWidget {
  final Widget child;
  final bool glow;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? baseColor;
  final Color? peakColor;

  const ClayCard({
    super.key,
    required this.child,
    this.glow = false,
    this.onTap,
    this.borderRadius = AppTheme.radiusXl,
    this.padding = const EdgeInsets.all(16.0),
    this.baseColor,
    this.peakColor,
  });

  @override
  State<ClayCard> createState() => _ClayCardState();
}

class _ClayCardState extends State<ClayCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBaseColor = widget.baseColor ?? AppTheme.surfaceBase;
    final effectivePeakColor = widget.peakColor ?? AppTheme.surfacePeak;

    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: widget.padding,
          // Inner container for the gradient border effect
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [effectivePeakColor, effectiveBaseColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow:
                widget.glow ? AppTheme.clayGlowShadow : AppTheme.clayShadow,
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.1), // Internal top-light highlight
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Additional helpful clay components that fit the theme

class ClayPill extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool glow;

  const ClayPill({
    super.key,
    required this.child,
    this.color = AppTheme.statusExpire,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        boxShadow: glow
            ? AppTheme.neonGlow(color, intensity: 0.3)
            : AppTheme.clayShadow,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class ClayPillButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color baseColor;

  const ClayPillButton({
    super.key,
    required this.child,
    required this.onTap,
    this.baseColor = AppTheme.emeraldCore,
  });

  @override
  State<ClayPillButton> createState() => _ClayPillButtonState();
}

class _ClayPillButtonState extends State<ClayPillButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
