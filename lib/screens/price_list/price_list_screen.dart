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

/// Distributor's private selling-price list (variant level). Prices are his
/// quote/sale prices to shops; editing here updates the defaults used when
/// building a bill. Nothing is seeded — empty means 0.
class PriceListScreen extends ConsumerStatefulWidget {
  const PriceListScreen({super.key});

  @override
  ConsumerState<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends ConsumerState<PriceListScreen> {
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _drafts = {};
  final Set<String> _dirty = {};
  bool _saving = false;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _drafts.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _variantKey(String productId, String variantId) => '$productId:$variantId';

  Future<void> _save() async {
    if (_dirty.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final entries = _dirty.map((key) {
        final parts = key.split(':');
        return PriceEntry(
          productId: parts.first,
          variantId: parts.last,
          sellingPrice: double.tryParse(_drafts[key]?.text ?? '') ?? 0,
        );
      }).toList();

      await ref.read(priceListRepositoryProvider).savePrices(entries);
      ref.invalidate(productsProvider);
      ref.invalidate(priceListProvider);
      if (!mounted) return;
      _dirty.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Price list saved'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Could not save the price list'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              actions: [
                if (_dirty.isNotEmpty)
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save (${_dirty.length})',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                  ),
              ],
              bottom: SearchField(
                controller: _searchController,
                hint: 'Search products...',
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ProductPriceCard(
                      product: filtered[i],
                      draftController: (productId, variantId) {
                        final key = _variantKey(productId, variantId);
                        return _drafts.putIfAbsent(key, () {
                          final variant = filtered[i].variants.firstWhere(
                            (v) => v.id == variantId,
                            orElse: () => const ProductVariant(
                                id: '', name: '', sellingPrice: 0),
                          );
                          final value = variant.sellingPrice > 0
                              ? _trim(variant.sellingPrice)
                              : '';
                          return TextEditingController(text: value);
                        });
                      },
                      isDirty: (productId, variantId) =>
                          _dirty.contains(_variantKey(productId, variantId)),
                      onChanged: (productId, variantId) {
                        setState(() =>
                            _dirty.add(_variantKey(productId, variantId)));
                      },
                    ),
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

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _ProductPriceCard extends StatelessWidget {
  final Product product;
  final TextEditingController Function(String productId, String variantId)
      draftController;
  final bool Function(String productId, String variantId) isDirty;
  final void Function(String productId, String variantId) onChanged;

  const _ProductPriceCard({
    required this.product,
    required this.draftController,
    required this.isDirty,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variants = product.variants.isNotEmpty
        ? product.variants
        : [
            ProductVariant(
              id: product.variantId.isEmpty ? product.id : product.variantId,
              name: 'Default',
              sellingPrice: product.sellingPrice,
              distributorPrice: product.distributorPrice,
              isDefault: true,
            ),
          ];

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductAvatar(name: product.name, colorHex: product.colorHex, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...variants.map((v) {
            final controller = draftController(product.id, v.id);
            final dirty = isDirty(product.id, v.id);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textMain,
                          ),
                        ),
                        Text(
                          'Cost ${F.money(v.distributorPrice)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      onChanged: (_) => onChanged(product.id, v.id),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: 'Rs ',
                        hintText: '0',
                        suffixIcon: dirty
                            ? const Icon(LucideIcons.pencil,
                                size: 14, color: AppColors.brand)
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: theme.surfaceMutedColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: dirty
                                ? AppColors.brand
                                : theme.surfaceMutedColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.brand, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
