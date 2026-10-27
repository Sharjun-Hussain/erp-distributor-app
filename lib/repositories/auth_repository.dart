import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/auth.dart';
import '../services/api_client.dart';

abstract class AuthRepository {
  Future<DistributorUser> login(String email, String password);
  Future<void> logout(String? token);
  Future<DistributorUser> me();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<String> forgotPassword(String email);
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clearToken();
}

class MockAuthRepository implements AuthRepository {
  static const _tokenKey = 'distributor_auth_token';

  @override
  Future<DistributorUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!email.contains('@')) {
      throw const AuthException('Enter a valid email address');
    }
    if (password.length < 4) {
      throw const AuthException('Invalid email or password');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _tokenKey, 'mock-token-${DateTime.now().millisecondsSinceEpoch}');
    return MockData.distributorUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<String> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'If an account exists with this email, a reset link has been sent.';
  }

  @override
  Future<void> logout(String? token) async {
    await Future.delayed(const Duration(milliseconds: 200));
    await clearToken();
  }

  @override
  Future<DistributorUser> me() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.distributorUser;
  }

  @override
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

class AuthException implements Exception {
  final String message;
  final bool requires2fa;
  const AuthException(this.message, {this.requires2fa = false});

  @override
  String toString() => message;
}

/// Talks to `/api/v1/auth/distributor-*` and `/api/v1/dapp/me`.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<DistributorUser> login(String email, String password) async {
    try {
      final data = await _client.post(
        '/auth/distributor-login',
        data: {'email': email, 'password': password},
      );
      final map = (data as Map).cast<String, dynamic>();
      final access = map['auth_token'] as String?;
      final refresh = map['refresh_token'] as String?;
      if (access == null || access.isEmpty) {
        throw const AuthException('Login failed. Please try again.');
      }
      await TokenStore.instance.save(access: access, refresh: refresh);
      final userJson = (map['user'] as Map?)?.cast<String, dynamic>();
      if (userJson == null) {
        return me();
      }
      return DistributorUser.fromJson(userJson);
    } on ApiException catch (e) {
      throw AuthException(e.message, requires2fa: e.requires2fa);
    }
  }

  @override
  Future<DistributorUser> me() async {
    try {
      final data = await _client.get('/dapp/me');
      final map = (data as Map).cast<String, dynamic>();
      final userJson = (map['user'] as Map?)?.cast<String, dynamic>();
      if (userJson == null) {
        throw const AuthException('Could not load your profile.');
      }
      return DistributorUser.fromJson(userJson);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        '/dapp/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<String> forgotPassword(String email) async {
    try {
      final res = await _client.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      if (res is Map && res['message'] is String) {
        return res['message'] as String;
      }
      return 'If an account exists with this email, a reset link has been sent.';
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> logout(String? token) async {
    final refresh = await TokenStore.instance.readRefresh();
    try {
      await _client.post(
        '/dapp/logout',
        data: {'refresh_token': ?refresh},
      );
    } on ApiException {
      // Best-effort: always clear the local session.
    } finally {
      await TokenStore.instance.clear();
    }
  }

  @override
  Future<String?> readToken() => TokenStore.instance.readAccess();

  @override
  Future<void> writeToken(String token) =>
      TokenStore.instance.save(access: token);

  @override
  Future<void> clearToken() => TokenStore.instance.clear();
}

AuthRepository buildAuthRepository(ApiClient client) =>
    useMockApis ? MockAuthRepository() : ApiAuthRepository(client);
