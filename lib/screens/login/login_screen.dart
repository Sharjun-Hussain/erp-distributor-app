import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../components/ui/app_button.dart';
import '../../components/ui/app_text_field.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPending = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _switchServer(String url, String name) async {
    await AppConfig.saveServerUrl(url);
    if (!mounted) return;
    setState(() {});
    toastification.show(
      context: context,
      title: Text('Switched to $name'),
      description: Text(AppConfig.apiBaseUrl),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _error = '';
      _isPending = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final authError =
          ref.read(authProvider).error ?? 'Invalid login credentials';
      toastification.show(
        context: context,
        title: const Text('Login Failed'),
        description: Text(authError),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
      setState(() {
        _isPending = false;
        _error = authError;
      });
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool loading = false;
    String? localError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
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
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Forgot Password',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your registered email address to receive a password reset link.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (localError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            localError!,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        'Email Address',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'distributor@example.com',
                          prefixIcon: const Icon(LucideIcons.mail, size: 16),
                          filled: true,
                          fillColor: theme.surfaceColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.glassBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.brand,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final email = emailCtrl.text.trim();
                                  if (email.isEmpty || !email.contains('@')) {
                                    setModalState(() => localError =
                                        'Please enter a valid email address');
                                    return;
                                  }

                                  setModalState(() {
                                    loading = true;
                                    localError = null;
                                  });

                                  try {
                                    final msg = await ref
                                        .read(authProvider.notifier)
                                        .forgotPassword(email);
                                    if (!modalCtx.mounted || !mounted) return;
                                    Navigator.of(modalCtx).pop();

                                    toastification.show(
                                      context: context,
                                      title: const Text('Reset Link Sent'),
                                      description: Text(msg),
                                      type: ToastificationType.success,
                                      style: ToastificationStyle.flatColored,
                                      autoCloseDuration:
                                          const Duration(seconds: 4),
                                    );
                                  } catch (err) {
                                    setModalState(() {
                                      loading = false;
                                      localError = err
                                          .toString()
                                          .replaceAll('Exception: ', '');
                                    });
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Send Reset Link',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    emailCtrl.dispose();
  }

  Widget _buildServerPill({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isPending ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: 0.12)
                : theme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? accentColor : theme.glassBorder,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? accentColor
                      : theme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                icon,
                size: 13,
                color: isActive ? accentColor : theme.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? accentColor : theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hyper Minimalist Aesthetic - Whitespace driven
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.surfaceMutedColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.glassBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.business_center_rounded,
                                color: AppColors.brand,
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surfaceMutedColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.glassBorder),
                      ),
                      child: Text(
                        'CoDesk Distribution',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                Text(
                  'Sign In.',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                    color: theme.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to CoDesk Distribution. Enter your credentials to access your routes and orders securely.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),

                const SizedBox(height: 44),

                AppTextField(
                  label: 'Email Address',
                  hintText: 'distributor@company.lk',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  disabled: _isPending,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                AppTextField(
                  label: 'Password',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  isPassword: true,
                  disabled: _isPending,
                ),

                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isPending ? null : _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                AppButton(
                  onPressed: _handleLogin,
                  isLoading: _isPending,
                  child: const Text('Continue'),
                ),

                const SizedBox(height: 32),

                // Server Setup Card with Shortcuts
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surfaceMutedColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.server,
                                size: 14,
                                color: theme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SERVER SETUP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () async {
                              await context.push('/setup');
                              if (mounted) setState(() {});
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Custom Setup',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    LucideIcons.chevronRight,
                                    size: 12,
                                    color: AppColors.brand,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Live Shortcut
                          Expanded(
                            child: _buildServerPill(
                              context: context,
                              label: 'Live',
                              icon: LucideIcons.cloudCheck,
                              isActive: AppConfig.isLive,
                              accentColor: Colors.green,
                              onTap: () => _switchServer(
                                AppConfig.productionBaseUrl,
                                'Live Server',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Localhost Shortcut
                          Expanded(
                            child: _buildServerPill(
                              context: context,
                              label: 'Localhost',
                              icon: LucideIcons.laptop,
                              isActive: AppConfig.isLocalhost,
                              accentColor: AppColors.brand,
                              onTap: () => _switchServer(
                                AppConfig.localhostBaseUrl,
                                'Localhost (5000)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Android Emulator Shortcut
                          Expanded(
                            child: _buildServerPill(
                              context: context,
                              label: '10.0.2.2',
                              icon: LucideIcons.smartphone,
                              isActive: AppConfig.isEmulator,
                              accentColor: Colors.orange,
                              onTap: () => _switchServer(
                                AppConfig.emulatorBaseUrl,
                                'Emulator (10.0.2.2)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConfig.apiBaseUrl,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: theme.textSecondary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Center(
                  child: Text(
                    'Access provided by your distributor administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
