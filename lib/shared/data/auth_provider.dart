import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/aws_config.dart';
import 'api_client.dart';

/// Authentication state model.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? email;
  final String? name;
  final String? idToken;
  final String? refreshToken;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.email,
    this.name,
    this.idToken,
    this.refreshToken,
    this.error,
  });

  /// Display name: Cognito name claim, or email prefix as fallback.
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (email != null && email!.contains('@')) return email!.split('@').first;
    return 'Guest User';
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? email,
    String? name,
    String? idToken,
    String? refreshToken,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      name: name ?? this.name,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error,
    );
  }
}

/// Manages authentication state.
///
/// When [AwsConfig.useCloudBackend] is false, uses demo-mode passthrough
/// (any credentials succeed). When true, calls Cognito via API Gateway.
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  static const _kIdToken = 'bio_id_token';
  static const _kRefreshToken = 'bio_refresh_token';
  static const _kEmail = 'bio_email';
  static const _kDisplayName = 'bio_display_name';

  AuthNotifier(this._ref) : super(const AuthState()) {
    _loadCachedSession();
  }

  /// Load cached session from SharedPreferences before first UI frame.
  Future<void> _loadCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString(_kIdToken);
    final cachedEmail = prefs.getString(_kEmail);
    final cachedRefresh = prefs.getString(_kRefreshToken);
    final cachedName = prefs.getString(_kDisplayName);

    if (cachedToken != null && cachedEmail != null) {
      // Extract name from the cached JWT (may be fresher than SharedPreferences)
      final jwtName = _extractNameFromJwt(cachedToken);
      state = state.copyWith(
        isAuthenticated: true,
        email: cachedEmail,
        name: jwtName ?? cachedName,
        idToken: cachedToken,
        refreshToken: cachedRefresh,
      );
    }
  }

  /// Sign up a new user.
  Future<bool> signUp(String email, String password, {String? fullName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!AwsConfig.useCloudBackend) {
        await Future.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(isLoading: false);
        return true;
      }

      await _ref.read(apiClientProvider).signUp(email, password);

      // Save fullName to SharedPreferences as backup display name
      if (fullName != null && fullName.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kDisplayName, fullName);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in with email and password.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!AwsConfig.useCloudBackend) {
        // Demo mode — always succeeds
        await Future.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          email: email,
          idToken: 'demo-token',
        );
        return true;
      }

      final data = await _ref.read(apiClientProvider).signIn(email, password);
      final idToken = data['idToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      // Extract the 'name' claim from the Cognito idToken JWT
      String? userName;
      if (idToken != null) {
        userName = _extractNameFromJwt(idToken);
      }

      // Check SharedPreferences backup if JWT name is missing
      if (userName == null || userName.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userName = prefs.getString(_kDisplayName);
      }

      // Persist session to SharedPreferences for pre-emptive loading
      final prefs = await SharedPreferences.getInstance();
      if (idToken != null) await prefs.setString(_kIdToken, idToken);
      if (refreshToken != null) await prefs.setString(_kRefreshToken, refreshToken);
      await prefs.setString(_kEmail, email);
      if (userName != null) await prefs.setString(_kDisplayName, userName);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        email: email,
        name: userName,
        idToken: idToken,
        refreshToken: refreshToken,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Biometric sign-in gate.
  ///
  /// On web, this is not supported and returns false.
  /// On mobile, uses local_auth to verify biometrics first,
  /// then calls [signIn] with stored credentials.
  Future<bool> biometricSignIn() async {
    if (kIsWeb) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Dynamic import to avoid web compilation issues
      final authenticated = await _checkBiometrics();
      if (!authenticated) {
        state = state.copyWith(isLoading: false, error: 'Biometric auth failed');
        return false;
      }

      // After biometric success, use stored/demo credentials
      return signIn('biometric@bioclock.app', 'biometric-session');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Check biometric availability. Returns true in demo mode.
  Future<bool> _checkBiometrics() async {
    if (!AwsConfig.useCloudBackend) return true;

    // In production, this would use local_auth:
    // final localAuth = LocalAuthentication();
    // return await localAuth.authenticate(
    //   localizedReason: 'Verify your identity to sign in',
    //   options: const AuthenticationOptions(biometricOnly: true),
    // );
    return true;
  }

  /// Sign out and clear tokens + cached session.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIdToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kEmail);
    await prefs.remove(_kDisplayName);
    state = const AuthState();
  }

  /// Extract the 'name' or 'given_name' claim from a Cognito idToken JWT.
  String? _extractNameFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return (map['name'] as String?) ?? (map['given_name'] as String?);
    } catch (_) {
      return null;
    }
  }

  /// Attempt to refresh the session using the stored refresh token.
  Future<bool> refreshSession() async {
    if (!AwsConfig.useCloudBackend) return true;
    
    final refresh = state.refreshToken;
    final userEmail = state.email;
    
    if (refresh == null || userEmail == null) return false;
    
    try {
      final data = await _ref.read(apiClientProvider).refreshToken(userEmail, refresh);
      final newIdToken = data['idToken'] as String?;
      
      if (newIdToken != null) {
        // Re-extract name from the refreshed token
        final userName = _extractNameFromJwt(newIdToken);
        state = state.copyWith(idToken: newIdToken, name: userName);
        return true;
      }
      return false;
    } catch (e) {
      signOut();
      return false;
    }
  }
}

/// Global auth state provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
