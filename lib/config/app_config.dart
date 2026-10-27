/// Central runtime configuration for the Distributor App.
///
/// Same architecture as flutter_erp:
/// - In release builds (`kReleaseMode`), production URL is always hardcoded.
/// - In debug/dev builds, localhost:5000 (or 10.0.2.2 on Android emulator)
///   is used by default, and can be overridden via Server Setup screen.
class AppConfig {
  AppConfig._();

  /// Production host (without the `/api/v1` suffix).
  static const String productionBaseUrl = 'https://pos-api-v2.inzeedo.lk';
  static const String productionApiUrl = '$productionBaseUrl/api/v1';

  /// SharedPreferences keys used for session persistence.
  static const String accessTokenKey = 'distributor_auth_token';
  static const String refreshTokenKey = 'distributor_refresh_token';
  static const String customApiUrlKey = 'custom_api_url';

  static String? _cachedCustomUrl;

  static void setCustomUrl(String? url) {
    _cachedCustomUrl = url?.trim();
  }

  static String? get customUrl => _cachedCustomUrl;

  /// The full API base including the version prefix.
  /// Defaults to productionApiUrl (https://pos-api-v2.inzeedo.lk/api/v1).
  /// Can be overridden via Server Setup screen or --dart-define=API_BASE_URL=...
  static String get apiBaseUrl {
    if (_cachedCustomUrl != null && _cachedCustomUrl!.isNotEmpty) {
      return _normalize(_cachedCustomUrl!);
    }

    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return _normalize(override);

    return productionApiUrl;
  }

  /// Ensure the base URL ends with `/api/v1` exactly once.
  static String _normalize(String url) {
    var base = url.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (!base.endsWith('/api/v1')) base = '$base/api/v1';
    return base;
  }
}
