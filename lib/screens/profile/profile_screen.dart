import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.brand.withValues(alpha: 0.14),
                          child: Text(
                            user.name.characters.first.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                        Text(
                          user.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusChip(
                          label: 'Distributor access',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(title: 'Distributor details'),
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow(
                            label: 'Company',
                            value: user.distributor.company),
                        InfoRow(label: 'Phone', value: user.distributor.phone),
                        InfoRow(
                            label: 'Address',
                            value: user.distributor.address),
                        InfoRow(
                          label: 'Credit limit',
                          value: 'Managed by manufacturer',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(title: 'App'),
                  AppCard(
                    child: Column(
                      children: [
                        _row(context, theme, Icons.info_outline_rounded,
                            'Version', '1.0.0'),
                        const Divider(height: 16),
                        _row(context, theme, Icons.shield_outlined,
                            'Security', 'App-restricted access'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign out?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign out',
                                  style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(authProvider.notifier).logout();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.danger),
                    label: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _row(BuildContext context, ThemeData theme, IconData icon,
      String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13.5, color: theme.textMain),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, color: theme.textSecondary),
        ),
      ],
    );
  }
}
