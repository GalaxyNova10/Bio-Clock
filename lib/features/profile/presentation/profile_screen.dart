import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/core/theme_provider.dart';
import '../../../shared/ui/glass_card.dart';

/// Profile screen — merged Agent + Profile + Settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = context.ext;
    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeProvider);

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
            title: const Text('Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => context.push('/about'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Avatar + Info ──────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.gradientPrimary,
                          boxShadow: AppTheme.neonGlow(AppTheme.accentGreen,
                              intensity: 0.3),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 14),
                      const Text('Guest User',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('demo@bioclock.app',
                          style: TextStyle(fontSize: 13, color: ext.textMuted)),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // ── Impact Dashboard ──────────
                Text(
                  'IMPACT DASHBOARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ext.textMuted,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _impactCard(context, Icons.eco, AppTheme.accentGreen,
                        '12.5kg', 'CO₂ Saved'),
                    const SizedBox(width: 10),
                    _impactCard(context, Icons.savings, AppTheme.accentAmber,
                        '₹3,450', 'Money Saved'),
                  ],
                ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _impactCard(context, Icons.qr_code_scanner,
                        AppTheme.accentCyan, '47', 'Items Scanned'),
                    const SizedBox(width: 10),
                    _impactCard(context, Icons.verified, AppTheme.accentPurple,
                        '85%', 'Accuracy'),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Achievements ───────────
                Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ext.textMuted,
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 12),

                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _badge(context, '🌱', 'First Scan'),
                      _badge(context, '🏆', '10 Scans'),
                      _badge(context, '♻️', 'Eco Hero'),
                      _badge(context, '🧠', 'AI Expert'),
                      _badge(context, '🥗', 'Zero Waste'),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Settings ──────────────
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ext.textMuted,
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 12),

                GlassCard(
                  child: Column(
                    children: [
                      _toggleRow(
                        context,
                        Icons.science_outlined,
                        'Demo Mode',
                        'Show dummy data for demonstration',
                        settings.demoMode,
                        (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setDemoMode(v),
                      ),
                      _divider(context),
                      _toggleRow(
                        context,
                        Icons.center_focus_strong,
                        'Auto-Scan',
                        'Automatically scan when produce detected',
                        settings.autoScan,
                        (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setAutoScan(v),
                      ),
                      _divider(context),
                      _toggleRow(
                        context,
                        Icons.notifications_outlined,
                        'Push Notifications',
                        'Get alerts when items are expiring',
                        settings.pushNotifications,
                        (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setPushNotifications(v),
                      ),
                      _divider(context),
                      _toggleRow(
                        context,
                        Icons.vibration,
                        'Haptic Feedback',
                        'Vibrate on scan completion',
                        settings.hapticFeedback,
                        (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setHapticFeedback(v),
                      ),
                      _divider(context),
                      _toggleRow(
                        context,
                        Icons.hd_outlined,
                        'HD Capture',
                        'Higher resolution for better accuracy',
                        settings.hdCapture,
                        (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setHdCapture(v),
                      ),
                      _divider(context),
                      _toggleRow(
                        context,
                        Icons.email_outlined,
                        'Email Reports',
                        'Weekly sustainability report',
                        settings.emailReports,
                        (v) => ref
                            .read(appSettingsProvider.notifier)
                            .setEmailReports(v),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 16),

                // Theme selector
                GlassCard(
                  child: Column(
                    children: [
                      _navRow(
                        context,
                        Icons.dark_mode_outlined,
                        'Dark Mode',
                        _themeModeLabel(themeMode),
                        () => _showThemeDialog(context, ref),
                      ),
                      _divider(context),
                      _navRow(
                        context,
                        Icons.language,
                        'Language',
                        settings.languageLabel,
                        () => _showLanguageDialog(context, ref),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                const SizedBox(height: 16),

                // Links
                GlassCard(
                  child: Column(
                    children: [
                      _navRow(context, Icons.info_outline, 'About Bio Clock',
                          '', () => context.push('/about')),
                      _divider(context),
                      _navRow(
                          context,
                          Icons.admin_panel_settings,
                          'Pitch Dashboard (Demo)',
                          '',
                          () => context.push('/pitch')),
                      _divider(context),
                      _navRow(context, Icons.privacy_tip_outlined,
                          'Privacy Policy', '', () {}),
                      _divider(context),
                      _navRow(context, Icons.description_outlined,
                          'Terms of Service', '', () {}),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                const SizedBox(height: 20),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.accentRed.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout,
                        color: AppTheme.accentRed, size: 18),
                    label: const Text('Logout',
                        style: TextStyle(
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.w600)),
                  ),
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactCard(BuildContext context, IconData icon, Color color,
      String value, String label) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    Text(label,
                        style: TextStyle(
                            fontSize: 10, color: context.ext.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String emoji, String label) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.ext.glassBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.ext.glassBorder),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: context.ext.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _toggleRow(BuildContext context, IconData icon, String title,
      String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.ext.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: context.ext.textMuted)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context, IconData icon, String title,
      String trailing, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.ext.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (trailing.isNotEmpty)
              Text(trailing,
                  style: TextStyle(fontSize: 12, color: context.ext.textMuted)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: context.ext.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 50,
      color: context.ext.glassBorder,
    );
  }

  String _themeModeLabel(AppThemeMode mode) => switch (mode) {
        AppThemeMode.dark => 'Dark',
        AppThemeMode.light => 'Light',
        _ => 'System',
      };

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).set(AppThemeMode.system);
              Navigator.pop(ctx);
            },
            child: const Text('System Default'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).set(AppThemeMode.light);
              Navigator.pop(ctx);
            },
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).set(AppThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: const Text('Dark'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final languages = {
      'en': 'English',
      'hi': 'Hindi',
      'ta': 'Tamil',
      'te': 'Telugu',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'mr': 'Marathi',
      'bn': 'Bengali',
      'gu': 'Gujarati',
      'pa': 'Punjabi',
      'or': 'Odia',
    };
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Language'),
        children: languages.entries
            .map((e) => SimpleDialogOption(
                  onPressed: () {
                    ref.read(appSettingsProvider.notifier).setLanguage(e.key);
                    Navigator.pop(ctx);
                  },
                  child: Text(e.value),
                ))
            .toList(),
      ),
    );
  }
}
