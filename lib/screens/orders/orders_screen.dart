import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/orders.dart';
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

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(shopOrdersProvider);

    final allOrders = ordersAsync.valueOrNull ?? [];
    final collectCount = allOrders.where((o) => o.isCollect).length;
    final directCount = allOrders.where((o) => o.isDirectSale).length;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Orders'),
            // Styled Segment Tab Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.surfaceMutedColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.brand,
                unselectedLabelColor: theme.textSecondary,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                tabs: [
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('All'),
                        if (allOrders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(
                            count: allOrders.length,
                            isSelected: _tabController.index == 0,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.clipboardList, size: 14),
                        const SizedBox(width: 5),
                        const Text('Collect'),
                        if (collectCount > 0) ...[
                          const SizedBox(width: 5),
                          _CountBadge(
                            count: collectCount,
                            isSelected: _tabController.index == 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.truck, size: 14),
                        const SizedBox(width: 5),
                        const Text('Direct'),
                        if (directCount > 0) ...[
                          const SizedBox(width: 5),
                          _CountBadge(
                            count: directCount,
                            isSelected: _tabController.index == 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ShopOrdersTab(filter: _OrderWorkflowFilter.all),
                  _ShopOrdersTab(filter: _OrderWorkflowFilter.collect),
                  _ShopOrdersTab(filter: _OrderWorkflowFilter.directSale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.isSelected});
  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brand.withValues(alpha: 0.12)
            : theme.surfaceColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.brand : theme.textSecondary,
        ),
      ),
    );
  }
}

enum _OrderWorkflowFilter { all, collect, directSale }

class _ShopOrdersTab extends ConsumerWidget {
  const _ShopOrdersTab({required this.filter});
  final _OrderWorkflowFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(shopOrdersProvider);

    return orders.when(
      data: (list) {
        final filtered = list.where((o) {
          switch (filter) {
            case _OrderWorkflowFilter.all:
              return true;
            case _OrderWorkflowFilter.collect:
              return o.isCollect;
            case _OrderWorkflowFilter.directSale:
              return o.isDirectSale;
          }
        }).toList();

        if (filtered.isEmpty) {
          final isCollect = filter == _OrderWorkflowFilter.collect;
          final isDirect = filter == _OrderWorkflowFilter.directSale;
          return EmptyState(
            icon: isDirect
                ? LucideIcons.truck
                : (isCollect
                    ? LucideIcons.clipboardList
                    : Icons.store_mall_directory_outlined),
            title: isDirect
                ? 'No direct sales yet'
                : (isCollect ? 'No collect orders yet' : 'No shop orders'),
            subtitle: isDirect
                ? 'Sell directly on the spot to retail shops from your vehicle.'
                : 'Collect pre-orders from shops to deliver on scheduled routes.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(shopOrdersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final o = filtered[index];
              return _OrderCard(order: o);
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDirect = order.isDirectSale;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/orders/shop/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.shopName,
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
                F.money(order.total),
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Workflow Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDirect
                      ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDirect ? LucideIcons.truck : LucideIcons.clipboardList,
                      size: 11,
                      color: isDirect
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDirect ? 'Direct Sale' : 'Collect Order',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDirect
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.orderNumber} • ${F.shortDate(order.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: theme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(
                label: order.status.label,
                color: shopStatusColor(order.status),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
