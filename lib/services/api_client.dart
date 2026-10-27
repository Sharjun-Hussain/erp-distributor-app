import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Thrown for any failed API interaction. [message] is always safe to show.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool requires2fa;

  const ApiException(this.message, {this.statusCode, this.requires2fa = false});

  @override
  String toString() => message;
}

/// Session persistence for the distributor app.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  Future<String?> readAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConfig.accessTokenKey);
    } catch (e) {
      debugPrint('[TokenStore] readAccess error: $e');
      return null;
    }
  }

  Future<String?> readRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConfig.refreshTokenKey);
    } catch (e) {
      debugPrint('[TokenStore] readRefresh error: $e');
      return null;
    }
  }

  Future<void> save({String? access, String? refresh}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (access != null) await prefs.setString(AppConfig.accessTokenKey, access);
      if (refresh != null) {
        await prefs.setString(AppConfig.refreshTokenKey, refresh);
      }
    } catch (e) {
      debugPrint('[TokenStore] save error: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.accessTokenKey);
      await prefs.remove(AppConfig.refreshTokenKey);
    } catch (e) {
      debugPrint('[TokenStore] clear error: $e');
    }
  }
}

enum _RefreshOutcome { ok, rejected, retryable }

class _RefreshResult {
  final _RefreshOutcome outcome;
  final String? accessToken;
  const _RefreshResult._(this.outcome, this.accessToken);
  factory _RefreshResult.ok(String? token) =>
      _RefreshResult._(_RefreshOutcome.ok, token);
  const _RefreshResult.rejected() : this._(_RefreshOutcome.rejected, null);
  const _RefreshResult.retryable() : this._(_RefreshOutcome.retryable, null);
}

/// Lightweight Dio wrapper for `/api/v1/dapp/*`.
///
/// - Attaches `Authorization: Bearer <access>` to every request.
/// - On 401, performs a single-flight `POST /auth/distributor-refresh` and
///   retries the original request once.
/// - Maps every failure to [ApiException] with a user-friendly message.
class ApiClient {
  ApiClient({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json'},
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = AppConfig.apiBaseUrl;
          final token = await TokenStore.instance.readAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401 &&
              err.requestOptions.extra['authRetried'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed != null) {
              try {
                final opts = err.requestOptions;
                opts.headers['Authorization'] = 'Bearer $refreshed';
                opts.extra['authRetried'] = true;
                final retried = await _dio.request<dynamic>(
                  opts.path,
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                    extra: opts.extra,
                  ),
                );
                return handler.resolve(retried);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get raw => _dio;

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
  }

  Future<String?> _tryRefresh() async {
    final refresh = await TokenStore.instance.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await TokenStore.instance.clear();
      return null;
    }
    final result = await _refreshSingleFlight(refresh);
    if (result.outcome == _RefreshOutcome.ok) return result.accessToken;
    if (result.outcome == _RefreshOutcome.rejected) {
      await TokenStore.instance.clear();
    }
    return null;
  }

  Future<_RefreshResult>? _refreshFuture;
  String? _refreshKey;

  Future<_RefreshResult> _refreshSingleFlight(String oldRefresh) {
    final ongoing = _refreshFuture;
    if (ongoing != null && _refreshKey == oldRefresh) return ongoing;
    final future = _doRefresh(oldRefresh);
    _refreshFuture = future;
    _refreshKey = oldRefresh;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
        _refreshKey = null;
      }
    });
  }

  Future<_RefreshResult> _doRefresh(String oldRefresh) async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    try {
      final res = await refreshDio.post<dynamic>(
        '/auth/distributor-refresh',
        data: {'refresh_token': oldRefresh},
      );
      final data = _unwrap(res);
      final newAccess = data['auth_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      if (newAccess == null) return const _RefreshResult.retryable();
      await TokenStore.instance.save(access: newAccess, refresh: newRefresh);
      return _RefreshResult.ok(newAccess);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return const _RefreshResult.rejected();
      }
      if (status == 409) {
        final current = await TokenStore.instance.readAccess();
        if (current != null) return _RefreshResult.ok(current);
      }
      return const _RefreshResult.retryable();
    } catch (e) {
      debugPrint('[ApiClient] refresh failed: $e');
      return const _RefreshResult.retryable();
    }
  }

  // ---------------------------------------------------------------------------
  // Verb helpers — all return the unwrapped `data` payload.
  // ---------------------------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => _dio.patch<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  /// Downloads binary bytes (e.g. PDF generation endpoints) with active auth headers.
  Future<List<int>> downloadBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );
      final data = response.data;
      if (data is List<int>) {
        return data;
      } else if (data is List) {
        return data.cast<int>();
      }
      throw const ApiException('Invalid binary response received.');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    try {
      final res = await run();
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Responses follow `{ status, message, data }`. Returns `data`.
  dynamic _unwrap(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  ApiException _mapError(DioException e) {
    debugPrint('[ApiClient] Request failed: ${e.requestOptions.method} ${e.requestOptions.uri}');
    debugPrint('[ApiClient] Type: ${e.type}, Status: ${e.response?.statusCode}, Error: ${e.error}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
            'The server took too long to respond (${e.requestOptions.uri.host}). Please try again.');
      case DioExceptionType.connectionError:
        return ApiException(
            'Cannot reach server at ${e.requestOptions.uri.host}. Check your internet connection.');
      case DioExceptionType.badCertificate:
        return ApiException(
            'Security certificate error for ${e.requestOptions.uri.host}.');
      case DioExceptionType.cancel:
        return const ApiException('Request was cancelled.');
      default:
        break;
    }

    final res = e.response;
    final data = res?.data;
    String? serverMessage;
    bool requires2fa = false;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.trim().isNotEmpty) serverMessage = msg.trim();
      final errors = data['errors'];
      if (errors is Map) {
        requires2fa = errors['requires2fa'] == true;
      }
    } else if (data is String && data.trim().isNotEmpty) {
      if (!data.contains('<html') && data.length < 200) {
        serverMessage = data.trim();
      }
    }

    final status = res?.statusCode;
    final fallback = switch (status) {
      400 => 'The request was invalid.',
      401 => 'Invalid credentials or session expired.',
      403 => 'You do not have access to this resource.',
      404 => 'The requested endpoint was not found on ${e.requestOptions.uri.host}.',
      500 => 'Server encountered an internal error. Please try again later.',
      502 || 503 || 504 => 'Server is temporarily unavailable ($status).',
      _ => e.error != null
          ? 'Network error: ${e.error}'
          : 'Request failed (${status ?? 'no response'}) on ${e.requestOptions.uri.host}.',
    };

    return ApiException(
      serverMessage ?? fallback,
      statusCode: status,
      requires2fa: requires2fa,
    );
  }
}
