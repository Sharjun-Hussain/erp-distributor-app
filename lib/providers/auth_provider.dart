import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth.dart';
import '../repositories/auth_repository.dart';
import 'repository_providers.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final DistributorUser? user;
  final bool loading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.loading = false,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> initialize() async {
    try {
      final token = await _repository.readToken();
      if (token == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _repository.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _repository.clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(
      status: state.status,
      user: state.user,
      loading: true,
    );
    try {
      final user = await _repository.login(email.trim(), password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on AuthException catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout(state.user?.id);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repo);
  Future.microtask(notifier.initialize);
  return notifier;
});
