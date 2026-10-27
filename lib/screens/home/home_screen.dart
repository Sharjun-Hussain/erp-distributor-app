import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/orders.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/entrance.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final shopOrders = ref.watch(shopOrdersProvider);

    final pendingShopOrders = shopOrders.maybeWhen(
      data: (list) => list
          .where((o) =>
              o.status != ShopOrderStatus.delivered &&
              o.status != ShopOrderStatus.cancelled)
          .length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shopOrdersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              EntranceFade(
                delay: Duration.zero,
                slideY: 0.15,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.brand.withValues(alpha: 0.14),
                      child: Text(
                        (user?.name ?? 'D').characters.first.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? ''} 👋',
                            style: GoogleFonts.inter(
                              fontSize: 17,
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
                    IconButton(
                      onPressed: () => context.go('/more/profile'),
                      icon: const Icon(Icons.person_outline_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Credit summary
              EntranceFade(
                delay: 80.ms,
                slideY: 0.06,
                scale: 0.97,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brand, Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit Balance',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        F.money(user?.distributor.balance ?? 0),
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _miniLabel('Credit limit',
                              F.money(user?.distributor.creditLimit ?? 0)),
                          const Spacer(),
                          _miniLabel(
                              'Available',
                              F.money((user?.distributor.creditLimit ?? 0) -
                                  (user?.distributor.balance ?? 0))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: EntranceFade(
                      delay: 160.ms,
                      slideY: 0.12,
                      child: _quickAction(
                        context,
                        theme,
                        icon: LucideIcons.clipboardPlus,
                        label: 'Collect Order',
                        onTap: () => context.go('/orders/new-shop-order'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EntranceFade(
                      delay: 220.ms,
                      slideY: 0.12,
                      child: _quickAction(
                        context,
                        theme,
                        icon: LucideIcons.zap,
                        label: 'Direct Sale',
                        onTap: () => context.go('/orders/direct-sale'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EntranceFade(
                      delay: 280.ms,
                      slideY: 0.12,
                      child: _quickAction(
                        context,
                        theme,
                        icon: LucideIcons.store,
                        label: 'Shops',
                        onTap: () => context.go('/shops'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats
              EntranceFade(
                delay: 360.ms,
                slideY: 0.12,
                child: _statCard(
                  theme,
                  title: 'Open shop orders',
                  value: '$pendingShopOrders',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 20),

              // Recent shop orders
              EntranceFade(
                delay: 480.ms,
                slideY: 0.18,
                child: SectionTitle(
                  title: 'Recent shop orders',
                  trailing: TextButton(
                    onPressed: () => context.go('/orders'),
                    child: const Text('See all'),
                  ),
                ),
              ),
              shopOrders.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return EntranceFade(
                      delay: 540.ms,
                      child: const AppCard(
                        child: Text('No shop orders yet'),
                      ),
                    );
                  }
                  final cards = orders.take(3).map((o) => AppCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => context.go('/orders/shop/${o.id}'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: shopStatusColor(o.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.store,
                                size: 20,
                                color: shopStatusColor(o.status),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.shopName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: theme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${o.orderNumber} • ${F.shortDate(o.date)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  F.money(o.total),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: theme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusChip(
                                  label: o.status.label,
                                  color: shopStatusColor(o.status),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ));
                  return Column(
                    children: staggered(
                      cards.toList(),
                      start: 540.ms,
                      slideY: 0.10,
                    ),
                  );
                },
                loading: () => EntranceFade(
                  delay: 540.ms,
                  slideY: 0,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, _) => EntranceFade(
                  delay: 540.ms,
                  child: const AppCard(
                    child: Text('Could not load orders'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.brand, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: theme.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme, {
    required String title,
    required String value,
    required Color color,
  }) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textMain,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
