import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/core/theme_provider.dart';
import '../../../shared/core/aws_config.dart';
import '../../../shared/data/api_client.dart';
import '../../../shared/data/auth_provider.dart';
import '../../../shared/data/inventory_provider.dart';
import '../../../shared/ui/glass_card.dart';

/// Profile screen — merged Agent + Profile + Settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  String _name = 'Guest User';
  String _email = 'demo@bioclock.app';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    // Immediately sync name from auth state (pre-emptively decoded)
    final authState = ref.read(authProvider);
    _name = authState.displayName;
    _email = authState.email ?? 'demo@bioclock.app';

    if (AwsConfig.useCloudBackend) {
      if (mounted) setState(() => _isLoadingStats = true);
      try {
        final api = ref.read(apiClientProvider);
        final stats = await api.fetchProfileStats();
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoadingStats = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingStats = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      // Reactive name: watch authProvider for live updates
                      Builder(builder: (context) {
                        final authState = ref.watch(authProvider);
                        final resolvedName = authState.displayName;
                        // Shimmer placeholder while name is still initializing
                        if (resolvedName == 'Guest User' && authState.isAuthenticated) {
                          return Container(
                            width: 120,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ).animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.15));
                        }
                        return Text(resolvedName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800));
                      }),
                      const SizedBox(height: 4),
                      Text(ref.watch(authProvider).email ?? _email,
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
                        _isLoadingStats ? 'Sync...' : (_stats != null ? '${_stats!['co2Saved'] ?? '0'}kg' : '12.5kg'), 'CO₂ Saved'),
                    const SizedBox(width: 10),
                    _impactCard(context, Icons.savings, AppTheme.accentAmber,
                        _isLoadingStats ? 'Sync...' : (_stats != null ? '₹${_stats!['moneySaved'] ?? '0'}' : '₹3,450'), 'Money Saved'),
                  ],
                ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _impactCard(context, Icons.qr_code_scanner, AppTheme.accentCyan,
                        _isLoadingStats ? 'Sync...' : (_stats != null ? '${_stats!['scans'] ?? '0'}' : '47'), 'Items Scanned'),
                    const SizedBox(width: 10),
                    _impactCard(context, Icons.verified, AppTheme.accentPurple,
                        _isLoadingStats ? 'Sync...' : (_stats != null ? '${_stats!['accuracy'] ?? '0'}%' : '85%'), 'Accuracy'),
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
                      _badge(context, '🌱', 'First Scan', unlocksAt: 1),
                      _badge(context, '🏆', '10 Scans', unlocksAt: 10),
                      _badge(context, '♻️', 'Eco Hero', unlocksAt: 50),
                      _badge(context, '🧠', 'AI Expert', unlocksAt: 100),
                      _badge(context, '🥗', 'Zero Waste', unlocksAt: 200),
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
                        Icons.dashboard_customize_outlined, // Updated icon
                        'Demo Mode',
                        'Fills inventory with simulated items', // Updated description
                        settings.demoMode,
                        (val) { // Updated onChange handler
                          ref.read(appSettingsProvider.notifier).setDemoMode(val);
                          if (!val) {
                            try {
                              ref.read(inventoryProvider.notifier).fetchFromCloud();
                            } catch (e) {
                              debugPrint('Error refreshing inventory: \$e');
                            }
                          }
                        },
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
                        Icons.palette_outlined,
                        'Theme',
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

                const SizedBox(height: 140),
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

  Widget _badge(BuildContext context, String emoji, String label, {int unlocksAt = 1}) {
    final int currentScans = _stats != null ? ((_stats!['scans'] as num?)?.toInt() ?? 0) : 47;
    final bool isUnlocked = currentScans >= unlocksAt;

    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.ext.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? context.ext.glassBorder : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji,
              style: TextStyle(
                fontSize: 28,
                color: isUnlocked ? null : Colors.grey.withOpacity(0.2), // Grayscale simulation for emoji
              )),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? context.ext.textMuted : context.ext.textMuted.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
          ),
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
