import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/catalog.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/price_list_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Distributor's private selling-price list.
/// Renders a fast, compact product list. Clicking any product opens an interactive
/// modal bottom sheet where rep can adjust selling price with real-time profit & margin badges.
class PriceListScreen extends ConsumerStatefulWidget {
  const PriceListScreen({super.key});

  @override
  ConsumerState<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends ConsumerState<PriceListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditSheet(BuildContext context, Product product) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProductPriceSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/more');
      }
    }

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/more');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'Price List',
                showBack: true,
                onBack: handleBack,
                bottom: SearchField(
                  controller: _searchController,
                  hint: 'Search products by name or SKU...',
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _search.isEmpty
                        ? products
                        : products
                            .where((p) =>
                                p.name.toLowerCase().contains(_search) ||
                                p.sku.toLowerCase().contains(_search))
                            .toList();

                    if (filtered.isEmpty) {
                      return const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No products found',
                        subtitle: 'Try a different search term.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final product = filtered[i];
                        return _CompactProductPriceTile(
                          product: product,
                          onTap: () => _openEditSheet(context, product),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingShimmer(),
                  error: (_, _) => const EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load products',
                    subtitle: 'Pull down to retry.',
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

/// Compact row for the clean list
class _CompactProductPriceTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _CompactProductPriceTile({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = product.defaultVariant ??
        (product.variants.isNotEmpty ? product.variants.first : null);

    final cost = def != null ? def.distributorPrice : product.distributorPrice;
    final sellingPrice = def != null ? def.sellingPrice : product.sellingPrice;
    final retailPrice = def != null ? def.price : product.price;

    final profit = sellingPrice > 0 ? (sellingPrice - cost) : 0.0;
    final marginPct = (cost > 0 && sellingPrice > 0) ? ((profit / cost) * 100) : 0.0;
    final hasCustomPrice = sellingPrice > 0;
    final isLoss = sellingPrice > 0 && profit < 0;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.glassBorder),
          ),
          child: Row(
            children: [
              // Product Avatar
              ProductAvatar(
                name: product.name,
                colorHex: product.colorHex,
                size: 40,
              ),
              const SizedBox(width: 12),

              // Title, SKU & Cost
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Cost: ${F.money(cost)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                        ),
                        if (product.variants.length > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.surfaceMutedColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.variants.length} vars',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ] else if (retailPrice > 0) ...[
                          Text(
                            ' • MRP ${F.money(retailPrice)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Selling Price & Profit Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasCustomPrice ? F.money(sellingPrice) : 'Not Set',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: hasCustomPrice ? theme.textMain : theme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasCustomPrice)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLoss
                            ? AppColors.danger.withValues(alpha: 0.12)
                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isLoss
                            ? '-${marginPct.abs().toStringAsFixed(1)}%'
                            : '+${marginPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isLoss ? AppColors.danger : const Color(0xFF10B981),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Set Price',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.brand),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Modal Bottom Sheet for editing price with live profit & margin calculations
class EditProductPriceSheet extends ConsumerStatefulWidget {
  final Product product;

  const EditProductPriceSheet({super.key, required this.product});

  @override
  ConsumerState<EditProductPriceSheet> createState() => _EditProductPriceSheetState();
}

class _EditProductPriceSheetState extends ConsumerState<EditProductPriceSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final variants = widget.product.variants.isNotEmpty
        ? widget.product.variants
        : [
            ProductVariant(
              id: widget.product.variantId.isEmpty ? widget.product.id : widget.product.variantId,
              name: 'Default',
              sellingPrice: widget.product.sellingPrice,
              distributorPrice: widget.product.distributorPrice,
              price: widget.product.price,
              isDefault: true,
            ),
          ];

    for (final v in variants) {
      final initialVal = v.sellingPrice > 0
          ? (v.sellingPrice == v.sellingPrice.roundToDouble()
              ? v.sellingPrice.toInt().toString()
              : v.sellingPrice.toString())
          : '';
      _controllers[v.id] = TextEditingController(text: initialVal);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _savePrices() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final entries = _controllers.entries.map((e) {
        return PriceEntry(
          productId: widget.product.id,
          variantId: e.key,
          sellingPrice: double.tryParse(e.value.text.trim()) ?? 0,
        );
      }).toList();

      await ref.read(priceListRepositoryProvider).savePrices(entries);
      ref.invalidate(productsProvider);
      ref.invalidate(priceListProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Price updated successfully'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Could not save price'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyMarkup(double pct) {
    final variants = widget.product.variants.isNotEmpty
        ? widget.product.variants
        : [
            ProductVariant(
              id: widget.product.variantId.isEmpty ? widget.product.id : widget.product.variantId,
              name: 'Default',
              sellingPrice: widget.product.sellingPrice,
              distributorPrice: widget.product.distributorPrice,
              price: widget.product.price,
            ),
          ];

    bool anyUpdated = false;
    for (final v in variants) {
      final controller = _controllers[v.id];
      if (controller == null) continue;

      // Base price to apply markup on:
      // 1. Distributor cost (wholesale price) if > 0
      // 2. Company retail/MRP price if > 0
      // 3. Current input or current selling price if > 0
      final currentInput = double.tryParse(controller.text.trim()) ?? 0.0;
      double base = v.distributorPrice;
      if (base <= 0) base = v.price;
      if (base <= 0) base = currentInput > 0 ? currentInput : v.sellingPrice;

      if (base > 0) {
        final newPrice = (base * (1 + (pct / 100))).roundToDouble();
        controller.text = newPrice == newPrice.roundToDouble()
            ? newPrice.toInt().toString()
            : newPrice.toStringAsFixed(2);
        anyUpdated = true;
      }
    }

    if (!anyUpdated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Cost is Rs 0.00. Enter a base price first to calculate markup.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variants = widget.product.variants.isNotEmpty
        ? widget.product.variants
        : [
            ProductVariant(
              id: widget.product.variantId.isEmpty ? widget.product.id : widget.product.variantId,
              name: 'Default',
              sellingPrice: widget.product.sellingPrice,
              distributorPrice: widget.product.distributorPrice,
              price: widget.product.price,
              isDefault: true,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.glassBorder),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              ProductAvatar(
                name: widget.product.name,
                colorHex: widget.product.colorHex,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Unit: ${widget.product.unit} • SKU: ${widget.product.sku}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Markup presets (+10%, +15%, +20%, +25%)
          Row(
            children: [
              Text(
                'Quick Markup:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [10.0, 15.0, 20.0, 25.0].map((pct) {
                  return InkWell(
                    onTap: () => _applyMarkup(pct),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '+${pct.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.glassBorder),
          const SizedBox(height: 16),

          // Variants List with Live Margin Calculations
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: variants.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final v = variants[i];
                final controller = _controllers[v.id]!;
                final inputVal = double.tryParse(controller.text.trim()) ?? 0.0;
                final cost = v.distributorPrice;
                final profit = inputVal > 0 ? (inputVal - cost) : 0.0;
                final marginPct = (cost > 0 && inputVal > 0) ? ((profit / cost) * 100) : 0.0;
                final isLoss = inputVal > 0 && profit < 0;

                final badgeColor = isLoss
                    ? AppColors.danger
                    : (inputVal > 0 ? const Color(0xFF10B981) : theme.textSecondary);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            v.name,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: theme.textMain,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Cost: ',
                                style: GoogleFonts.inter(fontSize: 11.5, color: theme.textSecondary),
                              ),
                              Text(
                                F.money(cost),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Live Profit Badge
                          Expanded(
                            child: inputVal > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLoss ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                                          size: 14,
                                          color: badgeColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isLoss
                                                ? 'Loss: -${F.money(profit.abs())} (${marginPct.abs().toStringAsFixed(1)}%)'
                                                : 'Profit: +${F.money(profit)} (${marginPct.toStringAsFixed(1)}%)',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: badgeColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    'Enter quote price to shops',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: theme.textSecondary.withValues(alpha: 0.7),
                                    ),
                                  ),
                          ),

                          const SizedBox(width: 12),

                          // Price Input
                          SizedBox(
                            width: 130,
                            child: TextField(
                              controller: controller,
                              autofocus: i == 0,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: theme.textMain,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                isDense: true,
                                prefixText: 'Rs ',
                                prefixStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textSecondary,
                                ),
                                hintText: '0',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: theme.glassBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
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

          const SizedBox(height: 20),

          // Save Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _savePrices,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.check, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Save Price',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
