import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import '../../../shared/core/app_theme.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/ui/clay_card.dart';
import '../../../shared/ui/chrono_seed.dart';
import '../../../shared/ui/animated_counter.dart';

/// Vault Discovery Hub — Emerald Claymorphism Redesign
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBase = isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
    final cardPeak = isDark ? const Color(0xFF1A1F2B) : const Color(0xFFF0FAF4);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mutedText = onSurface.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: scaffoldBg.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/bioClockLeafLogo.svg',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                Text('Bio Clock',
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: onSurface)),
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
                icon: const Icon(LucideIcons.bell,
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

                // ── The Chrono-Seed ────────────
                Center(
                  child: SizedBox(
                    height: 320, // Strict height guard to prevent cards dropping or overlapping
                    child: const ChronoSeed(
                      size: 260,
                    ).animate().fadeIn(duration: 600.ms).scale(
                          begin: const Offset(0.9, 0.9),
                          curve: Curves.easeOutBack,
                        ),
                  ),
                ),

                const SizedBox(height: 12),
                
                // Labels below the orb
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Bio-Clock AI Ready',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.emeraldCore,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Claude 4.5 Haiku Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Feature Walkthrough ClayCards ──

                // 1. Smart Scanning
                ClayCard(
                  glow: true,
                  baseColor: cardBase,
                  peakColor: cardPeak,
                  child: Row(
                    children: [
                      const TwoToneIcon(
                        icon: Icons.qr_code_scanner, size: 26,
                        colorA: Color(0xFF39FF14), colorB: Color(0xFF00BFA5), // Neon Green → Teal
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
                                    color: onSurface)),
                            const SizedBox(height: 4),
                            Text(
                                'Our AI-powered engine auto-detects 61+ produce classes in seconds. Using localized PyTorch Lite models, it identifies visual spoilage cues with 85%+ accuracy without requiring manual user input or cloud-only shutter delays.',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13, color: mutedText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 2. Live Graph (Waveform preview)
                ClayCard(
                  baseColor: cardBase,
                  peakColor: cardPeak,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const TwoToneIcon(
                                icon: Icons.show_chart, size: 26,
                                colorA: Color(0xFF00E5FF), colorB: Color(0xFF2979FF), // Cyan → Blue
                              ),
                              const SizedBox(width: 12),
                              Text('Live RUL Graph',
                                  style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FFCC).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00FFCC).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00FFCC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('LIVE · Chennai',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00FFCC))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: ChennaiAreaPainter(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('30°C  ·  70% Humidity',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  color: const Color(0xFF00FFCC).withValues(alpha: 0.7))),
                          Text('Q₁₀ = 2.41x',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  color: AppTheme.emeraldBrite,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Visualize the biological decay of your food in real-time. This interactive forecast syncs with local weather data to simulate how temperature and humidity spikes accelerate or decelerate the remaining useful life of your inventory.',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: mutedText),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining Useful Life',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: mutedText)),
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

                // 3. Inventory Vault (Violet → Blue)
                ClayCard(
                  baseColor: cardBase,
                  peakColor: cardPeak,
                  child: Row(
                    children: [
                      const TwoToneIcon(
                        icon: Icons.inventory_2, size: 26,
                        colorA: Color(0xFFBB86FC), colorB: Color(0xFF6200EA), // Violet → Deep Purple
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inventory',
                                style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.cloud_sync,
                                    color: Color(0xFFBB86FC), size: 14),
                                const SizedBox(width: 6),
                                Text('S3 Sync Active',
                                    style: GoogleFonts.spaceMono(
                                        fontSize: 11,
                                        color: const Color(0xFFBB86FC),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Manage your household's biological waste footprint. Our S3-synced vault tracks every item, providing batch predictions for your entire fridge so you know exactly which items to consume first based on real-time spoilage telemetry.",
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 4. AI Preservation (Gold → Orange)
                ClayCard(
                  baseColor: cardBase,
                  peakColor: cardPeak,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TwoToneIcon(
                            icon: Icons.lightbulb, size: 26,
                            colorA: Color(0xFFFFC000), colorB: Color(0xFFFF6D00), // Gold → Orange
                          ),
                          const SizedBox(width: 12),
                          Text('AI Preservation',
                              style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1200) : const Color(0xFFFFF8E1), // deep amber-tinted
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  const Color(0xFFFFC000).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          "Apples release ethylene gas. Store them separately from avocados to slow down ripening by 2.4x. This context-aware strategy is generated by our neuro-symbolic reasoning engine to extend the life of your specific produce by up to 3x.",
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color:
                                  const Color(0xFFFFC000).withValues(alpha: 0.9), // Gold-Amber
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // 5. Neuro-Symbolic Engine (Mint → Emerald)
                ClayCard(
                  glow: false,
                  baseColor: cardBase,
                  peakColor: cardPeak,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const TwoToneIcon(
                            icon: LucideIcons.brain, size: 26,
                            colorA: Color(0xFF00FFCC), colorB: Color(0xFF10B981), // Cyber-Mint → Emerald
                          ),
                          const SizedBox(width: 12),
                          Text('Neuro-Symbolic Engine',
                              style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0A0F14) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  const Color(0xFF00FFCC).withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: Text(
                            '2.0^(ΔT / 10.0)',
                            style: GoogleFonts.spaceMono(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00FFCC), // Cyber-Mint
                                letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Q10 Thermodynamic Spoilage Coefficient',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10, color: mutedText),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "The Bio-Clock uses thermodynamic spoilage coefficients to translate environmental stress into hours. By modeling molecular decay, our AI provides a 94% accurate biological verdict for your food's safety.",
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: mutedText),
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
                              fontSize: 16, color: mutedText)),
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

class TwoToneIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color colorA;
  final Color colorB;
  
  const TwoToneIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.colorA = const Color(0xFF39FF14),
    this.colorB = const Color(0xFF00BFA5),
  });
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [colorA, colorB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class ChennaiAreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.emeraldCore
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.2);

    // Create a stylized descending wave for Chennai Forecast
    final random = math.Random(10);
    double x = 0;
    while (x < size.width) {
      x += 20;
      double y = size.height * 0.2 +
          (x / size.width) * size.height * 0.7; // general downward trend
      y += (random.nextDouble() - 0.5) * 15; // noise representing heat index spikes
      path.lineTo(x, y);
    }

    // Add a vibrant gradient glow below the line (Area Chart)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF39FF14).withValues(alpha: 0.4), // Neon Green
          const Color(0xFF0A1A10).withValues(alpha: 0.0), // Faded to charcoal forest
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
