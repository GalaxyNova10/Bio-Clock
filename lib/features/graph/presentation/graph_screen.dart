import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/core/time_utils.dart';
import '../../../shared/data/weather_service.dart';
import '../../../shared/data/api_client.dart';
import '../../../shared/ui/glass_card.dart';

/// Graph page — live/simulation RUL decay graph.
class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  bool _isLive = false;
  LiveWeatherData _weather = const LiveWeatherData(
    temperature: 30.0,
    humidity: 70.0,
    city: 'Local',
    isLive: false,
  );
  static const double _baselineTemp = 20;
  static const double _baselineRUL = 48;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    _weather = LiveWeatherData(
      temperature: WeatherService.getCurrentTemperature(),
      humidity: WeatherService.getCurrentHumidity(),
      city: WeatherService.getCityName(),
      isLive: false,
    );
    // Refresh mock weather every minute if not in Live mode
    _weatherTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isLive) _updateMockWeather();
    });
  }

  double get _q10Factor =>
      math.pow(2.0, (_weather.temperature - _baselineTemp) / 10).toDouble();
  double get _humidityFactor => 1.0 + ((_weather.humidity - 50) / 100 * 0.3);
  double get _adjustedRUL => _baselineRUL / (_q10Factor * _humidityFactor);

  Color get _tempColor {
    if (_weather.temperature <= 10) return AppTheme.accentCyan;
    if (_weather.temperature <= 25) return AppTheme.accentGreen;
    if (_weather.temperature <= 35) return AppTheme.accentAmber;
    return AppTheme.accentRed;
  }

  Color get _rulColor {
    if (_adjustedRUL >= 36) return AppTheme.accentGreen;
    if (_adjustedRUL >= 18) return AppTheme.accentAmber;
    return AppTheme.accentRed;
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }

  void _toggleLive(bool live) {
    setState(() => _isLive = live);
    if (live) {
      _updateLiveWeather();
      _weatherTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _updateLiveWeather();
      });
    } else {
      _weatherTimer?.cancel();
      _updateMockWeather(); // Revert to mock data when switching off live
    }
  }

  void _updateMockWeather() {
    setState(() {
      _weather = LiveWeatherData(
        temperature: WeatherService.getCurrentTemperature(),
        humidity: WeatherService.getCurrentHumidity(),
        city: WeatherService.getCityName(),
        isLive: false,
      );
    });
  }

  Future<void> _updateLiveWeather() async {
    final liveData = await WeatherService.fetchLiveWeather(ref.read(apiClientProvider));
    if (!mounted) return;
    setState(() {
      _weather = liveData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.show_chart,
                  color: AppTheme.accentCyan, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Graph',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          // Live/Simulation toggle
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: context.ext.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.ext.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleChip('Simulate', !_isLive, () => _toggleLive(false)),
                const SizedBox(width: 4),
                _toggleChip('Live', _isLive, () => _toggleLive(true)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Metric Cards ────────
            Row(
              children: [
                _metricCard(context, 'Q₁₀', '${_q10Factor.toStringAsFixed(2)}×',
                    AppTheme.accentGreen),
                const SizedBox(width: 10),
                _metricCard(
                  context,
                  'Temperature',
                  '${_weather.temperature.toStringAsFixed(1)}°C',
                  _tempColor,
                ),
                const SizedBox(width: 10),
                _metricCard(
                    context,
                    'Baseline',
                    TimeUtils.formatHours(_baselineRUL),
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7)),
                const SizedBox(width: 10),
                _metricCard(context, 'Predicted',
                    TimeUtils.formatHours(_adjustedRUL), _rulColor),
              ],
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 20),

            // ── Chart ──────────────
            _buildRULChart(context)
                .animate()
                .fadeIn(delay: 100.ms, duration: 600.ms),

            const SizedBox(height: 20),

            // ── Environmental sliders / live data ──
            _buildEnvironmentSection(context)
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentGreen.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && label == 'Live') ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppTheme.accentGreen : context.ext.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(fontSize: 10, color: context.ext.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRULChart(BuildContext context) {
    final isDark = context.isDark;
    const int steps = 24;
    final List<FlSpot> predicted = [];
    final List<FlSpot> baseline = [];

    for (int i = 0; i <= steps; i++) {
      final t = i.toDouble();
      baseline.add(FlSpot(t, math.max(0, _baselineRUL * (1 - t / steps))));
      predicted.add(FlSpot(
        t,
        math.max(0, _adjustedRUL * (1 - math.pow(t / steps, 0.8))),
      ));
    }

    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.06);
    final axisColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.4);
    final baselineLineColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.2);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RUL Prediction',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        _isLive
                            ? 'Live weather-synced forecast'
                            : 'Simulated decay forecast',
                        style: TextStyle(
                            fontSize: 11, color: context.ext.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.ext.glassBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.ext.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 2, color: baselineLineColor),
                      const SizedBox(width: 4),
                      Text('Base',
                          style: TextStyle(
                              fontSize: 9, color: context.ext.textMuted)),
                      const SizedBox(width: 8),
                      Container(width: 10, height: 2, color: _rulColor),
                      const SizedBox(width: 4),
                      Text('Pred',
                          style: TextStyle(
                              fontSize: 9, color: context.ext.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _baselineRUL / 4,
                    verticalInterval: steps / 4,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: _baselineRUL / 3,
                        getTitlesWidget: (v, _) => Text(
                          TimeUtils.formatHours(v),
                          style: TextStyle(
                            fontSize: 9,
                            color: axisColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: steps / 3,
                        getTitlesWidget: (v, _) {
                          String text;
                          if (v == 0) {
                            text = 'Now';
                          } else if (v >= steps) {
                            text = 'End';
                          } else {
                            text = 'T+${v.toInt()}h';
                          }
                          return Text(text,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: axisColor,
                                  fontFamily: 'monospace'));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: steps.toDouble(),
                  minY: 0,
                  maxY: _baselineRUL + 4,
                  lineBarsData: [
                    LineChartBarData(
                      spots: baseline,
                      isCurved: true,
                      color: baselineLineColor,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      dashArray: [6, 4],
                    ),
                    LineChartBarData(
                      spots: predicted,
                      isCurved: true,
                      color: _rulColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _rulColor.withValues(alpha: 0.2),
                            _rulColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      shadow: Shadow(
                        blurRadius: 8,
                        color: _rulColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: _baselineRUL * 0.25,
                        color: AppTheme.accentRed.withValues(alpha: 0.25),
                        strokeWidth: 0.8,
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: TextStyle(
                            fontSize: 8,
                            color: AppTheme.accentRed.withValues(alpha: 0.5),
                          ),
                          labelResolver: (_) => 'Critical',
                        ),
                      ),
                    ],
                  ),
                ),
                duration: const Duration(milliseconds: 600),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _footerStat(
                    context,
                    'Baseline',
                    TimeUtils.formatHours(_baselineRUL),
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7)),
                const SizedBox(width: 10),
                _footerStat(context, 'Predicted',
                    TimeUtils.formatHours(_adjustedRUL), _rulColor),
                const SizedBox(width: 10),
                _footerStat(
                  context,
                  'Degradation',
                  '${((1 - _adjustedRUL / _baselineRUL) * 100).toStringAsFixed(0)}%',
                  AppTheme.accentAmber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerStat(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.ext.glassBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ext.glassBorder),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: context.ext.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSection(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Environmental Factors',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                if (_isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${WeatherService.getCityName()} Live',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                _isLive
                    ? 'Real-time weather data from ${WeatherService.getCityName()}'
                    : 'Adjust parameters to simulate decay rate',
                style: TextStyle(fontSize: 11, color: context.ext.textMuted)),
            const SizedBox(height: 24),

            // Temperature
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.thermostat, color: _tempColor, size: 22),
                Text('Temperature',
                    style: TextStyle(color: context.ext.textSecondary)),
                Text(
                  '${_weather.temperature.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _tempColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_isLive) ...[
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _tempColor,
                  thumbColor: _tempColor,
                  overlayColor: _tempColor.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _weather.temperature,
                  min: 0,
                  max: 45,
                  onChanged: (v) => setState(() => _weather = LiveWeatherData(
                    temperature: v,
                    humidity: _weather.humidity,
                    city: _weather.city,
                    isLive: _weather.isLive,
                  )),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0°C',
                      style: TextStyle(
                          fontSize: 10, color: context.ext.textMuted)),
                  Text('45°C',
                      style: TextStyle(
                          fontSize: 10, color: context.ext.textMuted)),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Humidity
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.water_drop,
                    color: AppTheme.accentCyan, size: 22),
                Text('Humidity',
                    style: TextStyle(color: context.ext.textSecondary)),
                Text(
                  '${_weather.humidity.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_isLive) ...[
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.accentCyan,
                  thumbColor: AppTheme.accentCyan,
                  overlayColor: AppTheme.accentCyan.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _weather.humidity,
                  min: 20,
                  max: 95,
                  onChanged: (v) => setState(() => _weather = LiveWeatherData(
                    temperature: _weather.temperature,
                    humidity: v,
                    city: _weather.city,
                    isLive: _weather.isLive,
                  )),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('20%',
                      style: TextStyle(
                          fontSize: 10, color: context.ext.textMuted)),
                  Text('95%',
                      style: TextStyle(
                          fontSize: 10, color: context.ext.textMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
