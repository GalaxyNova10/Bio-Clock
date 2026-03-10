import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/core/app_settings_provider.dart';
import '../../../shared/data/inventory_provider.dart';
import '../../../shared/data/weather_service.dart';
import '../../../shared/core/time_utils.dart';
import '../../../shared/core/aws_config.dart';
import '../../../shared/data/api_client.dart';
import '../../../shared/data/auth_provider.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/produce_emoji.dart';
import '../../../shared/data/local_ml_service.dart';

/// The scan experience — loading → reticle → scanner → storage → results.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

enum ScanPhase { loading, scanning, storageSelect, analyzing, result }
enum AnalysisModel { novaPro, shelfSenseAI }


class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  ScanPhase _phase = ScanPhase.loading;
  late AnimationController _reticleController;
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  String _selectedStorage = 'fridge';
  bool _showWork = false;
  bool _scanFailed = false;
  bool _isNameConfirmed = false;
  bool _isAnalyzing = false;
  final TextEditingController _produceNameController = TextEditingController();
  
  AnalysisModel _selectedModel = AnalysisModel.novaPro;
  String _activeModelUsed = '';
  final LocalMLService _localMLService = LocalMLService();

  // Real Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _cameraPermissionDenied = false;

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
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Try for front camera on Web, default back on mobile
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraPermissionDenied = false;
        });
      }
    } catch (e) {
      debugPrint('Camera init failed: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraPermissionDenied = true;
        });
      }
    }
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
    
    // Capture real image
    XFile? image;
    if (_isCameraInitialized && _cameraController != null) {
      try {
        image = await _cameraController!.takePicture();
      } catch (e) {
        debugPrint('Capture failed: $e');
      }
    }

    _scanLineController.stop();
    setState(() {
      _phase = ScanPhase.storageSelect;
      _capturedImage = image;
    });
  }

  XFile? _capturedImage;

  AppSettings get settings => ref.read(appSettingsProvider);

  void _onStorageSelected(String storage) async {
    // Debounce / State Lock
    if (_isAnalyzing) return;

    setState(() {
      _selectedStorage = storage;
      _isAnalyzing = true;
      _scanFailed = false;
    });

    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (AwsConfig.useCloudBackend) {
      // Extract raw sub from the auth token for S3 key partitioning
      final authState = ref.read(authProvider);
      String? userSub;
      if (authState.idToken != null) {
        try {
          final parts = authState.idToken!.split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            final map = jsonDecode(payload) as Map<String, dynamic>;
            userSub = map['sub'] as String?;
          }
        } catch (_) {}
      }
      final imageBytes = _capturedImage != null ? await _capturedImage!.readAsBytes() : Uint8List(0);
      final overrideName = _produceNameController.text.isEmpty ? 'Biological Sample' : _produceNameController.text;

      Map<String, dynamic>? scanResult;

      // 1. Attempt Nova Pro (Cloud) if selected
      if (_selectedModel == AnalysisModel.novaPro) {
        try {
          final api = ref.read(apiClientProvider);
          scanResult = await api.scanProduce(
            imageBytes,
            userId: userSub,
            overrideName: overrideName,
          ).timeout(const Duration(seconds: 5));
          
          _activeModelUsed = 'novaPro';

          // Fetch preservation tip eagerly if cloud succeeded
          try {
            final apiName = scanResult['name'] as String? ?? 'Unknown';
            final fetchName = _produceNameController.text.isNotEmpty ? _produceNameController.text : apiName;
            await api.getPreservationTip(fetchName, scanResult['status'] ?? 'fresh', _selectedStorage);
          } catch (_) {}

        } catch (e) {
          debugPrint('Nova Pro API failed or timed out: $e. Failing over to ShelfSense AI.');
          // scanResult remains null, triggers failover below
        }
      }

      // 2. ShelfSense AI (Edge) execution or failover
      if (scanResult == null || _selectedModel == AnalysisModel.shelfSenseAI) {
         try {
           scanResult = await _localMLService.analyzeImage(_capturedImage, overrideName);
           _activeModelUsed = 'shelfSenseAI';
         } catch (e) {
            debugPrint('ShelfSense AI failed: $e');
            if (mounted) {
              setState(() {
                _scanFailed = true;
                _isAnalyzing = false;
              });
              return;
            }
         }
      }
      
      if (scanResult != null) {
        final apiName = scanResult['name'] as String? ?? 'Unknown';
        _resultName = (_produceNameController.text.isNotEmpty)
            ? _produceNameController.text
            : (apiName == 'Unknown' ? 'Biological Sample' : apiName);

        _resultStatus = scanResult['status'] as String? ?? 'fresh';
        _resultConfidence = (scanResult['confidence'] as num?)?.toInt() ?? 85;
        _resultRul = (scanResult['rul'] as num?)?.toInt() ?? 2880;
      }

    } else {

      // ── Mock Logic ──
      await Future.delayed(const Duration(milliseconds: 1500));
      _generateMockResult(storage);
    }

    if (!mounted) return;

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

    // Auto-refresh inventory from cloud after scan
    if (AwsConfig.useCloudBackend) {
      ref.read(inventoryProvider.notifier).fetchFromCloud();
    }

    setState(() {
      _isAnalyzing = false;
      _phase = ScanPhase.result;
    });
  }

  void _generateMockResult(String storage) {
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
    _scanFailed = false;
    _isNameConfirmed = false;
    _isAnalyzing = false;
    _produceNameController.clear();
    _startLoading();
  }

  @override
  void dispose() {
    _reticleController.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    _produceNameController.dispose();
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
        child: _scanFailed
            ? _buildManualEntry()
            : switch (_phase) {
                ScanPhase.loading => _buildLoadingPhase(),
                ScanPhase.scanning => _buildScanningPhase(),
                ScanPhase.storageSelect || ScanPhase.analyzing => _buildStorageSelect(),
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

    return LayoutBuilder(
      key: const ValueKey('scanning'),
      builder: (context, constraints) {
        final double screenHeight = constraints.maxHeight;
        final bool isSmallHeight = screenHeight < 600;

        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: isSmallHeight ? 12 : 24,
            horizontal: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dual-Model Toggle
              Padding(
                padding: EdgeInsets.only(bottom: isSmallHeight ? 12 : 24),
                child: CupertinoSlidingSegmentedControl<AnalysisModel>(
                  groupValue: _selectedModel,
                  backgroundColor: context.ext.glassBackground,
                  thumbColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                  children: {
                    AnalysisModel.novaPro: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'Amazon Nova Pro (Cloud)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedModel == AnalysisModel.novaPro ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedModel == AnalysisModel.novaPro ? AppTheme.accentGreen : context.ext.textMuted,
                        ),
                      ),
                    ),
                    AnalysisModel.shelfSenseAI: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        'ShelfSense AI (Edge)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedModel == AnalysisModel.shelfSenseAI ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedModel == AnalysisModel.shelfSenseAI ? AppTheme.accentGreen : context.ext.textMuted,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (AnalysisModel? value) {
                    if (value != null) {
                      setState(() {
                        _selectedModel = value;
                      });
                      if (settings.hapticFeedback) {
                        HapticFeedback.selectionClick();
                      }
                    }
                  },
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),

              // Camera view with reticle - Expanded to take remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 340,
                      height: 340,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Camera preview or fallback
                          Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _cameraPermissionDenied
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                                        const SizedBox(height: 12),
                                        const Text('Camera Blocked', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: _initCamera,
                                          child: const Text('Grant Permissions', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  )
                                : (_isCameraInitialized && _cameraController != null)
                                    ? CameraPreview(_cameraController!)
                                    : const Center(child: CircularProgressIndicator()),
                          ),

                          // Expanding reticle
                          AnimatedBuilder(
                            animation: _reticleController,
                            builder: (context, _) {
                              final expand = _reticleController.value;
                              final size = 120 + expand * 80;
                              return SizedBox(
                                width: size,
                                height: size,
                                child: CustomPaint(
                                  painter: _ReticlePainter(
                                    color: AppTheme.accentGreen.withValues(alpha: 0.7 + expand * 0.3),
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
                                top: 40 + _scanLineController.value * 240,
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
                                        color: AppTheme.accentGreen.withValues(alpha: 0.3),
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
                                size: 40,
                                color: context.ext.textMuted,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                autoScan ? 'Point at produce...' : 'Position produce in frame',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.ext.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 16),

              // Bottom Section: Start Scan button & Info bar
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!autoScan)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.gradientPrimary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: AppTheme.neonGlow(AppTheme.accentGreen, intensity: 0.3),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _onScanComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                          ),
                          icon: const Icon(Icons.camera, size: 18, color: Colors.white),
                          label: const Text('Start Scan',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                  // Info bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.ext.surfaceDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: context.ext.textMuted),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            autoScan ? 'Auto-scan at 85% confidence' : 'Tap Start Scan when ready',
                            style: TextStyle(fontSize: 11, color: context.ext.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Phase 3: Storage selection & Identification ────────
  Widget _buildStorageSelect() {
    return LayoutBuilder(
      key: const ValueKey('storage'),
      builder: (context, constraints) {
        final double screenHeight = constraints.maxHeight;
        final bool isSmallHeight = screenHeight < 600;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 
            isSmallHeight ? 12 : 32, 
            24, 
            isSmallHeight ? 12 : 24
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Header Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle, 
                    size: isSmallHeight ? 36 : 48, 
                    color: AppTheme.accentGreen
                  )
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.5, 0.5)),
                  SizedBox(height: isSmallHeight ? 8 : 16),
                  Text(
                    'Produce Captured!',
                    style: TextStyle(
                      fontSize: isSmallHeight ? 18 : 22, 
                      fontWeight: FontWeight.w800
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),

              // Middle Section: Identification & Storage Options
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isSmallHeight ? 8 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mandatory Produce Identification
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _produceNameController,
                                onChanged: (v) {
                                  if (_isNameConfirmed) {
                                    setState(() => _isNameConfirmed = false);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Identify Produce Name',
                                  hintStyle: TextStyle(color: context.ext.textMuted, fontSize: 14),
                                  prefixIcon: const Icon(Icons.eco_outlined, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNameConfirmed ? Icons.check_circle : Icons.check_circle_outline,
                                      color: _isNameConfirmed ? AppTheme.accentGreen : context.ext.textMuted,
                                    ),
                                    onPressed: () {
                                      if (_produceNameController.text.isEmpty) return;
                                      setState(() => _isNameConfirmed = true);
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isNameConfirmed 
                                          ? AppTheme.accentGreen 
                                          : context.ext.glassBorder,
                                      width: _isNameConfirmed ? 2 : 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _isNameConfirmed 
                                          ? AppTheme.accentGreen 
                                          : context.ext.glassBorder,
                                      width: _isNameConfirmed ? 2 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.accentGreen, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              if (_isNameConfirmed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, size: 14, color: AppTheme.accentGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Produce Identified',
                                        style: TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.accentGreen.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().slideY(begin: -0.2),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      SizedBox(height: isSmallHeight ? 12 : 24),

                      // Storage options with responsive scaling
                      FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: constraints.maxWidth - 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: _isNameConfirmed ? 1.0 : 0.4,
                                child: AbsorbPointer(
                                  absorbing: !_isNameConfirmed || _isAnalyzing,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  ),
                                ),
                              ),
                              if (_isAnalyzing)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    color: Colors.black.withValues(alpha: 0.4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Reasoning with Nova Pro...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),

              // Bottom Instruction
              if (!_isNameConfirmed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Please identify produce to select storage',
                    style: TextStyle(fontSize: 12, color: context.ext.textMuted),
                  ),
                ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        );
      },
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

    return LayoutBuilder(
      key: const ValueKey('result'),
      builder: (context, constraints) {
        final double screenHeight = constraints.maxHeight;
        final bool isSmallHeight = screenHeight < 600;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            title: const Text('Scan Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _resetScan,
            ),
          ),
          body: Padding(
            padding: EdgeInsets.fromLTRB(
              20, 
              isSmallHeight ? 4 : 16, 
              20, 
              isSmallHeight ? 8 : 16
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Content: Model Chip & Status Ring
                Expanded(
                  flex: 5,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_activeModelUsed.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Chip(
                              backgroundColor: context.ext.surfaceDim,
                              side: BorderSide(color: context.ext.glassBorder, width: 1),
                              avatar: Icon(
                                _activeModelUsed == 'novaPro' ? Icons.cloud_done : Icons.memory,
                                size: 14,
                                color: _activeModelUsed == 'novaPro' ? Colors.blueAccent : AppTheme.accentGreen,
                              ),
                              label: Text(
                                _activeModelUsed == 'novaPro'
                                    ? 'STATUS: Amazon Nova Pro Active'
                                    : (_selectedModel == AnalysisModel.novaPro
                                        ? 'STATUS: ShelfSense AI Active (Failover)'
                                        : 'STATUS: ShelfSense AI (Edge) Active'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.ext.textSecondary,
                                ),
                              ),
                            ),
                          ).animate().fadeIn().slideY(begin: -0.2),

                        // Status Ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_statusIcon(_resultStatus), color: color, size: 36),
                              const SizedBox(height: 4),
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

                        const SizedBox(height: 12),

                        Text(
                          _resultName,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 4),

                        Text(
                          '$_resultConfidence% confidence',
                          style: TextStyle(fontSize: 13, color: context.ext.textMuted),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 16),

                        // Confidence bar
                        SizedBox(
                          width: 280,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _resultConfidence / 100,
                              minHeight: 6,
                              backgroundColor: context.ext.glassBackground,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallHeight ? 8 : 16),

                // Middle Section: Metrics & Info
                Expanded(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // RUL & Environment Tiles
                        SizedBox(
                          width: 340,
                          child: Row(
                            children: [
                              _metricTile(TimeUtils.formatMinutes(_resultRul), 'RUL', color),
                              const SizedBox(width: 8),
                              _metricTile('${temp.toStringAsFixed(1)}°C', 'Temp', AppTheme.accentAmber),
                              const SizedBox(width: 8),
                              _metricTile('${humidity.toStringAsFixed(0)}%', 'Humidity', AppTheme.accentCyan),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 12),

                        // Preservation Guide Header
                        Text(
                          'PRESERVATION GUIDE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: context.ext.textMuted,
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 12),

                        // Reduced Preservation Cards Section
                        SizedBox(
                          width: 340,
                          child: Column(
                            children: [
                              _preservationCard(
                                context,
                                'Technique',
                                _getStorageAdvice(_resultStatus),
                                color,
                                Icons.tips_and_updates,
                                isCompact: true,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallHeight ? 8 : 16),

                // Bottom Section: Scan Again Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetScan,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.accentGreen, size: 16),
                    label: const Text('Scan Another',
                        style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStorageAdvice(String status) {
    switch (status) {
      case 'fresh': return 'Store in airtight container in fridge (2-4°C). Keep away from ethylene-producers.';
      case 'ripening': return 'Consume within 48h. Move to fridge if at room temp. Great for cooking now.';
      case 'soon_rotten': return 'Trim affected edges and consume immediately. Use in smoothies or cooked dishes.';
      case 'rotten': return '⚠️ Unsafe for consumption. Discard immediately to prevent bacterial spread.';
      default: return 'Store according to produce-specific biological guidelines.';
    }
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
    IconData icon, {
    bool isCompact = false,
  }) {
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 10 : 14),
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
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
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

  // ── Manual Entry Fallback (AI failure / Bedrock timeout) ──────────
  Widget _buildManualEntry() {
    final nameController = TextEditingController();
    return Padding(
      key: const ValueKey('manual_entry'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentAmber.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.edit_note, color: AppTheme.accentAmber, size: 36),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 20),
            const Text(
              'AI Unavailable',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              'The scan service is temporarily unavailable.\nYou can add the item manually.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.ext.textMuted, height: 1.5),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 28),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter produce name (e.g. Tomato)',
                    hintStyle: TextStyle(color: context.ext.textMuted),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.eco, color: context.ext.textMuted, size: 20),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetScan,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.ext.glassBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry Scan', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        ref.read(inventoryProvider.notifier).addItem(ProduceItem(
                              id: 'm${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              rul: 48 * 60, // Default 48h
                              status: 'fresh',
                              icon: Icons.eco,
                              iconColor: AppTheme.accentGreen,
                              emoji: ProduceEmoji.getEmoji(name),
                              storage: _selectedStorage,
                              addedAt: DateTime.now(),
                            ));
                        _resultName = name;
                        _resultStatus = 'fresh';
                        _resultConfidence = 100;
                        _resultRul = 48 * 60;
                        setState(() {
                          _scanFailed = false;
                          _phase = ScanPhase.result;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Add Item',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
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
