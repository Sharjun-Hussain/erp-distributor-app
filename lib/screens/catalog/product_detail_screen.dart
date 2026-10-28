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
import '../price_list/price_list_screen.dart';

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
            title: const Text('Product Details'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Product not found',
            subtitle: 'It may have been removed or sync is pending.',
          ),
        ),
      );
    }

    final def = product.defaultVariant ??
        (product.variants.isNotEmpty ? product.variants.first : null);

    final cost = def != null ? def.distributorPrice : product.distributorPrice;
    final sellingPrice = product.sellingPrice > 0
        ? product.sellingPrice
        : (def != null && def.sellingPrice > 0
            ? def.sellingPrice
            : (cost > 0 ? cost : product.price));

    final retailPrice = def != null ? def.price : product.price;
    final profit = sellingPrice > 0 && cost > 0 ? (sellingPrice - cost) : 0.0;
    final marginPct = cost > 0 && sellingPrice > 0 ? ((profit / cost) * 100) : 0.0;
    final isLoss = sellingPrice > 0 && cost > 0 && profit < 0;

    final avatarColor = Color(int.parse(
        'FF${product.colorHex.replaceAll('#', '')}',
        radix: 16));

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
              // --- Custom Header Bar ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  border: Border(bottom: BorderSide(color: theme.glassBorder)),
                ),
                child: Row(
                  children: [
                    AppBackButton(onPressed: handleBack),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.textMain,
                            ),
                          ),
                          Text(
                            product.sku,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick Edit Price Icon
                    IconButton(
                      tooltip: 'Set Selling Price',
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.brand.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.pencil,
                          size: 16,
                          color: AppColors.brand,
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => EditProductPriceSheet(product: product),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- Content Body ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // 1. HERO PRODUCT CARD
                    _buildProductHeroCard(context, theme, product, avatarColor, def),

                    const SizedBox(height: 14),

                    // 2. FINANCIAL METRICS TILES
                    _buildPricingGrid(theme, sellingPrice, cost, retailPrice, profit, marginPct, isLoss, product.unit),

                    const SizedBox(height: 14),

                    // 3. CART STATUS BAR
                    _buildCartStatusBar(context, theme, product, localQty),

                    const SizedBox(height: 18),

                    // 4. VARIANTS MATRIX (if multiple variants exist)
                    if (product.variants.length > 1) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Product Variants (${product.variants.length})',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: theme.textMain,
                            ),
                          ),
                          Text(
                            'Per-variant pricing',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildVariantsList(context, theme, product),
                      const SizedBox(height: 18),
                    ],

                    // 5. INVENTORY & PRODUCT SPECIFICATIONS
                    Text(
                      'Specifications & Details',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: theme.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProductSpecsCard(theme, product, sellingPrice, cost),
                  ],
                ),
              ),

              // --- Bottom Action Bar ---
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  border: Border(top: BorderSide(color: theme.glassBorder)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Edit Price Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.brand.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: AppColors.brand,
                        ),
                        onPressed: () {
                          showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => EditProductPriceSheet(product: product),
                          );
                        },
                        icon: const Icon(LucideIcons.pencil, size: 16),
                        label: Text(
                          'Edit Price',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Add To Cart Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () => showAddToCartSheet(
                          context,
                          product: product,
                          onConfirm: (variant, q, unitPrice, discount) {
                            final notifier = ref.read(cartProvider.notifier);
                            notifier.add(
                              product,
                              variant: variant,
                              qty: q,
                              unitPrice: unitPrice,
                            );
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
                        icon: const Icon(LucideIcons.shoppingCart, size: 17),
                        label: Text(
                          'Add to Cart',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
  // HERO CARD
  // ==========================================
  Widget _buildProductHeroCard(
    BuildContext context,
    ThemeData theme,
    Product product,
    Color avatarColor,
    ProductVariant? defaultVariant,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Vibrant Avatar with Glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  avatarColor.withValues(alpha: 0.22),
                  avatarColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: avatarColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              product.name.isEmpty ? '?' : product.name.characters.first.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: avatarColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Product Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: theme.surfaceMutedColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.sku,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• Unit: ${product.unit.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stock Availability Badge
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: product.stock > 0
                            ? const Color(0xFF10B981)
                            : AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.stock > 0
                          ? '${product.stock.toStringAsFixed(0)} ${product.unit} Available in Stock'
                          : 'Out of Stock',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: product.stock > 0
                            ? const Color(0xFF10B981)
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRICING & PROFIT GRID
  // ==========================================
  Widget _buildPricingGrid(
    ThemeData theme,
    double sellingPrice,
    double cost,
    double retailPrice,
    double profit,
    double marginPct,
    bool isLoss,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.tag, size: 16, color: AppColors.brand),
                  const SizedBox(width: 6),
                  Text(
                    'Pricing & Profit Analysis',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: theme.textMain,
                    ),
                  ),
                ],
              ),
              if (cost > 0 && sellingPrice > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLoss
                        ? AppColors.danger.withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLoss
                        ? '-${marginPct.abs().toStringAsFixed(1)}% Margin'
                        : '+${marginPct.toStringAsFixed(1)}% Markup',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isLoss ? AppColors.danger : const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Selling Price Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR SELLING PRICE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rate offered to shops',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${F.money(sellingPrice)} / $unit',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Cost, Retail & Profit Breakdown Row
          Row(
            children: [
              // Cost Price Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.surfaceMutedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COST PRICE',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        F.money(cost),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Retail (MRP) Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.surfaceMutedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MRP / RETAIL',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        F.money(retailPrice),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Net Profit Per Unit Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (profit >= 0
                            ? const Color(0xFF10B981)
                            : AppColors.danger)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROFIT / UNIT',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: profit >= 0
                              ? const Color(0xFF10B981)
                              : AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profit >= 0 ? '+${F.money(profit)}' : '-${F.money(profit.abs())}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: profit >= 0
                              ? const Color(0xFF10B981)
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CART STATUS BAR
  // ==========================================
  Widget _buildCartStatusBar(
    BuildContext context,
    ThemeData theme,
    Product product,
    int localQty,
  ) {
    final hasItemsInCart = localQty > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasItemsInCart
            ? AppColors.brand.withValues(alpha: 0.09)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasItemsInCart
              ? AppColors.brand.withValues(alpha: 0.35)
              : theme.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasItemsInCart
                  ? AppColors.brand
                  : theme.surfaceMutedColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.shoppingBag,
              size: 16,
              color: hasItemsInCart ? Colors.white : theme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cart Status',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.textMain,
                  ),
                ),
                Text(
                  hasItemsInCart
                      ? '$localQty ${product.unit} currently in active cart'
                      : 'None added to cart yet',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasItemsInCart)
            TextButton.icon(
              onPressed: () => context.push('/catalog/cart'),
              icon: const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.brand),
              label: Text(
                'View Cart',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // VARIANTS LIST
  // ==========================================
  Widget _buildVariantsList(
    BuildContext context,
    ThemeData theme,
    Product product,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: product.variants.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: theme.glassBorder),
        itemBuilder: (_, i) {
          final v = product.variants[i];
          final vSellingPrice = v.sellingPrice > 0
              ? v.sellingPrice
              : (v.distributorPrice > 0 ? v.distributorPrice : v.price);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: Row(
              children: [
                Text(
                  v.name,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.textMain,
                  ),
                ),
                if (v.isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Default',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'SKU: ${v.sku.isNotEmpty ? v.sku : product.sku} • Stock: ${v.stock.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: theme.textSecondary,
              ),
            ),
            trailing: Text(
              F.money(vSellingPrice),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SPECIFICATIONS CARD
  // ==========================================
  Widget _buildProductSpecsCard(
    ThemeData theme,
    Product product,
    double sellingPrice,
    double cost,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Column(
        children: [
          _specRow(theme, 'Product Code / SKU', product.sku),
          _specDivider(theme),
          _specRow(theme, 'Stock Keeping Unit (UOM)', product.unit.toUpperCase()),
          _specDivider(theme),
          _specRow(theme, 'Total On-Hand Inventory', '${product.stock.toStringAsFixed(0)} ${product.unit}'),
          _specDivider(theme),
          _specRow(theme, 'Standard Unit Cost', F.money(cost)),
          _specDivider(theme),
          _specRow(theme, 'Distributor Selling Rate', F.money(sellingPrice)),
          _specDivider(theme),
          _specRow(theme, 'Company Retail (MRP)', F.money(product.price)),
        ],
      ),
    );
  }

  Widget _specRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: theme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specDivider(ThemeData theme) {
    return Divider(height: 1, thickness: 1, color: theme.glassBorder.withValues(alpha: 0.5));
  }
}

