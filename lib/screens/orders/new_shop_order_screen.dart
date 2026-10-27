import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Shop picker for both workflows:
/// - /orders/new-shop-order  → collect order (invoice later at warehouse)
/// - /orders/direct-sale     → sell on the spot (instant invoice)
class NewShopOrderScreen extends ConsumerWidget {
  const NewShopOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shops = ref.watch(shopsProvider);
    final isDirect =
        GoRouterState.of(context).uri.path == '/orders/direct-sale';

    void pick(String shopId) {
      final list = shops.valueOrNull ?? [];
      final shop = list.firstWhere((s) => s.id == shopId);
      final notifier = ref.read(cartProvider.notifier);
      if (isDirect) {
        notifier.startDirectSale(shop);
      } else {
        notifier.startShopOrder(shop);
      }
      context.go('/catalog');
    }

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/orders');
      }
    }

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/orders');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: isDirect ? 'Direct Sale' : 'Collect Order',
                showBack: true,
                onBack: handleBack,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      isDirect ? LucideIcons.zap : LucideIcons.clipboardList,
                      color: AppColors.brand,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isDirect
                            ? 'You have the goods with you — pick the shop to invoice and deliver now.'
                            : 'Pick the shop you collected this order from. Warehouse will process and deliver.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: shops.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'No shops yet',
                      subtitle: 'Add a shop first from the Shops tab.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final shop = list[index];
                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => pick(shop.id),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_mall_directory_rounded,
                                color: AppColors.brand,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textMain,
                                    ),
                                  ),
                                  Text(
                                    shop.address,
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
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.textSecondary,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingShimmer(),
                error: (_, _) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load shops',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
