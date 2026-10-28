import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _safetyTimeoutTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Safety fallback: if anything stalls (e.g. routing race condition, DNS delay),
    // force navigation to /login after 2.5 seconds.
    _safetyTimeoutTimer = Timer(const Duration(milliseconds: 2500), () {
      _evaluateAndNavigate(forceLoginIfUnknown: true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateAndNavigate(forceLoginIfUnknown: false);
    });
  }

  void _evaluateAndNavigate({bool forceLoginIfUnknown = false}) {
    if (!mounted || _hasNavigated) return;

    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      _hasNavigated = true;
      _safetyTimeoutTimer?.cancel();
      context.go('/home');
    } else if (auth.status == AuthStatus.unauthenticated || forceLoginIfUnknown) {
      _hasNavigated = true;
      _safetyTimeoutTimer?.cancel();
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _safetyTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!_hasNavigated && next.status != AuthStatus.unknown) {
        _evaluateAndNavigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'CoDesk DMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Distribution Management System',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
