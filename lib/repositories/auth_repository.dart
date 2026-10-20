import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/auth.dart';

abstract class AuthRepository {
  Future<DistributorUser> login(String email, String password);
  Future<void> logout(String? token);
  Future<DistributorUser> me();
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
    await prefs.setString(_tokenKey, 'mock-token-${DateTime.now().millisecondsSinceEpoch}');
    return MockData.distributorUser;
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
  const AuthException(this.message);

  @override
  String toString() => message;
}

AuthRepository buildAuthRepository() => MockAuthRepository();

// TODO(api): replace with ApiAuthRepository hitting
// POST /api/v1/auth/distributor-login, GET /auth/me, POST /auth/logout.
