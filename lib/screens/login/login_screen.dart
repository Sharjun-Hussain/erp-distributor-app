import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
