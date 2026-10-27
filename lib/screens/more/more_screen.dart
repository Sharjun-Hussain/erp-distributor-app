import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/finance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final invoices = ref.watch(invoicesProvider).valueOrNull;

    final unpaid =
        invoices?.where((i) => i.status != InvoiceStatus.paid).length ?? 0;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const AppTopBar(title: 'More'),
            const SizedBox(height: 6),
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brand.withValues(alpha: 0.14),
                    child: Text(
                      (user?.name ?? 'D').characters.first.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: theme.textMain,
                          ),
                        ),
                        Text(
                          user?.distributor.company ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(title: 'Records'),
            _tile(
              context,
              theme,
              icon: LucideIcons.fileText,
              color: AppColors.brand,
              title: 'Invoices',
              badge: unpaid > 0 ? '$unpaid unpaid' : null,
              onTap: () => context.push('/more/invoices'),
            ),
            const SizedBox(height: 10),
            _tile(
              context,
              theme,
              icon: LucideIcons.tag,
              color: AppColors.info,
              title: 'Price List',
              onTap: () => context.push('/more/price-list'),
            ),
            const SizedBox(height: 16),
            SectionTitle(title: 'Account'),
            _tile(
              context,
              theme,
              icon: LucideIcons.user,
              color: AppColors.brand,
              title: 'Profile',
              onTap: () => context.push('/more/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textMain,
                ),
              ),
            ),
            if (badge != null)
              StatusChip(label: badge, color: color),
            Icon(Icons.chevron_right_rounded, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }
}
