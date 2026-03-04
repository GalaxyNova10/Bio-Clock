import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/core/theme_provider.dart';
import '../../../shared/ui/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings,
                      color: AppTheme.accentPurple, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Settings',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Appearance ────────────────────────────
                _sectionLabel(context, 'Appearance')
                    .animate()
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 12),
                _themeSelector(context, ref, currentTheme)
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 500.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 28),

                // ── Scanning ─────────────────────────────
                _sectionLabel(context, 'Scanning')
                    .animate()
                    .fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                _settingsCard(context, [
                  _toggleRow(
                    context: context,
                    icon: Icons.camera_alt_outlined,
                    title: 'Auto-Scan',
                    subtitle: 'Auto-capture when produce detected',
                    value: false,
                    onChanged: (_) {},
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  _toggleRow(
                    context: context,
                    icon: Icons.high_quality_outlined,
                    title: 'HD Capture',
                    subtitle: 'Use highest resolution for analysis',
                    value: true,
                    onChanged: (_) {},
                  ),
                ])
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 500.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 28),

                // ── Bio-Agent / AWS Alert System ────────────────────────
                _sectionLabel(context, 'Bio-Agent Integration')
                    .animate()
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                _settingsCard(context, [
                  _toggleRow(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Autonomous Bio-Guardian',
                    subtitle: 'Enable Amazon SNS push alerts',
                    value: true,
                    onChanged: (_) {},
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  _toggleRow(
                    context: context,
                    icon: Icons.cloud_sync_outlined,
                    title: 'Bedrock Logging',
                    subtitle: 'Stream analysis logs to CloudWatch',
                    value: false,
                    onChanged: (_) {},
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alert Threshold (Remaining Useful Life)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Alert when items drop below 6 hours RUL.',
                            style:
                                TextStyle(fontSize: 11, color: ext.textMuted)),
                        const SizedBox(height: 8),
                        Slider(
                          value: 6.0,
                          min: 1.0,
                          max: 24.0,
                          divisions: 23,
                          label: '6 hrs',
                          onChanged: (v) {},
                        ),
                      ],
                    ),
                  ),
                ])
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 28),

                // ── Data & Privacy ───────────────────────
                _sectionLabel(context, 'Data & Privacy')
                    .animate()
                    .fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                _settingsCard(context, [
                  _toggleRow(
                    context: context,
                    icon: Icons.science_outlined,
                    title: 'Demo Mode',
                    subtitle: 'Use mock data instead of live API',
                    value: true,
                    onChanged: (_) {},
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  _navRow(
                    context: context,
                    icon: Icons.storage_outlined,
                    title: 'Clear Cache',
                    subtitle: '24 MB cached',
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  _navRow(
                    context: context,
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete all data',
                    color: AppTheme.accentRed,
                  ),
                ])
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 500.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 28),

                // ── About section ────────────────────────
                _sectionLabel(context, 'About').animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 12),
                _settingsCard(context, [
                  _navRow(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'About Bio-Clock Pulse',
                    subtitle: 'v1.0.0 · Flutter',
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  _navRow(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: '',
                  ),
                  Divider(color: ext.glassBorder, height: 1, indent: 56),
                  _navRow(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    subtitle: '',
                  ),
                ]).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Theme Selector ────────────────────────────────────────────

  Widget _themeSelector(
      BuildContext context, WidgetRef ref, AppThemeMode current) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined,
                    color: context.ext.textMuted, size: 20),
                const SizedBox(width: 12),
                const Text('Theme',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _themeOption(context, ref, AppThemeMode.system, 'System',
                    Icons.settings_brightness, current),
                const SizedBox(width: 10),
                _themeOption(context, ref, AppThemeMode.light, 'Light',
                    Icons.light_mode, current),
                const SizedBox(width: 10),
                _themeOption(context, ref, AppThemeMode.dark, 'Dark',
                    Icons.dark_mode, current),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, WidgetRef ref, AppThemeMode mode,
      String label, IconData icon, AppThemeMode current) {
    final isSelected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).set(mode),
        child: AnimatedContainer(
          duration: AppTheme.durationNormal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentGreen.withValues(alpha: 0.12)
                : context.ext.glassBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGreen.withValues(alpha: 0.4)
                  : context.ext.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected
                      ? AppTheme.accentGreen
                      : context.ext.textMuted),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.accentGreen
                      : context.ext.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.ext.textMuted,
      ),
    );
  }

  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
  }

  Widget _toggleRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: context.ext.textMuted, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: context.ext.textMuted)),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.accentGreen;
              }
              return context.ext.textMuted;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.accentGreen.withValues(alpha: 0.3);
              }
              return context.ext.glassBackground;
            }),
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? context.ext.textMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      )),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11, color: context.ext.textMuted)),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: context.ext.textMuted),
          ],
        ),
      ),
    );
  }
}
