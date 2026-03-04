import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/data/inventory_provider.dart';
import '../../../shared/data/weather_service.dart';
import '../../../shared/core/time_utils.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/produce_emoji.dart';

/// The scan experience — loading → reticle → scanner → storage → results.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

enum ScanPhase { loading, scanning, storageSelect, analyzing, result }

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  ScanPhase _phase = ScanPhase.loading;
  late AnimationController _reticleController;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  String _selectedStorage = 'fridge';
  bool _showWork = false;

  // Mock result data
  String _resultStatus = 'fresh';
  int _resultConfidence = 87;
  String _resultName = 'Tomato';
  int _resultRul = 42;

  @override
  void initState() {
    super.initState();
    _reticleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Start the loading phase
    _startLoading();
  }

  void _startLoading() async {
    setState(() => _phase = ScanPhase.loading);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final settings = ref.read(appSettingsProvider);
    _reticleController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    _scanLineController.repeat();
    setState(() => _phase = ScanPhase.scanning);

    if (settings.autoScan) {
      // Auto-scan after 2 seconds
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) _onScanComplete();
    }
  }

  void _onScanComplete() async {
    if (settings.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    _scanLineController.stop();
    setState(() => _phase = ScanPhase.storageSelect);
  }

  AppSettings get settings => ref.read(appSettingsProvider);

  void _onStorageSelected(String storage) async {
    setState(() {
      _selectedStorage = storage;
      _phase = ScanPhase.analyzing;
    });

    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Simulate analysis
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Generate mock result based on storage
    final random = math.Random();
    final statuses = ['fresh', 'ripening', 'soon_rotten', 'rotten'];
    final names = [
      'Tomato',
      'Spinach',
      'Banana',
      'Apple',
      'Mango',
      'Bell Pepper',
      'Cucumber',
      'Carrot'
    ];
    _resultName = names[random.nextInt(names.length)];
    _resultConfidence = 82 + random.nextInt(16); // 82-97%

    // Storage affects the result
    if (storage == 'freezer') {
      _resultStatus = 'fresh';
      _resultRul = (120 + random.nextInt(80)) * 60;
    } else if (storage == 'fridge') {
      _resultStatus = random.nextBool() ? 'fresh' : 'ripening';
      _resultRul = (24 + random.nextInt(72)) * 60;
    } else {
      _resultStatus = statuses[random.nextInt(3)]; // not rotten often at room
      _resultRul = (6 + random.nextInt(36)) * 60;
    }

    // Add to inventory
    ref.read(inventoryProvider.notifier).addItem(ProduceItem(
          id: 's${DateTime.now().millisecondsSinceEpoch}',
          name: _resultName,
          rul: _resultRul,
          status: _resultStatus,
          icon: Icons.eco,
          iconColor: _statusColor(_resultStatus),
          emoji: ProduceEmoji.getEmoji(_resultName),
          storage: _selectedStorage,
          addedAt: DateTime.now(),
        ));

    setState(() => _phase = ScanPhase.result);
  }

  Color _statusColor(String status) => switch (status) {
        'fresh' => AppTheme.accentGreen,
        'ripening' => AppTheme.accentAmber,
        'soon_rotten' => const Color(0xFFF97316),
        'rotten' => AppTheme.accentRed,
        _ => AppTheme.accentCyan,
      };

  String _statusLabel(String status) => switch (status) {
        'fresh' => 'Fresh',
        'ripening' => 'Ripening',
        'soon_rotten' => 'Soon to Expire',
        'rotten' => 'Rotten',
        _ => 'Unknown',
      };

  IconData _statusIcon(String status) => switch (status) {
        'fresh' => Icons.check_circle,
        'ripening' => Icons.warning_amber_rounded,
        'soon_rotten' => Icons.error_outline,
        'rotten' => Icons.dangerous,
        _ => Icons.help_outline,
      };

  void _resetScan() {
    _reticleController.reset();
    _scanLineController.reset();
    _showWork = false;
    _startLoading();
  }

  @override
  void dispose() {
    _reticleController.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _phase == ScanPhase.result
          ? null
          : AppBar(
              backgroundColor: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: 0.92),
              surfaceTintColor: Colors.transparent,
              title: const Text('Scan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_phase) {
          ScanPhase.loading => _buildLoadingPhase(),
          ScanPhase.scanning => _buildScanningPhase(),
          ScanPhase.storageSelect => _buildStorageSelect(),
          ScanPhase.analyzing => _buildAnalyzing(),
          ScanPhase.result => _buildResult(),
        },
      ),
    );
  }

  // ── Phase 1: Loading ──────────────────────────────────
  Widget _buildLoadingPhase() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rectangular frame with "Initializing Bio-Clock AI"
          Container(
            width: 280,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.accentGreen,
                    backgroundColor:
                        AppTheme.accentGreen.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Initializing Bio-Clock AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentGreen.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparing scanner...',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.ext.textMuted,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  // ── Phase 2: Scanning with expanding reticle ──────────
  Widget _buildScanningPhase() {
    final autoScan = ref.watch(appSettingsProvider).autoScan;

    return Center(
      key: const ValueKey('scanning'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera view with reticle
          SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dark camera background
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Expanding reticle — 4 corner brackets that expand
                AnimatedBuilder(
                  animation: _reticleController,
                  builder: (context, _) {
                    final expand = _reticleController.value;
                    final size = 120.0 + expand * 80.0;
                    return SizedBox(
                      width: size,
                      height: size,
                      child: CustomPaint(
                        painter: _ReticlePainter(
                          color: AppTheme.accentGreen
                              .withValues(alpha: 0.7 + expand * 0.3),
                          strokeWidth: 3,
                          gap: expand * 0.4,
                        ),
                      ),
                    );
                  },
                ),

                // Scan line
                AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (context, _) {
                    return Positioned(
                      top: 40 + _scanLineController.value * 220,
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.accentGreen.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.accentGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.center_focus_strong_outlined,
                      size: 36,
                      color: context.ext.textMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      autoScan
                          ? 'Point at produce...'
                          : 'Position produce in frame',
                      style: TextStyle(
                        color: context.ext.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // Start Scan button — only shown if auto-scan is OFF
          if (!autoScan)
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.gradientPrimary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow:
                    AppTheme.neonGlow(AppTheme.accentGreen, intensity: 0.3),
              ),
              child: ElevatedButton.icon(
                onPressed: _onScanComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                icon: const Icon(Icons.camera, size: 18, color: Colors.white),
                label: const Text('Start Scan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

          const SizedBox(height: 14),

          // Info bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.ext.surfaceDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: context.ext.textMuted),
                const SizedBox(width: 8),
                Text(
                  autoScan
                      ? 'Auto-scan at 85% confidence'
                      : 'Tap Start Scan when ready',
                  style: TextStyle(fontSize: 12, color: context.ext.textMuted),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  // ── Phase 3: Storage selection ────────────────────────
  Widget _buildStorageSelect() {
    return Padding(
      key: const ValueKey('storage'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 48, color: AppTheme.accentGreen)
              .animate()
              .fadeIn()
              .scale(begin: const Offset(0.5, 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Produce Captured!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'How was this stored?',
            style: TextStyle(fontSize: 14, color: context.ext.textMuted),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),

          // Storage options
          Row(
            children: [
              _storageOption(
                context,
                '🧊',
                'Freezer',
                'freezer',
                'Below 0°C',
              ),
              const SizedBox(width: 12),
              _storageOption(
                context,
                '❄️',
                'Fridge',
                'fridge',
                '2-8°C',
              ),
              const SizedBox(width: 12),
              _storageOption(
                context,
                '🧺',
                'Room Temp',
                'room',
                '20-35°C',
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _storageOption(
    BuildContext context,
    String emoji,
    String label,
    String value,
    String temp,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onStorageSelected(value),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(temp,
                    style:
                        TextStyle(fontSize: 11, color: context.ext.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Phase 4: Analyzing ────────────────────────────────
  Widget _buildAnalyzing() {
    return Center(
      key: const ValueKey('analyzing'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing orb
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 80 + _pulseController.value * 20,
                height: 80 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen
                      .withValues(alpha: 0.1 + _pulseController.value * 0.1),
                  border: Border.all(
                    color: AppTheme.accentGreen
                        .withValues(alpha: 0.3 + _pulseController.value * 0.2),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.eco, color: AppTheme.accentGreen, size: 36),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Running AI freshness analysis',
            style: TextStyle(fontSize: 13, color: context.ext.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Phase 5: Full-page result ─────────────────────────
  Widget _buildResult() {
    final color = _statusColor(_resultStatus);
    final temp = WeatherService.getCurrentTemperature();
    final humidity = WeatherService.getCurrentHumidity();

    return Scaffold(
      key: const ValueKey('result'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        title: const Text('Scan Result',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _resetScan,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Status Ring ────────
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_statusIcon(_resultStatus), color: color, size: 40),
                  const SizedBox(height: 6),
                  Text(
                    _statusLabel(_resultStatus),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 20),

            Text(
              _resultName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 6),

            Text(
              '$_resultConfidence% confidence',
              style: TextStyle(fontSize: 14, color: context.ext.textMuted),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 20),

            // Confidence bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _resultConfidence / 100,
                minHeight: 8,
                backgroundColor: context.ext.glassBackground,
                color: color,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // ── RUL & Environment ──
            Row(
              children: [
                _metricTile(TimeUtils.formatMinutes(_resultRul), 'RUL', color),
                const SizedBox(width: 10),
                _metricTile('${temp.toStringAsFixed(1)}°C', 'Temp',
                    AppTheme.accentAmber),
                const SizedBox(width: 10),
                _metricTile('${humidity.toStringAsFixed(0)}%', 'Humidity',
                    AppTheme.accentCyan),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 8),

            // Location tag
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: context.ext.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${WeatherService.getCityName()} · Live',
                  style: TextStyle(fontSize: 11, color: context.ext.textMuted),
                ),
              ],
            ).animate().fadeIn(delay: 550.ms),

            const SizedBox(height: 20),

            // ── Show Your Work ──
            GlassCard(
              onTap: () => setState(() => _showWork = !_showWork),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _showWork ? Icons.expand_less : Icons.expand_more,
                          color: context.ext.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('Show Your Work',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.ext.textSecondary)),
                      ],
                    ),
                    if (_showWork) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Model: Neuro-Symbolic AI Engine\n'
                        'Features: color_uniformity=0.92, texture_score=0.87\n'
                        'Q10 Factor: 1.41× at ${temp.toStringAsFixed(0)}°C\n'
                        'Storage: ${_selectedStorage.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.ext.textSecondary,
                          height: 1.6,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 20),

            // ── Preservation Techniques ──
            Text(
              'PRESERVATION GUIDE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.ext.textMuted,
              ),
            ).animate().fadeIn(delay: 650.ms),
            const SizedBox(height: 12),

            _preservationCard(
              context,
              'Fresh',
              'Store in airtight container in the fridge at 2-4°C. Keep away from ethylene-producing fruits.',
              AppTheme.accentGreen,
              Icons.check_circle,
            ),
            const SizedBox(height: 8),
            _preservationCard(
              context,
              'Ripening',
              'Consume within 24-48 hours. Move to fridge if at room temperature. Great for cooking now.',
              AppTheme.accentAmber,
              Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 8),
            _preservationCard(
              context,
              'Soon to Expire',
              'Trim any affected edges and consume immediately. Can be used in smoothies or cooked dishes within 2 hours.',
              const Color(0xFFF97316),
              Icons.error_outline,
            ),
            const SizedBox(height: 8),
            _preservationCard(
              context,
              'Rotten',
              '⚠️ Unsafe for consumption. Discard immediately. Do not attempt to trim and eat — bacterial contamination may have spread.',
              AppTheme.accentRed,
              Icons.dangerous,
            ),

            const SizedBox(height: 24),

            // Scan Again button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetScan,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner,
                    color: AppTheme.accentGreen, size: 18),
                label: const Text('Scan Another',
                    style: TextStyle(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ext.glassBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: context.ext.glassBorder),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: context.ext.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _preservationCard(
    BuildContext context,
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.ext.textSecondary,
                        height: 1.4,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the expanding reticle frame — breaks at midpoints and expands.
class _ReticlePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap; // 0 = closed, 1 = fully expanded gaps

  _ReticlePainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cornerLen = w * 0.25;
    final midGap = gap * w * 0.15; // gap at midpoints

    // Top-left corner
    canvas.drawLine(Offset(0, cornerLen), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerLen, 0), paint);

    // Top-right corner
    canvas.drawLine(Offset(w - cornerLen, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, h - cornerLen), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(w, h - cornerLen), Offset(w, h), paint);
    canvas.drawLine(Offset(w - cornerLen, h), Offset(w, h), paint);

    // Midpoint accents (the "break" effect)
    if (gap > 0.1) {
      final midPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final mx = w / 2;
      final my = h / 2;

      // Top mid
      canvas.drawLine(Offset(mx - midGap, 0), Offset(mx + midGap, 0), midPaint);
      // Bottom mid
      canvas.drawLine(Offset(mx - midGap, h), Offset(mx + midGap, h), midPaint);
      // Left mid
      canvas.drawLine(Offset(0, my - midGap), Offset(0, my + midGap), midPaint);
      // Right mid
      canvas.drawLine(Offset(w, my - midGap), Offset(w, my + midGap), midPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) =>
      oldDelegate.gap != gap || oldDelegate.color != color;
}
