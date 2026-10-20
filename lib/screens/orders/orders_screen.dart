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
  int _segment = 0; // 0 = manufacturer, 1 = shop

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final segment = GoRouterState.of(context).uri.queryParameters['segment'];
    if (segment == 'shop') _segment = 1;
    if (segment == 'manufacturer') _segment = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Orders',
              bottom: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('To Manufacturer'),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Shop Orders'),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (v) => setState(() => _segment = v.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.brand.withValues(alpha: 0.14)
                        : theme.cardColor,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.brand
                        : theme.textSecondary,
                  ),
                  textStyle: WidgetStateProperty.all(
                    GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  side: WidgetStateProperty.all(
                    BorderSide(color: theme.surfaceMutedColor),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _segment == 0
                  ? _ManufacturerOrdersList()
                  : _ShopOrdersList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManufacturerOrdersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orders = ref.watch(manufacturerOrdersProvider);

    return orders.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            subtitle: 'Orders you place to the manufacturer appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(manufacturerOrdersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final o = list[index];
              return AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => context.push('/orders/mfr/${o.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.orderNumber,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${F.date(o.date)} • ${o.items.length} item(s)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatusChip(
                            label: o.status.label,
                            color: manufacturerStatusColor(o.status),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      F.money(o.total),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
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
