import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/core/app_theme.dart';

/// Premium splash screen with pulsing Bio-Clock logo on deep emerald.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    // Auto-navigate after 4 seconds
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D3B2E),
              Color(0xFF0A2F25),
              Color(0xFF08241C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Subtle radial glow behind logo
            Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  return Container(
                    width: 260 + (_glowController.value * 40),
                    height: 260 + (_glowController.value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentGreen.withValues(
                              alpha: 0.08 + _glowController.value * 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glassmorphism logo container
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, _) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGreen.withValues(
                                  alpha: 0.2 + _glowController.value * 0.15),
                              blurRadius: 30 + _glowController.value * 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Logo Image
                            SvgPicture.asset(
                              'assets/images/bioClockLeafLogo.svg',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 800.ms).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                        duration: 800.ms,
                      ),

                  const SizedBox(height: 32),

                  // App name
                  const Text(
                    'Bio Clock',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 800.ms)
                      .slideY(begin: 0.15),

                  const SizedBox(height: 10),

                  // Tagline / Connection Sequence
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: 4),
                    duration: const Duration(milliseconds: 4000),
                    builder: (context, value, child) {
                      final statusStrings = [
                        'Initializing App...',
                        'Waking Claude 4.5 Haiku...',
                        'Syncing DynamoDB Vault...',
                        'Connecting AWS SNS...',
                        'Bio-Guardian Online',
                      ];
                      return Text(
                        statusStrings[value.clamp(0, 4)],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.emeraldBrite.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                          fontFamily: 'Space Mono',
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: 1000.ms, duration: 800.ms),

                  const SizedBox(height: 48),

                  // Loading indicator
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.accentGreen.withValues(alpha: 0.6),
                      backgroundColor:
                          AppTheme.accentGreen.withValues(alpha: 0.1),
                    ),
                  ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),
                ],
              ),
            ),

            // Version at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ).animate().fadeIn(delay: 1800.ms, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }
}
