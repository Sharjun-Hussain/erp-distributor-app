import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pos_sheets.dart';

final _productByIdProvider = Provider.family<Product?, String>((ref, id) {
  final products = ref.watch(productsProvider).valueOrNull;
  if (products == null) return null;
  try {
    return products.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = ref.watch(_productByIdProvider(productId));
    final cart = ref.watch(cartProvider);
    final localQty = product == null ? 0 : cart.qtyOfProduct(product.id);
    final sellingPrice = product == null
        ? 0.0
        : (product.sellingPrice > 0
            ? product.sellingPrice
            : product.distributorPrice);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/catalog');
      }
    }

    final canPop = context.canPop();

    if (product == null) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/catalog');
        },
        child: Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            title: const Text('Product'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Product not found',
            subtitle: 'It may have been removed.',
          ),
        ),
      );
    }

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
                title: 'Product',
                showBack: true,
                onBack: handleBack,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Center(
                    child: ProductAvatar(
                      name: product.name,
                      colorHex: product.colorHex,
                      size: 110,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.sku,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow(
                          label: 'Selling price',
                          value: '${F.money(sellingPrice)} / ${product.unit}',
                          bold: true,
                        ),
                        if (product.sellingPrice > 0)
                          InfoRow(
                            label: 'Cost price',
                            value: F.money(product.distributorPrice),
                          ),
                        InfoRow(
                          label: 'Retail price',
                          value: F.money(product.price),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'In cart',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textMain,
                            ),
                          ),
                        ),
                        Text(
                          '$localQty',
                          style: GoogleFonts.inter(
                            fontSize: 16,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Add to Cart',
                icon: Icons.add_shopping_cart_rounded,
                onPressed: () => showAddToCartSheet(
                  context,
                  product: product,
                  onConfirm: (variant, q, unitPrice, discount) {
                    final notifier = ref.read(cartProvider.notifier);
                    notifier.add(product,
                        variant: variant, qty: q, unitPrice: unitPrice);
                    if (discount > 0) {
                      final key = variant == null
                          ? product.id
                          : '${product.id}:${variant.id}';
                      notifier.setLineDiscount(key, discount);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('${product.name} added to cart'),
                      ),
                    );
                  },
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
