import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

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
    final localQty = product == null ? 0 : cart.qtyOf(product.id);

    if (product == null) {
      return Scaffold(
        backgroundColor: theme.bgColor,
        appBar: AppBar(
          title: const Text('Product'),
          leading: const AppBackButton(),
        ),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Product not found',
          subtitle: 'It may have been removed.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(
              title: 'Product',
              showBack: true,
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
                          label: 'Your price',
                          value:
                              '${F.money(product.distributorPrice)} / ${product.unit}',
                          bold: true,
                        ),
                        InfoRow(
                          label: 'Retail price',
                          value: F.money(product.price),
                        ),
                        InfoRow(
                          label: 'Available stock',
                          value: '${F.qty(product.stock)} ${product.unit}s',
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
                            'Quantity',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textMain,
                            ),
                          ),
                        ),
                        QtyStepper(
                          qty: localQty,
                          onChanged: (v) =>
                              ref.read(cartProvider.notifier).setQty(product.id, v),
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
                label: localQty > 0
                    ? 'Update Cart • ${F.money(product.distributorPrice * localQty)}'
                    : 'Add to Cart',
                icon: Icons.add_shopping_cart_rounded,
                onPressed: () {
                  final notifier = ref.read(cartProvider.notifier);
                  if (localQty == 0) notifier.add(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('${product.name} added to cart'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
