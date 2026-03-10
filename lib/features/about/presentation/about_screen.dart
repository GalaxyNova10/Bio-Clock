import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/ui/glass_card.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

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
            title: const Text('About',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── App Card ────────────
                GlassCard(
                  gradientBorder: true,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.gradientPrimary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.neonGlow(AppTheme.accentGreen,
                                intensity: 0.4),
                          ),
                          child: const Icon(Icons.eco,
                              color: Colors.black, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text('Bio-Clock Pulse',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: ext.glassBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('v1.0.0 · Flutter',
                              style: TextStyle(
                                  fontSize: 12, color: ext.textMuted)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bio-Clock utilizes a hybrid Neuro-Symbolic architecture, leveraging AWS SAM for rapid deployment and a high-availability dual-model pipeline for 99.9% inference uptime.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ext.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 28),

                _sectionLabel(context, 'Architecture'),
                const SizedBox(height: 14),
                _buildArchFlow(context)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 28),

                _sectionLabel(context, 'Technology Stack'),
                const SizedBox(height: 14),
                ..._techItems.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildTechCard(context, e.value)
                          .animate()
                          .fadeIn(
                              delay: (350 + e.key * 80).ms, duration: 400.ms)
                          .slideX(begin: 0.08),
                    )),

                const SizedBox(height: 28),

                _sectionLabel(context, 'Credits'),
                const SizedBox(height: 14),
                _buildCredits(context)
                    .animate()
                    .fadeIn(delay: 750.ms, duration: 500.ms),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.ext.textMuted,
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  static const _techItems = [
    _TechItem('Flutter', 'Cross-platform UI framework', Icons.phone_android,
        AppTheme.accentCyan),
    _TechItem('FastAPI', 'High-performance Python backend', Icons.speed,
        AppTheme.accentGreen),
    _TechItem('AI Engine', 'Neuro-symbolic reasoning model', Icons.psychology,
        AppTheme.accentPurple),
    _TechItem('Cloud DB', 'Serverless NoSQL database', Icons.storage,
        AppTheme.accentAmber),
    _TechItem('Cloud Storage', 'Object storage for images', Icons.cloud,
        AppTheme.accentCyan),
  ];

  Widget _buildTechCard(BuildContext context, _TechItem item) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.description,
                      style: TextStyle(
                          fontSize: 11, color: context.ext.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchFlow(BuildContext context) {
    const nodes = [
      _ArchNode('📱', 'Device', 'Camera + UI', AppTheme.accentGreen),
      _ArchNode('⚡', 'API Layer', 'Orchestration', AppTheme.accentCyan),
      _ArchNode('🧠', 'AI Engine', 'Freshness Model', AppTheme.accentPurple),
      _ArchNode('💾', 'Database', 'Persistence', AppTheme.accentAmber),
    ];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (int i = 0; i < nodes.length; i++) ...[
              _archNodeWidget(context, nodes[i]),
              if (i < nodes.length - 1) _archConnector(context, nodes[i].color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _archNodeWidget(BuildContext context, _ArchNode node) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: node.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: node.color.withValues(alpha: 0.25)),
          ),
          child: Center(
              child: Text(node.emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(node.desc,
                  style: TextStyle(fontSize: 11, color: context.ext.textMuted)),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: node.color,
            boxShadow: [
              BoxShadow(
                  color: node.color.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _archConnector(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.4),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredits(BuildContext context) {
    final ext = context.ext;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _creditRow(context, 'Developed for', 'AI for Bharat'),
            Divider(color: ext.glassBorder, height: 24),
            _creditRow(context, 'Architecture', 'Q10 Spoilage Model'),
            Divider(color: ext.glassBorder, height: 24),
            _creditRow(context, 'AI Models', 'Neuro-Symbolic Engine'),
            Divider(color: ext.glassBorder, height: 24),
            _creditRow(context, 'Frontend', 'Flutter + Riverpod'),
          ],
        ),
      ),
    );
  }

  Widget _creditRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: context.ext.textMuted, fontSize: 13)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class _TechItem {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  const _TechItem(this.name, this.description, this.icon, this.color);
}

class _ArchNode {
  final String emoji;
  final String name;
  final String desc;
  final Color color;
  const _ArchNode(this.emoji, this.name, this.desc, this.color);
}
