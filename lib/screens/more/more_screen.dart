import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';
import '../../models/finance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/update_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../settings/printer_settings_sheet.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final invoices = ref.watch(invoicesProvider).valueOrNull;

    final unpaid =
        invoices?.where((i) => i.status != InvoiceStatus.paid).length ?? 0;
    final totalInvoices = invoices?.length ?? 0;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'More'),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // --- Profile Hero Card ---
                      _buildProfileHero(context, theme, user),

                      const SizedBox(height: 14),

                      // --- Quick Metric Badges ---
                      _buildQuickMetrics(theme, user, unpaid, totalInvoices),

                      const SizedBox(height: 22),

                      // --- Section 1: Business & Records ---
                      SectionTitle(title: 'Records & Finance'),
                      _buildSectionCard(
                        theme,
                        children: [
                          _menuTile(
                            theme,
                            icon: LucideIcons.receiptText,
                            iconColor: AppColors.brand,
                            title: 'Invoices',
                            subtitle: 'Billing, settlements & payment history',
                            badge: unpaid > 0 ? '$unpaid unpaid' : null,
                            badgeColor: AppColors.warning,
                            onTap: () => context.push('/more/invoices'),
                          ),
                          _divider(theme),
                          _menuTile(
                            theme,
                            icon: LucideIcons.tag,
                            iconColor: const Color(0xFF10B981),
                            title: 'Price List',
                            subtitle: 'Custom wholesale pricing & variant rates',
                            onTap: () => context.push('/more/price-list'),
                          ),
                          _divider(theme),
                          _menuTile(
                            theme,
                            icon: LucideIcons.store,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Client Shops',
                            subtitle: 'Registered retailer outlets & contacts',
                            onTap: () => context.go('/shops'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // --- Section 2: Account & Security ---
                      SectionTitle(title: 'Account & Security'),
                      _buildSectionCard(
                        theme,
                        children: [
                          _menuTile(
                            theme,
                            icon: LucideIcons.user,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Distributor Profile',
                            subtitle: 'Personal details, company info & limits',
                            onTap: () => context.push('/more/profile'),
                          ),
                          _divider(theme),
                          _menuTile(
                            theme,
                            icon: LucideIcons.shieldCheck,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Security & Password',
                            subtitle: 'Change password & password reset links',
                            onTap: () => context.push('/more/profile'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // --- Section 3: App & System ---
                      SectionTitle(title: 'System & Preferences'),
                      _buildSectionCard(
                        theme,
                        children: [
                          _menuTile(
                            theme,
                            icon: LucideIcons.arrowUpCircle,
                            iconColor: const Color(0xFF10B981),
                            title: 'Check for Updates',
                            subtitle: 'Check for the latest distributor app release',
                            onTap: () => UpdateService.manualCheckForUpdates(context),
                          ),
                          _divider(theme),
                          _menuTile(
                            theme,
                            icon: LucideIcons.printer,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Printer Setup',
                            subtitle: 'Bluetooth & LAN thermal receipt settings',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const PrinterSettingsSheet(),
                              );
                            },
                          ),
                          _divider(theme),
                          _menuTile(
                            theme,
                            icon: LucideIcons.server,
                            iconColor: const Color(0xFF0EA5E9),
                            title: 'Server Setup',
                            subtitle: _serverSubtitle(),
                            onTap: () => context.push('/setup'),
                          ),
                          _divider(theme),
                          _menuTile(
                            theme,
                            icon: LucideIcons.logOut,
                            iconColor: AppColors.danger,
                            title: 'Sign Out',
                            subtitle: 'Log out of current distributor session',
                            textColor: AppColors.danger,
                            onTap: () => _confirmSignOut(context, ref),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- App Version Footer ---
                      Center(
                        child: Text(
                          'Inzeedo Distributor ERP • v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(
    BuildContext context,
    ThemeData theme,
    dynamic user,
  ) {
    final name = (user?.name ?? 'Distributor').toString();
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'D';
    final company = (user?.distributor?.company ?? user?.distributor?.name ?? '')
        .toString();
    final email = (user?.email ?? '').toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/more/profile'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      company.isNotEmpty ? company : email,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.glassBorder),
                ),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetrics(
    ThemeData theme,
    dynamic user,
    int unpaidInvoices,
    int totalInvoices,
  ) {
    final creditLimit = user?.distributor?.creditLimit ?? 0;
    final limitStr =
        creditLimit > 0 ? F.money(creditLimit) : 'Managed';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.creditCard,
                    size: 16,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Limit',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        limitStr,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    size: 16,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoices',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        unpaidInvoices > 0
                            ? '$unpaidInvoices Unpaid'
                            : '$totalInvoices Total',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: unpaidInvoices > 0
                              ? AppColors.warning
                              : theme.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      endIndent: 14,
      color: theme.glassBorder,
    );
  }

  Widget _menuTile(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textColor ?? theme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.brand)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? AppColors.brand,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: theme.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _serverSubtitle() {
    final url = AppConfig.apiBaseUrl;
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      return 'Localhost (Dev) • Tap to configure';
    }
    return 'Cloud Production • Tap to configure';
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign out?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out of your distributor account?',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
