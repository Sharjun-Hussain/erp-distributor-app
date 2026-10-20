import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    if (!ok && mounted) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error ?? 'Login failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(context, theme),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntranceFade(
                        delay: 320.ms,
                        slideY: 0.14,
                        child: Text(
                          'Welcome back',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      EntranceFade(
                        delay: 380.ms,
                        slideY: 0.14,
                        child: Text(
                          'Sign in to manage your orders & shops',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      EntranceFade(
                        delay: 450.ms,
                        slideY: 0.10,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'you@company.lk',
                                prefixSvg: 'assets/svg/field_mail.svg',
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                validator: (v) => (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: '••••••••',
                                prefixSvg: 'assets/svg/field_lock.svg',
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => (v == null || v.length < 4)
                                    ? 'Enter your password'
                                    : null,
                                suffix: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                                    ),
                                    child: SvgPicture.asset(
                                      _obscure
                                          ? 'assets/svg/field_eye_off.svg'
                                          : 'assets/svg/field_eye.svg',
                                      width: 20,
                                      height: 20,
                                      key: ValueKey(_obscure),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _ScaleTap(
                                onTap: _submit,
                                child: PrimaryButton(
                                  label: 'Sign In',
                                  loading: auth.loading,
                                  onPressed: _submit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      EntranceFade(
                        delay: 660.ms,
                        child: Center(
                          child: Text(
                            'Access is provided by your distributor administrator.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: 400,
      child: ClipPath(
        clipper: _HeroCurveClipper(),
        child: Stack(
          children: [
            // Gradient base
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brand, Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Drifting radial shimmer
            Positioned(
              left: -60,
              right: -60,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.5, -0.6),
                      radius: 1.1,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(
                  begin: -30,
                  end: 30,
                  duration: 5000.ms,
                  curve: Curves.easeInOut,
                ),
            // Decorative circles
            Positioned(
              right: -40,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -24,
              top: 130,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 44,
              top: 96,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            // Brand header
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  EntranceFade(
                    delay: Duration.zero,
                    slideY: 0,
                    scale: 0.5,
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset('assets/svg/logo_store.svg'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  EntranceFade(
                    delay: 80.ms,
                    slideY: 0.2,
                    child: Text(
                      'Distributor',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  EntranceFade(
                    delay: 140.ms,
                    slideY: 0.2,
                    child: Text(
                      'Orders, shops & stock on the go',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hero illustration
            Positioned(
              left: 0,
              right: 0,
              top: 172,
              child: Center(
                child: FloatingLoop(
                  distance: 8,
                  duration: const Duration(milliseconds: 2200),
                  child: EntranceFade(
                    delay: 250.ms,
                    slideY: 0.15,
                    child: SvgPicture.asset(
                      'assets/svg/hero_truck.svg',
                      width: 280,
                    ),
                  ),
                ),
              ),
            ),
            // Floating SVG badges
            Positioned(
              left: 18,
              top: 152,
              child: _floatingBadge(
                asset: 'assets/svg/badge_package.svg',
                delay: 450,
                floatDuration: 1600,
                floatDistance: 6,
              ),
            ),
            Positioned(
              right: 20,
              top: 196,
              child: _floatingBadge(
                asset: 'assets/svg/badge_wallet.svg',
                delay: 550,
                floatDuration: 1900,
                floatDistance: 8,
              ),
            ),
            Positioned(
              left: 52,
              top: 296,
              child: _floatingBadge(
                asset: 'assets/svg/badge_store.svg',
                delay: 650,
                floatDuration: 2200,
                floatDistance: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingBadge({
    required String asset,
    required int delay,
    required int floatDuration,
    required double floatDistance,
  }) {
    return FloatingLoop(
      delay: floatDuration.ms,
      distance: floatDistance,
      duration: floatDuration.ms,
      child: EntranceFade(
        delay: delay.ms,
        slideY: 0,
        scale: 0.6,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: SvgPicture.asset(
            asset,
            width: 22,
            height: 22,
            colorFilter:
                const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _HeroCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 24,
        size.width,
        size.height - 40,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
