import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Update policy for CoDesk Distributor App:
/// - current < minVersion                  → BLOCKING force-update dialog (unclosable).
/// - minVersion <= current < latestVersion → Soft "update available" bottom sheet (dismissible).
/// - current >= latestVersion              → Silent on auto, "Up to date" toast on manual check.
class UpdateService {
  UpdateService._();

  /// True while the blocking force dialog is active.
  static bool _forceDialogOpen = false;

  /// True while the soft update sheet is active.
  static bool _softSheetOpen = false;

  static const String _kRemindLaterUntil = 'distributor_update_remind_until';
  static const String _kLastSoftPrompt = 'distributor_update_last_soft_prompt';

  /// "Remind me later" snooze duration (24 hours).
  static const Duration _remindSnooze = Duration(hours: 24);
  static const Duration _softPromptGap = Duration(hours: 24);

  /// Check for updates automatically (called on app startup and app resume).
  static Future<void> checkForUpdates(BuildContext context) async {
    // Skip on Web; app updates apply to installed mobile apps
    if (kIsWeb) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final versionInfo = await _fetchLatestVersionFromAPI();
      if (versionInfo == null) return; // Stay silent on network/server error

      final latestVersion = versionInfo['version']!.isEmpty
          ? currentVersion
          : versionInfo['version']!;
      final minVersion = versionInfo['minVersion']!.isEmpty
          ? latestVersion
          : versionInfo['minVersion']!;
      final storeUrl = versionInfo['url'] ?? '';

      if (_compareVersions(currentVersion, minVersion) < 0) {
        // HARD BLOCKING UPDATE
        final BuildContext? navContext = rootNavigatorKey.currentContext;
        final target = (navContext != null && navContext.mounted)
            ? navContext
            : (context.mounted ? context : null);
        if (target != null && target.mounted) {
          _showForceUpdateDialog(
            target,
            packageInfo.packageName,
            storeUrl,
            currentVersion,
            minVersion,
          );
        }
      } else if (_compareVersions(currentVersion, latestVersion) < 0) {
        // SOFT UPDATE: Check snooze & prompt gap
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().millisecondsSinceEpoch;
        final remindUntil = prefs.getInt(_kRemindLaterUntil) ?? 0;
        final lastPrompt = prefs.getInt(_kLastSoftPrompt) ?? 0;

        if (now < remindUntil) return;
        if (now - lastPrompt < _softPromptGap.inMilliseconds) return;

        await prefs.setInt(_kLastSoftPrompt, now);
        final BuildContext? navContext = rootNavigatorKey.currentContext;
        final target = (navContext != null && navContext.mounted)
            ? navContext
            : (context.mounted ? context : null);
        if (target != null && target.mounted) {
          _showUpdateBottomSheet(
            target,
            packageInfo.packageName,
            storeUrl,
            currentVersion,
            latestVersion,
          );
        }
      }
    } catch (e) {
      debugPrint('[UpdateService] Check error: $e');
    }
  }

  /// Manual check triggered by user (e.g. from Settings / More screen).
  static Future<void> manualCheckForUpdates(BuildContext context) async {
    if (kIsWeb) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flatColored,
        title: const Text('Web Version'),
        description: const Text(
          'You are using the web version, which is always updated automatically.',
        ),
        autoCloseDuration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final versionInfo = await _fetchLatestVersionFromAPI();
      if (versionInfo == null) {
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text('Update Check Failed'),
            description: const Text(
              'Unable to check server for updates. Please try again later.',
            ),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
        return;
      }

      final latestVersion = versionInfo['version']!.isEmpty
          ? currentVersion
          : versionInfo['version']!;
      final minVersion = versionInfo['minVersion']!.isEmpty
          ? latestVersion
          : versionInfo['minVersion']!;
      final storeUrl = versionInfo['url'] ?? '';

      final BuildContext? navContext = rootNavigatorKey.currentContext;
      final target = (navContext != null && navContext.mounted)
          ? navContext
          : (context.mounted ? context : null);
      if (target == null || !target.mounted) return;

      if (_compareVersions(currentVersion, minVersion) < 0) {
        _showForceUpdateDialog(
          target,
          packageInfo.packageName,
          storeUrl,
          currentVersion,
          minVersion,
        );
      } else if (_compareVersions(currentVersion, latestVersion) < 0) {
        _showUpdateBottomSheet(
          target,
          packageInfo.packageName,
          storeUrl,
          currentVersion,
          latestVersion,
        );
      } else {
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: const Text('Up to Date'),
            description: Text(
              'You are running the latest version (v$currentVersion).',
            ),
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      debugPrint('[UpdateService] Manual check error: $e');
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Update Check Error'),
          description: Text(e.toString().replaceAll('Exception: ', '')),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    }
  }

  /// Queries the backend API for distributor app version configuration.
  static Future<Map<String, String>?> _fetchLatestVersionFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String baseUrl = kReleaseMode
          ? AppConfig.productionApiUrl
          : (prefs.getString(AppConfig.customApiUrlKey) ?? AppConfig.apiBaseUrl);

      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      // Attempt endpoint 1: /mobile/distributor-app-version
      Response? response;
      try {
        response = await dio.get('$baseUrl/mobile/distributor-app-version');
      } catch (_) {
        // Fallback to /mobile/app-version?app=distributor
        response = await dio.get('$baseUrl/mobile/app-version', queryParameters: {'app': 'distributor'});
      }

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'] as Map;
        return {
          'version': data['latestVersion']?.toString() ?? '',
          'minVersion': data['minVersion']?.toString() ?? '',
          'url': data['storeUrl']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('[UpdateService] Failed to fetch latest version: $e');
    }
    return null;
  }

  /// Numeric semantic version comparison.
  /// Ignores build metadata after '+'. Returns -1 if a < b, 0 if a == b, 1 if a > b.
  static int _compareVersions(String a, String b) {
    List<int> parse(String v) {
      final core = v.split('+').first.trim();
      if (core.isEmpty) return <int>[0];
      return core.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    }

    final pa = parse(a);
    final pb = parse(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }

  /// Launches the store URL or APK download link.
  static Future<void> _openStore(String storeUrl, String packageName) async {
    if (storeUrl.isNotEmpty && storeUrl.startsWith('http')) {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (Platform.isAndroid) {
      final marketUri = Uri.parse('market://details?id=$packageName');
      final webUri =
          Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }

  /// Blocking mandatory-update dialog: no dismiss, no close, PopScope locked.
  static void _showForceUpdateDialog(
    BuildContext context,
    String packageName,
    String storeUrl,
    String currentVersion,
    String minVersion,
  ) {
    if (_forceDialogOpen) return;
    _forceDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: theme.glassBorder),
            ),
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.shieldAlert,
                          color: AppColors.danger,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Update Required',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your current distributor app version (v$currentVersion) is no longer supported. Please update to v$minVersion or newer to continue connecting with the ERP server.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: theme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openStore(storeUrl, packageName),
                        icon: const Icon(LucideIcons.download, size: 18),
                        label: Text(
                          'UPDATE NOW',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) => _forceDialogOpen = false);
  }

  /// Soft update bottom sheet (dismissible, offers 'Remind Me Later').
  static void _showUpdateBottomSheet(
    BuildContext context,
    String packageName,
    String storeUrl,
    String currentVersion,
    String latestVersion,
  ) {
    if (_softSheetOpen) return;
    _softSheetOpen = true;

    // Record prompt time for gap enforcement
    unawaited(
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setInt(
          _kLastSoftPrompt,
          DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );

    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.surfaceMutedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.arrowUpCircle,
                      color: AppColors.brand,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Available',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version $latestVersion is now ready to download',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: theme.textSecondary),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.glassBorder),
                ),
                child: Text(
                  'A new version of CoDesk DMS is available with performance improvements, enhanced shop syncing, and vital security patches.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openStore(storeUrl, packageName),
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: Text(
                    'UPDATE NOW',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt(
                        _kRemindLaterUntil,
                        DateTime.now().millisecondsSinceEpoch +
                            _remindSnooze.inMilliseconds,
                      );
                    } catch (_) {}
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                  child: Text(
                    'Remind Me Later',
                    style: GoogleFonts.inter(
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _softSheetOpen = false);
  }
}
