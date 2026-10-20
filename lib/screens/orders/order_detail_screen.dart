import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/orders.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';

final _orderByIdProvider =
    Provider.family<ManufacturerOrder?, String>((ref, id) {
  final orders = ref.watch(manufacturerOrdersProvider).valueOrNull;
  if (orders == null) return null;
  try {
    return orders.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
});

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final order = ref.watch(_orderByIdProvider(orderId));

    if (order == null) {
      return Scaffold(
        backgroundColor: theme.bgColor,
        appBar: AppBar(
          title: const Text('Order'),
          leading: const AppBackButton(),
        ),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Order not found',
          subtitle: 'It may have been removed.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: order.orderNumber,
              showBack: true,
              onBack: () => context.go('/orders'),
              actions: [
                StatusChip(
                  label: order.status.label,
                  color: manufacturerStatusColor(order.status),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow(label: 'Order number', value: order.orderNumber),
                        InfoRow(label: 'Date', value: F.date(order.date)),
                        if (order.notes.isNotEmpty)
                          InfoRow(label: 'Notes', value: order.notes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SectionTitle(title: 'Items'),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < order.items.length; i++) ...[
                          if (i > 0) const Divider(height: 16),
                          _ItemRow(item: order.items[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Row(
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          F.money(order.total),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ManufacturerOrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textMain,
                ),
              ),
              Text(
                '${item.qty} ${item.unit}(s) × ${F.money(item.unitPrice)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          F.money(item.lineTotal),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: theme.textMain,
          ),
        ),
      ],
    );
  }
}
