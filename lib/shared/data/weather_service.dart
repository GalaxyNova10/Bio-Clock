import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../core/aws_config.dart';

/// Weather service with live GPS + Lambda and mock fallback.
///
/// When [AwsConfig.useCloudBackend] is true and location is available,
/// fetches real weather from OpenWeather via Lambda proxy.
/// Otherwise falls back to sinusoidal Chennai simulation.
class WeatherService {
  WeatherService._();

  // ── Mock (Sinusoidal Simulation) ──

  /// Returns current mock temperature for Chennai (~30°C + sin variation).
  static double getCurrentTemperature() {
    final now = DateTime.now();
    final hourFraction = now.hour + now.minute / 60.0 + now.second / 3600.0;

    // Base temp varies through the day: cooler at night, hotter at 2 PM
    final diurnalPhase = (hourFraction - 14) / 24 * 2 * math.pi;
    final baseTemp = 30.0 + 4.0 * math.cos(diurnalPhase);

    // Small random-ish component from seconds
    final microVar = math.sin(now.millisecondsSinceEpoch / 10000.0) * 0.8;

    return baseTemp + microVar;
  }

  /// Returns current mock humidity for Chennai (~70% ± variation).
  static double getCurrentHumidity() {
    final now = DateTime.now();
    final hourFraction = now.hour + now.minute / 60.0 + now.second / 3600.0;

    // Humidity inverse of temp: higher at night, lower at noon
    final diurnalPhase = (hourFraction - 14) / 24 * 2 * math.pi;
    final baseHumidity = 68.0 - 8.0 * math.cos(diurnalPhase);

    final microVar = math.cos(now.millisecondsSinceEpoch / 12000.0) * 2.0;

    return (baseHumidity + microVar).clamp(40.0, 95.0);
  }

  /// Returns city name for display.
  static String getCityName() => 'Chennai';

  // ── Live Weather (via Lambda) ──

  /// Fetch live weather from OpenWeather Lambda proxy using GPS coordinates.
  /// Returns a [LiveWeatherData] with real temp, humidity, and city name.
  /// Falls back to mock data on failure.
  static Future<LiveWeatherData> fetchLiveWeather(ApiClient api) async {
    if (!AwsConfig.useCloudBackend) {
      return LiveWeatherData(
        temperature: getCurrentTemperature(),
        humidity: getCurrentHumidity(),
        city: getCityName(),
        isLive: false,
      );
    }

    try {
      final position = await _getCurrentPosition();
      final data = await api.fetchWeather(position.latitude, position.longitude);

      return LiveWeatherData(
        temperature: (data['temperature'] as num).toDouble(),
        humidity: (data['humidity'] as num).toDouble(),
        city: data['city'] as String? ?? 'Unknown',
        isLive: true,
      );
    } catch (e) {
      debugPrint('Live weather fetch failed: $e');
      return LiveWeatherData(
        temperature: getCurrentTemperature(),
        humidity: getCurrentHumidity(),
        city: getCityName(),
        isLive: false,
      );
    }
  }

  /// Get current GPS position using geolocator.
  /// On web, returns a default Chennai position.
  static Future<_GeoPosition> _getCurrentPosition() async {
    if (kIsWeb) {
      // Web fallback — use Chennai coordinates
      return const _GeoPosition(13.0827, 80.2707);
    }

    try {
      // Dynamic geolocator call to avoid web compilation issues
      // In production, import geolocator and call:
      // final pos = await Geolocator.getCurrentPosition();
      // return _GeoPosition(pos.latitude, pos.longitude);

      // For now, use Chennai as default
      return const _GeoPosition(13.0827, 80.2707);
    } catch (_) {
      return const _GeoPosition(13.0827, 80.2707);
    }
  }
}

/// Simple position holder to avoid geolocator dependency on web.
class _GeoPosition {
  final double latitude;
  final double longitude;
  const _GeoPosition(this.latitude, this.longitude);
}

/// Live weather data model.
class LiveWeatherData {
  final double temperature;
  final double humidity;
  final String city;
  final bool isLive;

  const LiveWeatherData({
    required this.temperature,
    required this.humidity,
    required this.city,
    required this.isLive,
  });
}
