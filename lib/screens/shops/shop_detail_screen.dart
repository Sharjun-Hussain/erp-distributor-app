import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/orders.dart';
import '../../models/shop.dart';
import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';

final _shopByIdProvider = Provider.family<Shop?, String>((ref, id) {
  final shops = ref.watch(shopsProvider).valueOrNull;
  if (shops == null) return null;
  try {
    return shops.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shop = ref.watch(_shopByIdProvider(shopId));

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/shops');
      }
    }

    final canPop = context.canPop();

    if (shop == null) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/shops');
        },
        child: Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            title: const Text('Shop Details'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Shop not found',
            subtitle: 'It may have been removed or you do not have permission to view it.',
          ),
        ),
      );
    }

    final orders = ref.watch(shopOrdersProvider).valueOrNull ?? [];
    final shopOrders = orders.where((o) => o.shopId == shop.id).toList();
    shopOrders.sort((a, b) => b.date.compareTo(a.date));

    final totalOrderValue = shopOrders.fold<double>(0.0, (sum, o) => sum + o.total);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/shops');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'Shop Profile',
                showBack: true,
                onBack: handleBack,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.glassBorder),
                    ),
                    child: IconButton(
                      tooltip: 'Edit Shop',
                      onPressed: () => context.push('/shops/$shopId/edit'),
                      icon: Icon(
                        LucideIcons.pencil,
                        size: 17,
                        color: theme.textMain,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(shopsProvider);
                    ref.invalidate(shopOrdersProvider);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // --- Hero Header Card ---
                      _buildShopHeroCard(context, theme, shop),

                      const SizedBox(height: 16),

                      // --- Quick Financial Metric Cards ---
                      _buildFinancialCards(theme, shop, shopOrders.length, totalOrderValue),

                      const SizedBox(height: 16),

                      // --- Quick Sales / Order Action Bar ---
                      _buildOrderActions(context, ref, theme, shop),

                      const SizedBox(height: 14),

                      // --- Direct Contact Action Buttons (Call / WhatsApp / Map) ---
                      _buildContactActions(context, theme, shop),

                      const SizedBox(height: 24),

                      // --- Contact & Location Information Details ---
                      SectionTitle(title: 'Shop Information'),
                      const SizedBox(height: 8),
                      _buildInfoCard(context, theme, shop),

                      const SizedBox(height: 24),

                      // --- Recent Orders Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order History',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textMain,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${shopOrders.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (shopOrders.length > 5)
                            TextButton(
                              onPressed: () => context.go('/orders?segment=shop'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View all',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    LucideIcons.chevronRight,
                                    size: 14,
                                    color: AppColors.brand,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (shopOrders.isEmpty)
                        _buildEmptyOrdersCard(context, ref, theme, shop)
                      else
                        ...shopOrders.take(5).map((o) => _buildOrderCard(context, theme, o)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HERO HEADER CARD
  // ==========================================
  Widget _buildShopHeroCard(BuildContext context, ThemeData theme, Shop shop) {
    final initial = shop.name.trim().isNotEmpty
        ? shop.name.trim().characters.first.toUpperCase()
        : 'S';
    final hasAddress = shop.address.trim().isNotEmpty;
    final isActive = shop.isActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Avatar with Gradient
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 24,
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
                        Expanded(
                          child: Text(
                            shop.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: theme.textMain,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF10B981) : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isActive ? 'Active Client' : 'Inactive',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? const Color(0xFF10B981) : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (shop.contactPerson.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.user,
                                  size: 12,
                                  color: theme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    shop.contactPerson,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasAddress) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.surfaceColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shop.address,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // FINANCIAL METRIC CARDS
  // ==========================================
  Widget _buildFinancialCards(
    ThemeData theme,
    Shop shop,
    int orderCount,
    double totalOrderValue,
  ) {
    final hasBalance = shop.balance > 0;
    final creditLimit = shop.creditLimit;
    final creditLimitStr = creditLimit > 0 ? F.money(creditLimit) : 'No Limit';

    return Row(
      children: [
        // Outstanding Balance Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: hasBalance
                  ? AppColors.danger.withValues(alpha: 0.06)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasBalance
                    ? AppColors.danger.withValues(alpha: 0.25)
                    : theme.glassBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: hasBalance ? AppColors.danger : theme.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: (hasBalance ? AppColors.danger : const Color(0xFF10B981))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        hasBalance ? LucideIcons.alertCircle : LucideIcons.checkCircle,
                        size: 13,
                        color: hasBalance ? AppColors.danger : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  F.money(shop.balance),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: hasBalance ? AppColors.danger : theme.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Credit Limit Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Credit Limit',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.creditCard,
                        size: 13,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  creditLimitStr,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ORDER ACTIONS: NEW ORDER & SELL NOW
  // ==========================================
  Widget _buildOrderActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Shop shop,
  ) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(cartProvider.notifier).startShopOrder(shop);
                context.go('/catalog');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.clipboardPlus, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'New Order',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(cartProvider.notifier).startDirectSale(shop);
                context.go('/catalog');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.zap, size: 18, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      'Direct Sale',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DIRECT CONTACT ACTIONS (Call, WhatsApp, Maps)
  // ==========================================
  Widget _buildContactActions(BuildContext context, ThemeData theme, Shop shop) {
    final hasPhone = shop.phone.trim().isNotEmpty;
    final hasAddress = shop.address.trim().isNotEmpty;

    return Row(
      children: [
        // Call Action
        Expanded(
          child: _contactButton(
            theme,
            icon: LucideIcons.phone,
            label: 'Call',
            color: const Color(0xFF0EA5E9),
            enabled: hasPhone,
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: shop.phone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // WhatsApp Action
        Expanded(
          child: _contactButton(
            theme,
            icon: LucideIcons.messageSquare,
            label: 'WhatsApp',
            color: const Color(0xFF10B981),
            enabled: hasPhone,
            onTap: () async {
              final cleanPhone = shop.phone.replaceAll(RegExp(r'[^0-9]'), '');
              final formattedPhone = cleanPhone.startsWith('0')
                  ? '94${cleanPhone.substring(1)}'
                  : cleanPhone.startsWith('94')
                      ? cleanPhone
                      : '94$cleanPhone';

              final uri = Uri.parse('https://wa.me/$formattedPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // Map Action
        Expanded(
          child: _contactButton(
            theme,
            icon: LucideIcons.mapPin,
            label: 'Maps',
            color: const Color(0xFFF59E0B),
            enabled: hasAddress,
            onTap: () async {
              final query = Uri.encodeComponent('${shop.name}, ${shop.address}');
              final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _contactButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.09) : theme.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.3) : theme.glassBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: enabled ? color : theme.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: enabled ? color : theme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SHOP INFORMATION CARD
  // ==========================================
  Widget _buildInfoCard(BuildContext context, ThemeData theme, Shop shop) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoTile(
            context,
            theme,
            icon: LucideIcons.user,
            iconColor: const Color(0xFF6366F1),
            label: 'Contact Person',
            value: shop.contactPerson.trim().isNotEmpty ? shop.contactPerson : 'Not specified',
            canCopy: shop.contactPerson.trim().isNotEmpty,
          ),
          _divider(theme),
          _infoTile(
            context,
            theme,
            icon: LucideIcons.phone,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Phone Number',
            value: shop.phone.trim().isNotEmpty ? shop.phone : 'Not specified',
            canCopy: shop.phone.trim().isNotEmpty,
          ),
          _divider(theme),
          _infoTile(
            context,
            theme,
            icon: LucideIcons.mail,
            iconColor: const Color(0xFFEC4899),
            label: 'Email Address',
            value: shop.email.trim().isNotEmpty ? shop.email : 'Not specified',
            canCopy: shop.email.trim().isNotEmpty,
          ),
          _divider(theme),
          _infoTile(
            context,
            theme,
            icon: LucideIcons.mapPin,
            iconColor: const Color(0xFFF59E0B),
            label: 'Store Address',
            value: shop.address.trim().isNotEmpty ? shop.address : 'Not specified',
            canCopy: shop.address.trim().isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool canCopy = false,
  }) {
    return InkWell(
      onTap: canCopy
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              toastification.show(
                context: context,
                type: ToastificationType.success,
                style: ToastificationStyle.flatColored,
                title: Text('$label copied to clipboard'),
                autoCloseDuration: const Duration(seconds: 2),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
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
                      color: value == 'Not specified'
                          ? theme.textSecondary.withValues(alpha: 0.6)
                          : theme.textMain,
                    ),
                  ),
                ],
              ),
            ),
            if (canCopy)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  LucideIcons.copy,
                  size: 14,
                  color: theme.textSecondary.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      endIndent: 16,
      color: theme.glassBorder,
    );
  }

  // ==========================================
  // ORDERS LIST & ORDER CARDS
  // ==========================================
  Widget _buildEmptyOrdersCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Shop shop,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shoppingBag,
              size: 28,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Orders Yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a new pre-order or direct sale for this shop.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: theme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref.read(cartProvider.notifier).startShopOrder(shop);
              context.go('/catalog');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            label: Text(
              'Create First Order',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, ThemeData theme, ShopOrder order) {
    final color = shopStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/orders/shop/${order.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Order Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.fileText,
                      size: 20,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Order Number & Date & Item Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              order.orderNumber,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.status.label,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${F.date(order.date)} • ${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      F.money(order.total),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.paymentStatus.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: order.paymentStatus.toLowerCase() == 'paid'
                            ? const Color(0xFF10B981)
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
