import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pos_sheets.dart';

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
  void dispose() {
    _notesController.dispose();
    _billDiscountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.lines.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final ordersRepo = ref.read(ordersRepositoryProvider);
      switch (cart.purpose) {
        case CartPurpose.shopOrder:
          await ordersRepo.createShopOrder(
            cart.shop!,
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
              content: Text('Shop order collected'),
            ),
          );
          context.go('/orders?segment=shop');
          break;
        case CartPurpose.directSale:
          final order = await ordersRepo.createDirectSale(
            cart.shop!,
            cart.lines,
            discount: cart.billDiscount,
            notes: _notesController.text.trim(),
          );
          ref.invalidate(shopOrdersProvider);
          ref.invalidate(invoicesProvider);
          ref.read(cartProvider.notifier).clear();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Invoice generated'),
            ),
          );
          context.go('/orders/shop/${order.id}');
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Could not submit. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: _title,
              showBack: true,
              onBack: () => context.go('/catalog'),
              actions: [
                if (cart.lines.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (cart.shop != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.store,
                          size: 16, color: AppColors.brand),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cart.shop!.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: cart.lines.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Your cart is empty',
                      subtitle: 'Add products from the catalog.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.lines.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index < cart.lines.length) {
                          final line = cart.lines[index];
                          return AppCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ProductAvatar(
                                      name: line.product.name,
                                      colorHex: line.product.colorHex,
                                      size: 42,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.displayName,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: theme.textMain,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${F.money(line.unitPrice)} × ${line.qty} ${line.product.unit}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                          if (line.discount > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Discount −${F.money(line.discount)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          F.money(line.lineTotal),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () => _editLine(line),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.pencil,
                                                  size: 13,
                                                  color: AppColors.brand),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Edit',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.brand,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    QtyStepper(
                                      qty: line.qty,
                                      onChanged: (v) => ref
                                          .read(cartProvider.notifier)
                                          .setQty(line.key, v),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => ref
                                          .read(cartProvider.notifier)
                                          .remove(line.key),
                                      child: const Icon(
                                          LucideIcons.trash2,
                                          size: 18,
                                          color: AppColors.danger),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        // Notes + bill discount card
                        return AppCard(
                          child: Column(
                            children: [
                              TextField(
                                controller: _notesController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Notes (optional)...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: theme.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: SvgPicture.asset(
                                            'assets/svg/field_note.svg'),
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints:
                                      const BoxConstraints(
                                          minWidth: 40, minHeight: 40),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 12),
                                ),
                              ),
                              Divider(color: theme.glassBorder, height: 20),
                              Row(
                                children: [
                                  const Icon(LucideIcons.tag,
                                      size: 16, color: AppColors.brand),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Bill discount',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textMain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller: _billDiscountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      textAlign: TextAlign.right,
                                      onChanged: (v) => ref
                                          .read(cartProvider.notifier)
                                          .setBillDiscount(
                                              double.tryParse(v) ?? 0),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        prefixText: 'Rs ',
                                        hintText: '0',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: theme.surfaceMutedColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (cart.lines.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(top: BorderSide(color: theme.glassBorder)),
                ),
                child: Column(
                  children: [
                    if (cart.discountTotal > 0) ...[
                      Row(
                        children: [
                          Text(
                            'Subtotal',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            F.money(cart.grossTotal),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Discount',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '−${F.money(cart.discountTotal)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
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
                          F.money(cart.total),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: _buttonLabel,
                      loading: _submitting,
                      onPressed: _submit,
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
