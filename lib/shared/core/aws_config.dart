/// Centralized AWS configuration — single source of truth.
///
/// Replace placeholder values with real endpoints after provisioning
/// the AWS us-east-1 infrastructure (Cognito, API Gateway, Lambda, S3).
class AwsConfig {
  AwsConfig._();

  // ── Region ──
  static const String region = 'us-east-1';

  // ── Cognito ──
  static const String userPoolId = 'us-east-1_u4dg8hPVI';
  static const String clientId = '2j5runm77e1iss73grqjsf5skp';
  static const String identityPoolId = 'us-east-1:70f2b5e7-03ec-402c-a27f-534e5b5ab972';

  // ── API Gateway ──
  static const String apiBaseUrl = 'https://0dqlv9aerd.execute-api.us-east-1.amazonaws.com/Prod';
  static const String s3BucketName = 'bioclock-scans-v3-882574059997-us-east-1';
  static const String s3Region = region;

  // ── Lambda Endpoints (relative to apiBaseUrl) ──
  static const String authSignUp = '/auth/signup';
  static const String authSignIn = '/auth/signin';
  static const String authRefresh = '/auth/refresh';

  static const String inventoryList = '/inventory';
  static const String inventoryAdd = '/inventory/add';
  static const String inventoryBatchPredict = '/inventory/batch-predict';

  static const String weatherLive = '/weather/live';

  static const String scanAnalyze = '/scan/analyze';
  static const String scanPreserve = '/scan/preserve';

  static const String profileStats = '/profile/stats';
  static const String profileAchievements = '/profile/achievements';

  // ── API Keys ──
  static const String apiKey = 'PLACEHOLDER_API_KEY';

  // ── Feature Flags ──
  /// Set to true once real AWS endpoints are deployed.
  static const bool useCloudBackend = true;
}
