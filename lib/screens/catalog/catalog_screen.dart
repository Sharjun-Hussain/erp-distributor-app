import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/catalog.dart';
import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/pos_sheets.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(productSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Catalog',
              bottom: SearchField(
                controller: _searchController,
                hint: 'Search products or SKU...',
                onChanged: _onSearch,
              ),
            ),

            // Cart context banner
            if (cart.shop != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.store,
                        size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cart.purpose == CartPurpose.directSale
                            ? 'Direct sale to ${cart.shop!.name}'
                            : 'Order for ${cart.shop!.name}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(cartProvider.notifier).clear(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: products.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No products found',
                      subtitle: 'Try a different search term.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(productsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _ProductTile(product: list[index]),
                    ),
                  );
                },
                loading: () => const LoadingShimmer(),
                error: (_, _) => const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load catalog',
                  subtitle: 'Pull down to retry.',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cart.lines.isEmpty
          ? null
          : SafeArea(
              child: GestureDetector(
                onTap: () => context.go('/catalog/cart'),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Badge(
                        label: Text('${cart.itemCount}'),
                        backgroundColor: Colors.white,
                        textColor: AppColors.brand,
                        child: const Icon(Icons.shopping_cart_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'View Cart',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        F.money(cart.total),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final qty = cart.qtyOfProduct(product.id);
    final price =
        product.sellingPrice > 0 ? product.sellingPrice : product.distributorPrice;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.go('/catalog/product/${product.id}'),
      child: Row(
        children: [
          ProductAvatar(
            name: product.name,
            colorHex: product.colorHex,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.sku} • ${product.unit}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      F.money(price),
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                    if (product.variants.length > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· ${product.variants.length} variants',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (qty > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$qty in cart',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          GestureDetector(
            onTap: () => showAddToCartSheet(
              context,
              product: product,
              onConfirm: (variant, q, unitPrice, discount) {
                ref.read(cartProvider.notifier).add(
                      product,
                      variant: variant,
                      qty: q,
                      unitPrice: unitPrice,
                    );
                if (discount > 0) {
                  final key =
                      variant == null ? product.id : '${product.id}:${variant.id}';
                  ref.read(cartProvider.notifier).setLineDiscount(key, discount);
                }
              },
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
