import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _submitting = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.lines.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final ordersRepo = ref.read(ordersRepositoryProvider);
      switch (cart.purpose) {
        case CartPurpose.manufacturer:
          await ordersRepo.submitManufacturerOrder(
              cart.lines, _notesController.text.trim());
          ref.invalidate(manufacturerOrdersProvider);
          ref.read(cartProvider.notifier).clear();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Order submitted to manufacturer'),
            ),
          );
          context.go('/orders');
          break;
        case CartPurpose.shopOrder:
          await ordersRepo.createShopOrder(cart.shop!, cart.lines);
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
          final order =
              await ordersRepo.createDirectSale(cart.shop!, cart.lines);
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

  String get _title {
    final purpose = ref.watch(cartProvider).purpose;
    switch (purpose) {
      case CartPurpose.manufacturer:
        return 'My Cart';
      case CartPurpose.shopOrder:
        return 'Shop Order';
      case CartPurpose.directSale:
        return 'Direct Sale';
    }
  }

  String get _buttonLabel {
    final purpose = ref.watch(cartProvider).purpose;
    switch (purpose) {
      case CartPurpose.manufacturer:
        return 'Submit Order';
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
                            child: Row(
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
                                        line.product.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textMain,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        F.money(line.product.distributorPrice),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: theme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        F.money(line.lineTotal),
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                QtyStepper(
                                  qty: line.qty,
                                  onChanged: (v) => ref
                                      .read(cartProvider.notifier)
                                      .setQty(line.product.id, v),
                                ),
                              ],
                            ),
                          );
                        }
                        // Notes card
                        return AppCard(
                          child: TextField(
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
