import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/catalog.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'common.dart';

/// Bottom sheets mirroring the flutter_erp POS flow:
///   product tap → variant picker (when >1) → price + qty sheet → cart.
///
/// Everything is a [showModalBottomSheet] with a rounded top, a big value box
/// and a 4x3 numpad, matching the house style.

/// Entry point: resolves the variant, then opens the price/qty sheet.
Future<void> showAddToCartSheet(
  BuildContext context, {
  required Product product,
  required void Function(ProductVariant? variant, int qty, double unitPrice,
          double discount)
      onConfirm,
}) async {
  final variants = product.variants;
  if (variants.length <= 1) {
    final variant = variants.isEmpty ? null : variants.first;
    await _showPriceQtySheet(context,
        product: product, variant: variant, onConfirm: onConfirm);
    return;
  }

  final picked = await _showVariantPicker(context, product);
  if (picked == null) return;
  if (!context.mounted) return;
  await _showPriceQtySheet(context,
      product: product, variant: picked, onConfirm: onConfirm);
}

// ---------------------------------------------------------------------------
// Variant picker
// ---------------------------------------------------------------------------

Future<ProductVariant?> _showVariantPicker(
    BuildContext context, Product product) {
  return showModalBottomSheet<ProductVariant>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.surfaceMutedColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Variant',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: theme.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: product.variants.length,
                itemBuilder: (_, i) {
                  final v = product.variants[i];
                  final price =
                      v.sellingPrice > 0 ? v.sellingPrice : v.distributorPrice;
                  return ListTile(
                    title: Text(
                      v.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: theme.textMain,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          F.money(price),
                          style: GoogleFonts.inter(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (v.sku.isNotEmpty) ...[
                          Text('  •  ${v.sku}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: theme.textSecondary)),
                        ],
                      ],
                    ),
                    trailing: v.isDefault
                        ? StatusChip(label: 'Default', color: AppColors.info)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(v),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Price + quantity sheet (numpad)
// ---------------------------------------------------------------------------

Future<void> _showPriceQtySheet(
  BuildContext context, {
  required Product product,
  required ProductVariant? variant,
  required void Function(ProductVariant?, int, double, double) onConfirm,
}) {
  final basePrice = variant != null
      ? (variant.sellingPrice > 0 ? variant.sellingPrice : variant.distributorPrice)
      : (product.sellingPrice > 0 ? product.sellingPrice : product.distributorPrice);

  String priceStr = _trimZeros(basePrice);
  String qtyStr = '1';
  bool priceModified = false;
  bool qtyModified = false;
  bool activeIsPrice = true;

  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(
        builder: (context, setSB) {
          void press(String label) {
            setSB(() {
              final isPrice = activeIsPrice;
              var str = isPrice ? priceStr : qtyStr;
              var modified = isPrice ? priceModified : qtyModified;
              final reset = isPrice ? '0' : '1';
              if (label == 'C') {
                str = reset;
                modified = false;
              } else if (label == '<') {
                modified = true;
                str = str.length > 1
                    ? str.substring(0, str.length - 1)
                    : reset;
                if (str == reset) modified = false;
              } else if (label == '.') {
                if (!str.contains('.')) str = '$str.';
                modified = true;
              } else {
                if (!modified) {
                  str = label;
                  modified = true;
                } else if (str == '0') {
                  str = label;
                } else if (str.length < 10) {
                  str += label;
                }
              }
              if (isPrice) {
                priceStr = str;
                priceModified = modified;
              } else {
                qtyStr = str;
                qtyModified = modified;
              }
            });
          }

          final qty = (int.tryParse(qtyStr) ?? 1).clamp(1, 999999);
          final price = double.tryParse(priceStr) ?? 0;
          final lineTotal = price * qty;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.82,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 14),
                Text(
                  variant == null
                      ? product.name
                      : '${product.name} · ${variant.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${F.money(lineTotal)}  •  ${product.unit}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _FieldBox(
                        label: 'Price',
                        value: priceStr,
                        active: activeIsPrice,
                        onTap: () => setSB(() => activeIsPrice = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FieldBox(
                        label: 'Qty',
                        value: qtyStr,
                        active: !activeIsPrice,
                        onTap: () => setSB(() => activeIsPrice = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(child: _Numpad(onKey: press)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: 'Add to Cart',
                        icon: Icons.add_shopping_cart_rounded,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onConfirm(variant, qty, price, 0);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _trimZeros(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString();
}

class _FieldBox extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const _FieldBox({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: active
              ? AppColors.brand.withValues(alpha: 0.1)
              : theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.brand : theme.surfaceMutedColor,
            width: active ? 2.0 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: active ? AppColors.brand : theme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: active ? AppColors.brand : theme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onKey;

  const _Numpad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget btn(String label, {Color? color, IconData? icon}) => Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onKey(label),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color ?? theme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.glassBorder),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: 28, color: theme.textMain)
                      : Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );

    Widget row(List<Widget> children) =>
        Expanded(child: Row(children: children));

    return Column(
      children: [
        row([btn('7'), btn('8'), btn('9')]),
        row([btn('4'), btn('5'), btn('6')]),
        row([btn('1'), btn('2'), btn('3')]),
        row([
          btn('C', color: AppColors.warning.withValues(alpha: 0.15)),
          btn('0'),
          btn('<', icon: LucideIcons.delete),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Line edit sheet (price + discount for an existing cart line)
// ---------------------------------------------------------------------------

/// Returns the edited [CartLine] when confirmed, or null when dismissed.
Future<CartLine?> showLineEditSheet(
  BuildContext context, {
  required CartLine line,
}) {
  final priceController =
      TextEditingController(text: _trimZeros(line.unitPrice));
  final discountController = TextEditingController(
      text: line.discount > 0 ? _trimZeros(line.discount) : '');

  return showModalBottomSheet<CartLine>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(
        builder: (context, setSB) {
          final p = double.tryParse(priceController.text) ?? line.unitPrice;
          final d = double.tryParse(discountController.text) ?? 0;
          final lineTotal = ((p * line.qty) - d).clamp(0.0, double.infinity);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    line.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity: ${line.qty} ${line.product.unit}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      Text(
                        'Total: ${F.money(lineTotal)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Unit price',
                          controller: priceController,
                          onChanged: (_) => setSB(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LabeledField(
                          label: 'Line discount',
                          controller: discountController,
                          onChanged: (_) => setSB(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: 'Save Changes',
                          icon: Icons.check_rounded,
                          onPressed: () {
                            final price =
                                double.tryParse(priceController.text) ??
                                    line.unitPrice;
                            final discount =
                                double.tryParse(discountController.text) ?? 0;
                            Navigator.of(ctx).pop(
                              line.copyWith(
                                  unitPrice: price, discount: discount),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.surfaceMutedColor),
          ),
          child: Row(
            children: [
              Text(
                'Rs',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textMain,
                  ),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textSecondary.withValues(alpha: 0.5),
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
    );
  }
}
