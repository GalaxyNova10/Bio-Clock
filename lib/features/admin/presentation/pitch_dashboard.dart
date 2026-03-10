import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/ui/clay_card.dart';
import 'dart:math' as math;

class PitchDashboard extends StatefulWidget {
  const PitchDashboard({super.key});

  @override
  State<PitchDashboard> createState() => _PitchDashboardState();
}

class _PitchDashboardState extends State<PitchDashboard> {
  double _tempDelta = 10.0; // ΔT for Q10 formula

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Bio-Clock: Technical Pitch',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Cloud Infrastructure Map ──
          Text('CLOUD INFRASTRUCTURE',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.emeraldBrite)),
          const SizedBox(height: 12),
          ClayCard(
            glow: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfraRow(LucideIcons.smartphone, 'Flutter Edge Node',
                      'Sends 64-class logits + Metadata'),
                  _buildInfraLine(),
                  _buildInfraRow(LucideIcons.zap, 'Amazon API Gateway',
                      'Rest Endpoint (eu-north-1)'),
                  _buildInfraLine(),
                  _buildInfraRow(LucideIcons.cpu, 'AWS SAM Lambda',
                      'Runs Core Neuro-Symbolic Engine'),
                  _buildInfraLine(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                          child: _buildInfraRow(
                              LucideIcons.sparkles,
                              'Amazon Nova Pro',
                              'Primary AI Reasoning Engine')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildInfraRow(LucideIcons.database,
                              'Amazon DynamoDB', 'State / Q10 Timelines')),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

          const SizedBox(height: 16),

          // ── Resilience Status ──
          ClayCard(
            glow: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck,
                        color: AppTheme.accentGreen, size: 18),
                    const SizedBox(width: 8),
                    Text('RESILIENCE STATUS',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.accentGreen)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Primary: Amazon Nova Pro | Failover: In-house ML Engine',
                    style: GoogleFonts.spaceMono(
                        fontSize: 12, color: Colors.white)),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 500.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 32),

          // ── Live Metrics ──
          Text('LIVE METRICS',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.emeraldBrite)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildMetricCard(
                      'Total AI Reasonings', '14,092', '+12%')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard(
                      'Biological Accuracy', '94.2%', '+1.1%')),
            ],
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 500.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child:
                      _buildMetricCard('Latency (Bedrock)', '840ms', '-30ms')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard(
                      'Cloud Cost / Scan', '\$0.0004', 'Stable')),
            ],
          )
              .animate()
              .fadeIn(delay: 250.ms, duration: 500.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 32),

          // ── Q10 Math Interactive Demo ──
          Text('NEURO-SYMBOLIC ENGINE (Q10)',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.emeraldBrite)),
          const SizedBox(height: 12),
          ClayCard(
            glow: true,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spoilage Multiplier = 2.0 ^ (ΔT / 10.0)',
                      style: GoogleFonts.spaceMono(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),

                  // Interactive Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ΔT (Temp Difference)',
                          style: GoogleFonts.nunito(fontSize: 14)),
                      Text('${_tempDelta.toStringAsFixed(1)} °C',
                          style: GoogleFonts.spaceMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.emeraldBrite)),
                    ],
                  ),
                  Slider(
                    value: _tempDelta,
                    min: 0,
                    max: 30,
                    activeColor: AppTheme.emeraldGlow,
                    inactiveColor: AppTheme.surfaceUp,
                    onChanged: (val) => setState(() => _tempDelta = val),
                  ),

                  const SizedBox(height: 16),

                  // Live Result
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfacePeak),
                    ),
                    child: Column(
                      children: [
                        Text('Resulting Decay Multiplier',
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          '${math.pow(2.0, _tempDelta / 10.0).toStringAsFixed(2)}x',
                          style: GoogleFonts.spaceMono(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.statusExpire),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'Produce spoils ${math.pow(2.0, _tempDelta / 10.0).toStringAsFixed(2)}x faster.',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 500.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfraRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfacePeak),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.emeraldGlow, size: 24),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                  fontSize: 8, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildInfraLine() {
    return Container(
      width: 2,
      height: 20,
      color: AppTheme.emeraldCore.withValues(alpha: 0.3),
    );
  }

  Widget _buildMetricCard(String title, String value, String change) {
    return ClayCard(
      glow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  GoogleFonts.nunito(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.spaceMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: AppTheme.emeraldBrite, size: 14),
              const SizedBox(width: 4),
              Text(change,
                  style: GoogleFonts.spaceMono(
                      fontSize: 10, color: AppTheme.emeraldBrite)),
            ],
          )
        ],
      ),
    );
  }
}
