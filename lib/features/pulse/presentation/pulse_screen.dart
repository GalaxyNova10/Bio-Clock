import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/status_orb.dart';
import '../../../shared/ui/animated_counter.dart';

class PulseScreen extends ConsumerWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = context.ext;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('Bio-Clock Pulse',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // ── Hero Section ────────────
                Center(
                  child: const StatusOrb(
                    size: 140,
                    baseColor: AppTheme.accentGreen,
                    label: 'Claude 4.5 Haiku Ready',
                    sublabel: 'on AWS Bedrock',
                  ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOutBack,
                      ),
                ),

                const SizedBox(height: 32),

                // ── Gradient Title ──────────
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.gradientPrimary.createShader(bounds),
                  child: const Text(
                    'Bio-Clock Pulse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                const SizedBox(height: 8),
                Text(
                  'AI-powered food freshness monitoring\nusing neuro-symbolic models & AWS Bedrock',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: ext.textMuted,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                // ── Stats Row ───────────────
                const Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('🌱', style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 8),
                                  Text('CO₂ Saved',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentGreen,
                                      )),
                                ],
                              ),
                              SizedBox(height: 12),
                              AnimatedCounter(
                                  value: 12500,
                                  suffix: 'g',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('💰', style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 8),
                                  Text('Money Saved',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentAmber,
                                      )),
                                ],
                              ),
                              SizedBox(height: 12),
                              AnimatedCounter(
                                  value: 3450,
                                  prefix: '₹',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.12),

                const SizedBox(height: 24),

                // ── Infrastructure Heartbeat ─
                _InfraHeartbeatMap()
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 24),

                // ── Feature Stats ───────────
                Row(
                  children: [
                    _featureStat(ext, '< 50ms', 'Latency'),
                    const SizedBox(width: 10),
                    _featureStat(ext, '99.9%', 'Uptime'),
                    const SizedBox(width: 10),
                    _featureStat(ext, '3', 'Regions'),
                  ],
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureStat(AppThemeExtension ext, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: ext.textMuted)),
        ],
      ),
    );
  }
}

// ── Infrastructure Heartbeat ─────────────────────────────────────

class _InfraHeartbeatMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ext = context.ext;

    const nodes = [
      _InfraNode('📱', 'Your Device', 'Active', AppTheme.accentGreen),
      _InfraNode('⚡', 'FastAPI', '<50ms', AppTheme.accentCyan),
      _InfraNode('☁️', 'AWS Bedrock', 'Ready', AppTheme.accentPurple),
      _InfraNode('💾', 'DynamoDB', 'Synced', AppTheme.accentAmber),
    ];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INFRASTRUCTURE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ext.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Live',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                        )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < nodes.length; i++) ...[
              _nodeRow(context, nodes[i]),
              if (i < nodes.length - 1) _connector(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nodeRow(BuildContext context, _InfraNode node) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: node.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: node.color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(node.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(node.name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: node.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(node.status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: node.color)),
        ),
      ],
    );
  }

  Widget _connector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        width: 2,
        height: 20,
        color: context.ext.glassBorder,
      ),
    );
  }
}

class _InfraNode {
  final String emoji;
  final String name;
  final String status;
  final Color color;

  const _InfraNode(this.emoji, this.name, this.status, this.color);
}
