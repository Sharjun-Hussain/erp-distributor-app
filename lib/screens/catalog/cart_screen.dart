import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/catalog.dart';
import '../../models/shop.dart';
import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pos_sheets.dart';
import '../orders/widgets/payment_collection_sheet.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _submitting = false;
  final _notesController = TextEditingController();
  final _billDiscountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = ref.read(cartProvider).billDiscount;
    if (d > 0) {
      _billDiscountController.text =
          d == d.roundToDouble() ? d.toInt().toString() : d.toString();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _billDiscountController.dispose();
    super.dispose();
  }

  Future<Shop?> _pickShop(BuildContext context) async {
    final searchController = TextEditingController();
    try {
      return await showModalBottomSheet<Shop>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          String query = '';
          return StatefulBuilder(
            builder: (context, setSB) {
              final shopsAsync = ref.watch(shopsProvider);
              return Container(
                height: MediaQuery.of(ctx).size.height * 0.75,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.surfaceMutedColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Target Shop',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the client shop this order will be delivered to.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SearchField(
                      controller: searchController,
                      hint: 'Search shops by name, address...',
                      onChanged: (v) =>
                          setSB(() => query = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: shopsAsync.when(
                      data: (shops) {
                        final filtered = query.isEmpty
                            ? shops
                            : shops
                                .where((s) =>
                                    s.name.toLowerCase().contains(query) ||
                                    s.address.toLowerCase().contains(query))
                                .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No shops found',
                              style:
                                  GoogleFonts.inter(color: theme.textSecondary),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final shop = filtered[i];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(ctx).pop(shop),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.surfaceColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: theme.glassBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.brand
                                            .withValues(alpha: 0.12),
                                        child: Text(
                                          shop.name.characters.first
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shop.name,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.5,
                                                color: theme.textMain,
                                              ),
                                            ),
                                            if (shop.address.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                shop.address,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: theme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        LucideIcons.chevronRight,
                                        size: 16,
                                        color: AppColors.brand,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(
                        child: Text('Failed to load shops: $e'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    } finally {
      searchController.dispose();
    }
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.lines.isEmpty || _submitting) return;

    // Ensure target shop is selected
    Shop? targetShop = cart.shop;
    if (targetShop == null) {
      targetShop = await _pickShop(context);
      if (targetShop == null || !mounted) {
        return; // User cancelled shop selection
      }
      ref.read(cartProvider.notifier).setShop(targetShop);
    }

    if (cart.purpose == CartPurpose.directSale) {
      final payment = await PaymentCollectionSheet.show(
        context,
        orderTotal: cart.total,
        shopName: targetShop.name,
        title: 'Direct Sale Payment',
      );
      if (payment == null || !mounted) return;

      setState(() => _submitting = true);
      try {
        final ordersRepo = ref.read(ordersRepositoryProvider);
        final order = await ordersRepo.createDirectSale(
          targetShop,
          cart.lines,
          discount: cart.billDiscount,
          notes: _notesController.text.trim(),
          cashAmount: payment.cashAmount,
          bankAmount: payment.bankAmount,
          bankRef: payment.bankRef,
          chequeAmount: payment.chequeAmount,
          chequeNo: payment.chequeNo,
          chequeDate: payment.chequeDate,
          chequeBank: payment.chequeBank,
        );
        ref.invalidate(shopOrdersProvider);
        ref.invalidate(invoicesProvider);
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Direct sale & invoice generated successfully'),
          ),
        );
        context.go('/orders/shop/${order.id}');
      } catch (e, stack) {
        debugPrint('[Cart] Submit error: $e\n$stack');
        if (mounted) {
          final message = e is ApiException
              ? e.message
              : 'Could not submit: ${e.toString().replaceAll("Exception: ", "")}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text(message),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final ordersRepo = ref.read(ordersRepositoryProvider);
      await ordersRepo.createShopOrder(
        targetShop,
        cart.lines,
        discount: cart.billDiscount,
        notes: _notesController.text.trim(),
      );
      ref.invalidate(shopOrdersProvider);
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Shop order collected successfully'),
        ),
      );
      context.go('/orders?segment=shop');
    } catch (e, stack) {
      debugPrint('[Cart] Submit error: $e\n$stack');
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'Could not submit: ${e.toString().replaceAll("Exception: ", "")}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(message),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editLine(CartLine line) async {
    final edited = await showLineEditSheet(context, line: line);
    if (edited == null) return;
    final notifier = ref.read(cartProvider.notifier);
    notifier.setUnitPrice(line.key, edited.unitPrice);
    notifier.setLineDiscount(line.key, edited.discount);
  }

  String get _title {
    final purpose = ref.watch(cartProvider).purpose;
    switch (purpose) {
      case CartPurpose.shopOrder:
        return 'Shop Order';
      case CartPurpose.directSale:
        return 'Direct Sale';
    }
  }

  String get _buttonLabel {
    final purpose = ref.watch(cartProvider).purpose;
    switch (purpose) {
      case CartPurpose.shopOrder:
        return 'Collect Order';
      case CartPurpose.directSale:
        return 'Generate Invoice';
    }
  }

  Widget _buildCartItemCard({
    required BuildContext context,
    required CartLine line,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Product Details, Line Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductAvatar(
                name: line.product.name,
                colorHex: line.product.colorHex,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: theme.glassBorder),
                          ),
                          child: Text(
                            '${F.money(line.unitPrice)} / ${line.product.unit}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                        if (line.discount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '−${F.money(line.discount)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                F.money(line.lineTotal),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: theme.glassBorder, height: 1),
          const SizedBox(height: 12),

          // Bottom Row: Stepper and Actions
          Row(
            children: [
              // Stepper Pill
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: line.qty > 1
                            ? () => ref
                                .read(cartProvider.notifier)
                                .setQty(line.key, line.qty - 1)
                            : null,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: line.qty > 1
                                ? theme.textMain
                                : theme.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${line.qty}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: theme.textMain,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref
                            .read(cartProvider.notifier)
                            .setQty(line.key, line.qty + 1),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: theme.textMain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Edit Line
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _editLine(line),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.pencil,
                          size: 14,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete Item
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      ref.read(cartProvider.notifier).remove(line.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/catalog');
      }
    }

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/catalog');
        }
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: _title,
                showBack: true,
                onBack: handleBack,
                actions: [
                  TextButton.icon(
                    onPressed: handleBack,
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 15,
                      color: AppColors.brand,
                    ),
                    label: Text(
                      'Add Items',
                      style: GoogleFonts.inter(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (cart.lines.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(cartProvider.notifier).clear(),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),

              // Shop Selector (Compact One-Button)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final picked = await _pickShop(context);
                      if (picked != null) {
                        ref.read(cartProvider.notifier).setShop(picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: cart.shop != null
                            ? AppColors.brand.withValues(alpha: 0.08)
                            : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cart.shop != null
                              ? AppColors.brand.withValues(alpha: 0.25)
                              : Colors.amber.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.store,
                            size: 16,
                            color: cart.shop != null
                                ? AppColors.brand
                                : (Colors.amber[700] ?? Colors.amber),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cart.shop != null
                                  ? cart.shop!.name
                                  : 'Select Client Shop',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: cart.shop != null
                                    ? theme.textMain
                                    : (Colors.amber[700] ?? Colors.amber),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cart.shop != null ? 'Change' : 'Select',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cart.shop != null
                                  ? AppColors.brand
                                  : (Colors.amber[700] ?? Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: cart.shop != null
                                ? AppColors.brand
                                : (Colors.amber[700] ?? Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: cart.lines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: theme.surfaceColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.shoppingBag,
                                  size: 48,
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Your cart is empty',
                                style: GoogleFonts.inter(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textMain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Browse the catalog and add products to start an order.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: theme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              OutlinedButton.icon(
                                onPressed: handleBack,
                                icon: const Icon(LucideIcons.arrowLeft, size: 16),
                                label: const Text('Browse Catalog'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          // Cart Items List
                          ...cart.lines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCartItemCard(
                                context: context,
                                line: line,
                                theme: theme,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Bill discount & Notes Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: theme.glassBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bill discount row
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.brand
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        LucideIcons.tag,
                                        size: 16,
                                        color: AppColors.brand,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bill Discount',
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: theme.textMain,
                                            ),
                                          ),
                                          Text(
                                            'Overall order discount',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 125,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.surfaceColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.surfaceMutedColor,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Rs',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _billDiscountController,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                      decimal: true),
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: theme.textMain,
                                              ),
                                              onChanged: (v) => ref
                                                  .read(cartProvider.notifier)
                                                  .setBillDiscount(
                                                      double.tryParse(v) ?? 0),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: '0',
                                                hintStyle: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textSecondary
                                                      .withValues(alpha: 0.5),
                                                ),
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Divider(color: theme.glassBorder, height: 1),
                                const SizedBox(height: 12),

                                // Notes input
                                TextField(
                                  controller: _notesController,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: theme.textMain,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Add order notes or instructions...',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: theme.textSecondary
                                          .withValues(alpha: 0.6),
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 20, left: 2, right: 8),
                                      child: Icon(
                                        LucideIcons.fileText,
                                        size: 16,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                    prefixIconConstraints:
                                        const BoxConstraints(minWidth: 26),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Order Summary Breakdown Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: theme.glassBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.receipt,
                                          size: 15,
                                          color: theme.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ORDER BREAKDOWN',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: theme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.surfaceColor,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: theme.glassBorder),
                                      ),
                                      child: Text(
                                        '${cart.lines.length} ${cart.lines.length == 1 ? 'item' : 'items'} • ${cart.itemCount} units',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Subtotal
                                Row(
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      F.money(cart.grossTotal),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textMain,
                                      ),
                                    ),
                                  ],
                                ),

                                if (cart.discountTotal > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Total Discounts',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '−${F.money(cart.discountTotal)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 12),
                                Divider(color: theme.glassBorder, height: 1),
                                const SizedBox(height: 12),

                                // Net Payable
                                Row(
                                  children: [
                                    Text(
                                      'Net Payable',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: theme.textMain,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      F.money(cart.total),
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.brand,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              // Sticky Checkout Footer
              if (cart.lines.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border:
                        Border(top: BorderSide(color: theme.glassBorder)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total (${cart.itemCount} units)',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                F.money(cart.total),
                                style: GoogleFonts.inter(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: theme.textMain,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 6,
                          child: PrimaryButton(
                            label: _buttonLabel,
                            icon: cart.purpose == CartPurpose.directSale
                                ? LucideIcons.fileCheck2
                                : LucideIcons.checkCheck,
                            loading: _submitting,
                            onPressed: _submit,
                          ),
                        ),
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
}
