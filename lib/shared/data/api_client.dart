import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/aws_config.dart';
import 'auth_provider.dart';

/// Dio-based API client for all AWS Lambda calls via API Gateway.
///
/// Handles auth token injection, retries, and typed response deserialization.
/// All methods return Maps; callers parse domain objects.
class ApiClient {
  late final Dio _dio;
  final String? Function() getToken;
  final Future<bool> Function() onRefresh;

  ApiClient({required this.getToken, required this.onRefresh}) {
    _dio = Dio(BaseOptions(
      baseUrl: AwsConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': AwsConfig.apiKey,
      },
    ));

    // Auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized by attempting to refresh the session
        if (error.response?.statusCode == 401) {
          final refreshed = await onRefresh();
          if (refreshed) {
            final newToken = getToken();
            if (newToken != null) {
              // Retry the failed request with the new token
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // ══════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════

  /// Sign up a new user via Cognito Lambda proxy.
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await _dio.post(
      AwsConfig.authSignUp,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Sign in and receive JWT tokens.
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _dio.post(
      AwsConfig.authSignIn,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Refresh the session using a Cognito refresh token.
  Future<Map<String, dynamic>> refreshToken(
      String email, String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh', // Target API Gateway route for REFRESH_TOKEN_AUTH
      data: {'email': email, 'refreshToken': refreshToken},
    );
    return response.data as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════
  // INVENTORY
  // ══════════════════════════════════════════════

  /// Fetch all inventory items from DynamoDB for a specific user.
  Future<List<Map<String, dynamic>>> fetchInventory([String? userId]) async {
    final response = await _dio.get(
      AwsConfig.inventoryList,
      queryParameters: userId != null ? {'userId': userId} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  /// Donate an item, updating its status and incrementing the user's ImpactPoints.
  Future<Map<String, dynamic>> donateItem(String userId, String itemId) async {
    final response = await _dio.post(
      '/inventory/donate', // Relative to apiBaseUrl
      data: {'userId': userId, 'itemId': itemId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Add a scanned item to DynamoDB.
  Future<Map<String, dynamic>> addItem(Map<String, dynamic> item) async {
    final response = await _dio.post(AwsConfig.inventoryAdd, data: item);
    return response.data as Map<String, dynamic>;
  }

  /// Trigger Lambda batch prediction for all ripening items.
  Future<List<Map<String, dynamic>>> batchPredict() async {
    final response = await _dio.post(AwsConfig.inventoryBatchPredict);
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }

  // ══════════════════════════════════════════════
  // WEATHER
  // ══════════════════════════════════════════════

  /// Fetch live weather from OpenWeather via Lambda proxy.
  Future<Map<String, dynamic>> fetchWeather(double lat, double lng) async {
    final response = await _dio.get(
      AwsConfig.weatherLive,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return response.data as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════
  // SCAN (Rekognition + Claude)
  // ══════════════════════════════════════════════

  /// Upload image to S3 (Pre-signed or Direct API Gateway proxy flow)
  /// Forces a token refresh before every upload for bulletproof auth.
  Future<Map<String, dynamic>> uploadImageToS3(dynamic imageFile,
      {String? userId}) async {
    if (!AwsConfig.useCloudBackend) {
      throw Exception(
          'Cloud disabled. Falling back to local EmeraldDiamond mock logic.');
    }

    await onRefresh();

    try {
      final userSub = userId ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String s3Key = 'public/$userSub/$timestamp.jpg';

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _dio.post(
        AwsConfig.scanAnalyze,
        data: {
          'image': base64Image,
          's3Key': s3Key,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection Timed Out. Falling back to local mock.');
      }
      throw Exception('Upload Failed: ${e.message}');
    }
  }

  /// Upload image via bytes (Web/Cross-platform) with S3-partitioned key.
  /// Optionally accepts [overrideName] for user-corrected produce identification.
  Future<Map<String, dynamic>> scanProduce(Uint8List imageBytes,
      {String? userId, String? overrideName}) async {
    await onRefresh();

    final userSub = userId ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final s3Key = 'public/$userSub/$timestamp.jpg';

    final base64Image = base64Encode(imageBytes);

    final data = <String, dynamic>{
      'image': base64Image,
      's3Key': s3Key,
    };

    // Inject override_name if the user provided a correction
    if (overrideName != null && overrideName.isNotEmpty) {
      data['override_name'] = overrideName;
    }

    final response = await _dio.post(
      AwsConfig.scanAnalyze,
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get a Claude 4.5 Haiku preservation tip for a produce item.
  Future<Map<String, dynamic>> getPreservationTip(
      String produceName, String status, String storage) async {
    final response = await _dio.post(
      AwsConfig.scanPreserve,
      data: {
        'produce': produceName,
        'status': status,
        'storage': storage,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════
  // PROFILE
  // ══════════════════════════════════════════════

  /// Fetch aggregated user stats (CO2, money saved, scan count).
  Future<Map<String, dynamic>> fetchProfileStats() async {
    final response = await _dio.get(AwsConfig.profileStats);
    return response.data as Map<String, dynamic>;
  }

  /// Fetch user achievements.
  Future<Map<String, dynamic>> fetchAchievements() async {
    final response = await _dio.get(AwsConfig.profileAchievements);
    return response.data as Map<String, dynamic>;
  }
}

/// Global singleton provider for the API client.
final apiClientProvider = Provider<ApiClient>((ref) {
  // Use fully qualified `import` structure or lazy closures to avoid Riverpod loops
  return ApiClient(
    // We strictly use the idToken for Cognito authorizers
    getToken: () => ref.read(authProvider).idToken,
    onRefresh: () => ref.read(authProvider.notifier).refreshSession(),
  );
});
