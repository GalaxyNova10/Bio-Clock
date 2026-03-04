import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../shared/core/app_theme.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/ui/clay_card.dart';
import '../../../shared/ui/status_orb.dart';
import '../../../shared/ui/animated_counter.dart';

/// Vault Discovery Hub — Emerald Claymorphism Redesign
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep, // Deep forest night
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.bgDeep.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldCore,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emeraldCore.withValues(alpha: 0.3),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child:
                      const Icon(Icons.eco, color: AppTheme.bgDeep, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Bio Clock',
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 5),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: ClayCard(
                        glow: true,
                        baseColor: AppTheme.bgMid,
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppTheme.statusExpire),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'APP-SNS-ALERT: Mango dropping below safe Q10 threshold.',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active,
                    color: AppTheme.emeraldBrite),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12), // Deep padding
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // ── Hero Orb Section ────────────
                Center(
                  child: const StatusOrb(
                    size: 150,
                    baseColor: AppTheme.emeraldCore,
                    label: 'Bio-Clock AI Ready',
                    sublabel: 'Claude 4.5 Haiku Active',
                  ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOutBack,
                      ),
                ),

                const SizedBox(height: 32),

                // ── Feature Walkthrough ClayCards ──

                // 1. Smart Scanning
                ClayCard(
                  glow: true,
                  baseColor: AppTheme.surfaceBase,
                  onTap: () => context.go('/scan'),
                  child: Row(
                    children: [
                      const ClayPill(
                        color: AppTheme.emeraldCore,
                        glow: false,
                        child: Icon(Icons.qr_code_scanner,
                            color: AppTheme.bgDeep, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart Scanning',
                                style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                                'Auto-detect produce freshness in seconds via AI.',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 2. Live Graph (Waveform preview)
                ClayCard(
                  onTap: () => context.go('/graph'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.show_chart,
                              color: AppTheme.emeraldBrite, size: 24),
                          const SizedBox(width: 12),
                          Text('Live RUL Graph',
                              style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: WaveformPainter(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining Useful Life',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: AppTheme.textMuted)),
                          Text('Forecast',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  color: AppTheme.emeraldBrite,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 3. Inventory Vault (Purple tint)
                ClayCard(
                  onTap: () => context.go('/inventory'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  AppTheme.accentPurple.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.inventory_2,
                            color: AppTheme.accentPurple, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inventory Vault',
                                style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.cloud_sync,
                                    color: AppTheme.accentPurple, size: 14),
                                const SizedBox(width: 6),
                                Text('S3 Sync Active',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: AppTheme.accentPurple,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 4. AI Preservation (Amber tint)
                ClayCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb,
                              color: AppTheme.accentAmber, size: 24),
                          const SizedBox(width: 12),
                          Text('AI Preservation',
                              style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppTheme.accentAmber.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '"Apples release ethylene gas. Store them separately from avocados to slow down ripening by 2.4x."',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color:
                                  AppTheme.accentAmber.withValues(alpha: 0.9),
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 5. Neuro-Symbolic Engine (Q10 Formula)
                ClayCard(
                  glow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology,
                              color: AppTheme.emeraldBrite, size: 24),
                          const SizedBox(width: 12),
                          Text('Neuro-Symbolic Engine',
                              style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDeep,
                          borderRadius: BorderRadius.circular(16),
                          // Faint emerald grid background
                          image: DecorationImage(
                            image: const NetworkImage(
                                'https://www.transparenttextures.com/patterns/cubes.png'), // Placeholder for grid pattern
                            colorFilter: ColorFilter.mode(
                                AppTheme.emeraldGlow.withValues(alpha: 0.05),
                                BlendMode.srcATop),
                            repeat: ImageRepeat.repeat,
                          ),
                          border: Border.all(
                              color:
                                  AppTheme.emeraldCore.withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            '2.0^(ΔT / 10.0)',
                            style: GoogleFonts.spaceMono(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldBrite,
                                letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Q10 Thermodynamic Spoilage Coefficient',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // ── Impact Output Counter ───────────
                if (settings.demoMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Waste Prevented: ',
                          style: GoogleFonts.nunito(
                              fontSize: 16, color: AppTheme.textSecondary)),
                      AnimatedCounter(
                        value: 284,
                        suffix: ' kg',
                        style: GoogleFonts.spaceMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldCore),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),

                const SizedBox(
                    height: 120), // Padding for the floating nav pill
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.emeraldCore
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.2);

    // Create a stylized descending wave
    final random = math.Random(42);
    double x = 0;
    while (x < size.width) {
      x += 20;
      double y = size.height * 0.2 +
          (x / size.width) * size.height * 0.7; // general downward trend
      y += (random.nextDouble() - 0.5) * 15; // noise
      path.lineTo(x, y);
    }

    // Add a gentle glow below the line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.emeraldCore.withValues(alpha: 0.3),
          AppTheme.bgDeep.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
