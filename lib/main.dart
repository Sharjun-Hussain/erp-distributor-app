import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'config/app_config.dart';
import 'router/app_router.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Prevent Google Fonts from blocking on network requests
    GoogleFonts.config.allowRuntimeFetching = false;

    // Catch all unhandled Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
      final customUrl = prefs.getString(AppConfig.customApiUrlKey);
      if (customUrl != null && customUrl.isNotEmpty) {
        AppConfig.setCustomUrl(customUrl);
      }
    } catch (_) {
      // Ignore initialization errors
    }

    runApp(
      const ProviderScope(
        child: DistributorApp(),
      ),
    );
  } catch (e, stack) {
    FlutterError.presentError(FlutterErrorDetails(exception: e, stack: stack));
    runApp(const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'App failed to start',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ));
  }
}

class DistributorApp extends ConsumerWidget {
  const DistributorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'CoDesk Distribution',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
        builder: (context, child) {
          return AppWrapper(child: child!);
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  final Widget child;
  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _updateOfflineStatus(results);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateService.checkForUpdates(context);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isOffline && mounted) {
      UpdateService.checkForUpdates(context);
    }
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateOfflineStatus(results);
    } catch (_) {
      // Ignore platform channel failures on initial frame
    }
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    if (!mounted) return;
    try {
      final offline = results.contains(ConnectivityResult.none);
      if (_isOffline != offline) {
        setState(() => _isOffline = offline);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isOffline)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.red[600],
                elevation: 10,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "No Internet Connection",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
