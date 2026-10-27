import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';
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
        title: Text(
          'Cancel order?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this order? This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Keep',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flatColored,
        title: Text('Invoice ${order.invoiceNumber}'),
        autoCloseDuration: const Duration(seconds: 2),
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
            title: const Text('Shop Order'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Order not found',
            subtitle: 'It may have been removed or cancelled.',
          ),
        ),
      );
    }

    final next = _nextStatus;
    final canCancel = order.status == ShopOrderStatus.collected ||
        order.status == ShopOrderStatus.processing;
    final statusColor = shopStatusColor(order.status);
    final isPaid = order.paymentStatus.toLowerCase() == 'paid';
    final isPartial = order.paymentStatus.toLowerCase() == 'partially_paid';

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
              // Top Bar
              AppTopBar(
                title: order.orderNumber,
                showBack: true,
                onBack: handleBack,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          order.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Scrollable Order Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(shopOrdersProvider);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    children: [
                      // --- Customer & Order Info Card ---
                      _buildShopOrderHeroCard(context, theme, order),

                      const SizedBox(height: 16),

                      // --- Quick Communication Action Buttons (Call / WhatsApp / Maps) ---
                      _buildContactActions(context, theme, order),

                      const SizedBox(height: 20),

                      // --- Order Items Card ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order Items',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textMain,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${order.items.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${order.items.fold<int>(0, (sum, i) => sum + i.qty)} Units',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Items Card List
                      _buildItemsCard(theme, order),

                      const SizedBox(height: 16),

                      // --- Financial / Payment Summary Card ---
                      _buildFinancialSummaryCard(theme, order, isPaid, isPartial),

                      if (order.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesCard(theme, order.notes),
                      ],

                      // If invoice is linked, provide dedicated invoice link
                      if (order.invoiceNumber != null) ...[
                        const SizedBox(height: 16),
                        _buildInvoiceCard(context, theme, order),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Bottom Workflow Action Bar
              if (next != null || canCancel)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(top: BorderSide(color: theme.glassBorder)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (canCancel)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _cancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel Order',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (canCancel && next != null) const SizedBox(width: 12),
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

  // ==========================================
  // SHOP & ORDER HERO CARD
  // ==========================================
  Widget _buildShopOrderHeroCard(BuildContext context, ThemeData theme, ShopOrder order) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Name & Tap to View Shop
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    order.shopName.isNotEmpty
                        ? order.shopName.characters.first.toUpperCase()
                        : 'S',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.shopName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.shopAddress.isNotEmpty ? order.shopAddress : 'No address provided',
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
              if (order.shopId.isNotEmpty)
                IconButton(
                  tooltip: 'View Shop Profile',
                  onPressed: () => context.push('/shops/${order.shopId}'),
                  icon: Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: AppColors.brand,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.glassBorder),
          const SizedBox(height: 12),

          // Metadata Grid: Phone, Date, Collected By, Invoice
          _detailRow(
            theme,
            icon: LucideIcons.phone,
            label: 'Phone',
            value: order.shopPhone.isNotEmpty ? order.shopPhone : '—',
          ),
          const SizedBox(height: 8),
          _detailRow(
            theme,
            icon: LucideIcons.calendar,
            label: 'Date',
            value: F.dateTime(order.date),
          ),
          const SizedBox(height: 8),
          _detailRow(
            theme,
            icon: LucideIcons.userCheck,
            label: 'Collected by',
            value: order.placedBy.isNotEmpty ? order.placedBy : '—',
          ),
          if (order.invoiceNumber != null && order.invoiceNumber!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _detailRow(
              theme,
              icon: LucideIcons.fileText,
              label: 'Invoice',
              value: order.invoiceNumber!,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.textSecondary.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.brand : theme.textMain,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CONTACT ACTIONS (CALL, WHATSAPP, MAPS)
  // ==========================================
  Widget _buildContactActions(BuildContext context, ThemeData theme, ShopOrder order) {
    final hasPhone = order.shopPhone.trim().isNotEmpty;
    final hasAddress = order.shopAddress.trim().isNotEmpty;

    return Row(
      children: [
        // Call Action
        Expanded(
          child: _contactButton(
            theme,
            icon: LucideIcons.phone,
            label: 'Call Shop',
            color: const Color(0xFF0EA5E9),
            enabled: hasPhone,
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: order.shopPhone);
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
              final cleanPhone = order.shopPhone.replaceAll(RegExp(r'[^0-9]'), '');
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
            label: 'Directions',
            color: const Color(0xFFF59E0B),
            enabled: hasAddress,
            onTap: () async {
              final query = Uri.encodeComponent('${order.shopName}, ${order.shopAddress}');
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.09) : theme.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.25) : theme.glassBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: enabled ? color : theme.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
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
  // COMPACT ITEMS CARD
  // ==========================================
  Widget _buildItemsCard(ThemeData theme, ShopOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.items.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 1,
          indent: 44,
          endIndent: 12,
          color: theme.glassBorder,
        ),
        itemBuilder: (context, i) {
          final item = order.items[i];
          final cleanTitle = _cleanItemTitle(item.productName);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Compact Index Badge
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Product Name & Quantity Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cleanTitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${item.qty} ${item.unit} × ${F.money(item.unitPrice)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.textSecondary,
                            ),
                          ),
                          if (item.discount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(-${F.money(item.discount)})',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Line Total
                Text(
                  F.money(item.lineTotal),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.textMain,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Removes redundant " - Default" or " · Default" variant suffixes from product titles
  String _cleanItemTitle(String title) {
    var result = title;
    // Handle " - Default", " - default", " · Default", " · default"
    result = result.replaceAll(RegExp(r'\s*[-·•]\s*Default\b', caseSensitive: false), '');
    return result.trim().isEmpty ? title : result.trim();
  }

  // ==========================================
  // FINANCIAL SUMMARY CARD
  // ==========================================
  Widget _buildFinancialSummaryCard(
    ThemeData theme,
    ShopOrder order,
    bool isPaid,
    bool isPartial,
  ) {
    final paymentBg = isPaid
        ? const Color(0xFF10B981).withValues(alpha: 0.12)
        : isPartial
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.danger.withValues(alpha: 0.12);
    final paymentColor = isPaid
        ? const Color(0xFF10B981)
        : isPartial
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                F.money(order.subtotal > 0 ? order.subtotal : order.total),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textMain,
                ),
              ),
            ],
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Discount',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  '-${F.money(order.discount)}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.glassBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    F.money(order.total),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.textMain,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: paymentBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: paymentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid
                          ? LucideIcons.checkCircle
                          : isPartial
                              ? LucideIcons.clock
                              : LucideIcons.alertCircle,
                      size: 13,
                      color: paymentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      order.paymentStatus.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: paymentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INVOICE CARD
  // ==========================================
  Widget _buildInvoiceCard(BuildContext context, ThemeData theme, ShopOrder order) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openInvoice(order),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linked Invoice',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                    Text(
                      order.invoiceNumber!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Invoice',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 13,
                      color: Color(0xFF0EA5E9),
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

  // ==========================================
  // NOTES CARD
  // ==========================================
  Widget _buildNotesCard(ThemeData theme, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.stickyNote, size: 14, color: theme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
