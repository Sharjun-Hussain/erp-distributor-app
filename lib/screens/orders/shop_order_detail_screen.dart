import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/orders.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';

final _shopOrderByIdProvider = Provider.family<ShopOrder?, String>((ref, id) {
  final orders = ref.watch(shopOrdersProvider).valueOrNull;
  if (orders == null) return null;
  try {
    return orders.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
});

class ShopOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ShopOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<ShopOrderDetailScreen> createState() =>
      _ShopOrderDetailScreenState();
}

class _ShopOrderDetailScreenState
    extends ConsumerState<ShopOrderDetailScreen> {
  bool _busy = false;

  ShopOrderStatus? get _nextStatus {
    final order = ref.read(_shopOrderByIdProvider(widget.orderId));
    if (order == null) return null;
    switch (order.status) {
      case ShopOrderStatus.collected:
        return ShopOrderStatus.processing;
      case ShopOrderStatus.processing:
        return ShopOrderStatus.loaded;
      case ShopOrderStatus.loaded:
        return ShopOrderStatus.delivered;
      case ShopOrderStatus.delivered:
      case ShopOrderStatus.cancelled:
        return null;
    }
  }

  String get _nextLabel {
    switch (_nextStatus) {
      case ShopOrderStatus.processing:
        return 'Start Processing';
      case ShopOrderStatus.loaded:
        return 'Mark as Loaded';
      case ShopOrderStatus.delivered:
        return 'Mark as Delivered';
      default:
        return '';
    }
  }

  Future<void> _advance() async {
    final next = _nextStatus;
    if (next == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .updateShopOrderStatus(widget.orderId, next);
      ref.invalidate(shopOrdersProvider);
      if (next == ShopOrderStatus.delivered) {
        ref.invalidate(invoicesProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .updateShopOrderStatus(widget.orderId, ShopOrderStatus.cancelled);
      ref.invalidate(shopOrdersProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openInvoice(ShopOrder order) {
    final invoices = ref.read(invoicesProvider).valueOrNull ?? [];
    final match = invoices.where((i) => i.invoiceNumber == order.invoiceNumber);
    if (match.isNotEmpty) {
      context.push('/more/invoices/${match.first.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${order.invoiceNumber}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = ref.watch(_shopOrderByIdProvider(widget.orderId));

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/orders');
      }
    }

    final canPop = context.canPop();

    if (order == null) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/orders');
        },
        child: Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            title: const Text('Shop order'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Order not found',
            subtitle: 'It may have been removed.',
          ),
        ),
      );
    }

    final next = _nextStatus;
    final canCancel = order.status == ShopOrderStatus.collected ||
        order.status == ShopOrderStatus.processing;

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
                title: order.orderNumber,
                showBack: true,
                onBack: handleBack,
                actions: [
                  StatusChip(
                    label: order.status.label,
                    color: shopStatusColor(order.status),
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
                        InfoRow(label: 'Shop', value: order.shopName, bold: true),
                        InfoRow(label: 'Address', value: order.shopAddress),
                        InfoRow(label: 'Phone', value: order.shopPhone),
                        InfoRow(label: 'Date', value: F.dateTime(order.date)),
                        InfoRow(label: 'Collected by', value: order.placedBy),
                        if (order.invoiceNumber != null)
                          InfoRow(label: 'Invoice', value: order.invoiceNumber!),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: theme.textSecondary,
                                ),
                              ),
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
                        StatusChip(
                          label: order.paymentStatus == 'paid'
                              ? 'Paid'
                              : order.paymentStatus == 'partially_paid'
                                  ? 'Partially paid'
                                  : 'Unpaid',
                          color: order.paymentStatus == 'paid'
                              ? AppColors.success
                              : order.paymentStatus == 'partially_paid'
                                  ? AppColors.warning
                                  : AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Call shop',
                          icon: Icons.phone_outlined,
                          onPressed: () async {
                            final uri = Uri(
                                scheme: 'tel', path: order.shopPhone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ),
                      if (order.invoiceNumber != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: SecondaryButton(
                            label: 'Invoice',
                            icon: LucideIcons.fileText,
                            onPressed: () => _openInvoice(order),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (next != null || canCancel)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(top: BorderSide(color: theme.glassBorder)),
                ),
                child: Row(
                  children: [
                    if (canCancel)
                      Expanded(
                        child: SecondaryButton(
                          label: 'Cancel',
                          onPressed: _busy ? null : _cancel,
                        ),
                      ),
                    if (canCancel && next != null) const SizedBox(width: 10),
                    if (next != null)
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: _nextLabel,
                          loading: _busy,
                          onPressed: _advance,
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
}

class _ItemRow extends StatelessWidget {
  final ShopOrderItem item;

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
