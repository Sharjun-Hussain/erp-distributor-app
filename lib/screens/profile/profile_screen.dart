import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../config/app_config.dart';
import '../../models/auth.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/more');
      }
    }

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/more');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'Profile',
                showBack: true,
                onBack: handleBack,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        // --- User Header Hero Card ---
                        _buildUserHeader(context, theme, user),

                    const SizedBox(height: 24),

                    // --- Distributor Details ---
                    SectionTitle(title: 'Distributor Details'),
                    _buildDistributorDetailsCard(theme, user),

                    const SizedBox(height: 24),

                    // --- Security & Password ---
                    SectionTitle(title: 'Security & Access'),
                    _buildSecurityCard(context, ref, theme, user),

                    const SizedBox(height: 24),

                    // --- App & System Info ---
                    SectionTitle(title: 'App & System'),
                    _buildAppCard(theme),

                    const SizedBox(height: 28),

                    // --- Sign Out Button ---
                    _buildSignOutButton(context, ref),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, ThemeData theme, DistributorUser user) {
    final initial = user.name.isNotEmpty ? user.name.characters.first.toUpperCase() : 'D';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.mail, size: 13, color: theme.textSecondary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Distributor Access',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributorDetailsCard(ThemeData theme, DistributorUser user) {
    final company = user.distributor.company.isNotEmpty
        ? user.distributor.company
        : (user.distributor.name.isNotEmpty ? user.distributor.name : 'Not configured');

    final phone = user.distributor.phone.isNotEmpty
        ? user.distributor.phone
        : (user.phone.isNotEmpty ? user.phone : 'Not provided');

    final address = user.distributor.address.isNotEmpty
        ? user.distributor.address
        : 'Not provided';

    final creditLimit = user.distributor.creditLimit > 0
        ? F.money(user.distributor.creditLimit)
        : 'Managed by manufacturer';

    return AppCard(
      child: Column(
        children: [
          _detailTile(
            theme,
            icon: LucideIcons.building2,
            iconColor: AppColors.brand,
            label: 'Company',
            value: company,
          ),
          const Divider(height: 16),
          _detailTile(
            theme,
            icon: LucideIcons.phone,
            iconColor: const Color(0xFF10B981),
            label: 'Phone',
            value: phone,
          ),
          const Divider(height: 16),
          _detailTile(
            theme,
            icon: LucideIcons.mapPin,
            iconColor: const Color(0xFFF59E0B),
            label: 'Address',
            value: address,
          ),
          const Divider(height: 16),
          _detailTile(
            theme,
            icon: LucideIcons.creditCard,
            iconColor: const Color(0xFF8B5CF6),
            label: 'Credit Limit',
            value: creditLimit,
          ),
        ],
      ),
    );
  }

  Widget _detailTile(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              if (isNarrow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: theme.textMain,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecurityCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    DistributorUser user,
  ) {
    return AppCard(
      child: Column(
        children: [
          // Change Password Action Tile
          InkWell(
            onTap: () => _showChangePasswordSheet(context, ref),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.keyRound,
                      size: 16,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your current account password',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: theme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 20),

          // Forgot Password Action Tile
          InkWell(
            onTap: () => _handleForgotPassword(context, ref, user.email),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.mailQuestion,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forgot Password?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Send password reset link to your email',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(ThemeData theme) {
    final serverUrl = AppConfig.apiBaseUrl;
    final isLocal = serverUrl.contains('localhost') || serverUrl.contains('127.0.0.1');

    return AppCard(
      child: Column(
        children: [
          _row(
            theme,
            LucideIcons.info,
            'Version',
            '1.0.0 (Build 100)',
          ),
          const Divider(height: 16),
          _row(
            theme,
            LucideIcons.server,
            'Server',
            isLocal ? 'Localhost (Dev)' : 'Production Cloud',
          ),
          const Divider(height: 16),
          _row(
            theme,
            LucideIcons.shieldCheck,
            'Security',
            'App-restricted access (JWT)',
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Sign out?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Are you sure you want to log out of your distributor account?',
              style: GoogleFonts.inter(fontSize: 13.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(authProvider.notifier).logout();
        }
      },
      icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.danger),
      label: Text(
        'Sign Out',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.danger,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _row(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textMain,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handleForgotPassword(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Send a password reset link to $email?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final msg = await ref.read(authProvider.notifier).forgotPassword(email);
      if (!context.mounted) return;
      toastification.show(
        context: context,
        title: const Text('Reset Link Sent'),
        description: Text(msg),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!context.mounted) return;
      toastification.show(
        context: context,
        title: const Text('Request Failed'),
        description: Text(e.toString().replaceAll('Exception: ', '')),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _showChangePasswordSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool loading = false;
    String? localError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        'Change Password',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your current password and pick a strong new password.',
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

                      // Current Password
                      Text(
                        'Current Password',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: currentPassCtrl,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          prefixIcon: const Icon(LucideIcons.lock, size: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                            ),
                            onPressed: () =>
                                setModalState(() => obscureCurrent = !obscureCurrent),
                          ),
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

                      const SizedBox(height: 14),

                      // New Password
                      Text(
                        'New Password',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Minimum 6 characters',
                          prefixIcon: const Icon(LucideIcons.key, size: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                            ),
                            onPressed: () =>
                                setModalState(() => obscureNew = !obscureNew),
                          ),
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

                      const SizedBox(height: 14),

                      // Confirm Password
                      Text(
                        'Confirm New Password',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          prefixIcon: const Icon(LucideIcons.checkCheck, size: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                            ),
                            onPressed: () => setModalState(
                                () => obscureConfirm = !obscureConfirm),
                          ),
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

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final current = currentPassCtrl.text.trim();
                                  final newPass = newPassCtrl.text.trim();
                                  final confirm = confirmPassCtrl.text.trim();

                                  if (current.isEmpty) {
                                    setModalState(() =>
                                        localError = 'Please enter your current password');
                                    return;
                                  }
                                  if (newPass.length < 6) {
                                    setModalState(() => localError =
                                        'New password must be at least 6 characters');
                                    return;
                                  }
                                  if (newPass != confirm) {
                                    setModalState(() =>
                                        localError = 'New passwords do not match');
                                    return;
                                  }

                                  setModalState(() {
                                    loading = true;
                                    localError = null;
                                  });

                                  try {
                                    await ref
                                        .read(authProvider.notifier)
                                        .changePassword(
                                          currentPassword: current,
                                          newPassword: newPass,
                                        );
                                    if (!modalContext.mounted) return;
                                    Navigator.of(modalContext).pop();

                                    toastification.show(
                                      context: context,
                                      title: const Text('Password Updated'),
                                      description: const Text(
                                          'Your password was changed successfully.'),
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
                                  'Update Password',
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

    currentPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
  }
}
