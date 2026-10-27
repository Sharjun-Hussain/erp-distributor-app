import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Orders'),
            Expanded(child: _ShopOrdersList()),
          ],
        ),
      ),
    );
  }
}

class _ShopOrdersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orders = ref.watch(shopOrdersProvider);

    return orders.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: 'No shop orders',
            subtitle:
                'Collect orders from shops or create a direct sale to get started.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(shopOrdersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final o = list[index];
              return AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => context.push('/orders/shop/${o.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.shopName,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: theme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          F.money(o.total),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${o.orderNumber} • ${F.shortDate(o.date)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        StatusChip(
                          label: o.status.label,
                          color: shopStatusColor(o.status),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingShimmer(),
      error: (_, _) =>
          const EmptyState(icon: Icons.error_outline, title: 'Load failed'),
    );
  }
}
