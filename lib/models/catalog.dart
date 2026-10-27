import '../utils/json.dart';

class ProductVariant {
  final String id;
  final String name;
  final String sku;
  final double price;
  final double distributorPrice;
  final double sellingPrice;
  final bool isDefault;
  final double stock;

  const ProductVariant({
    required this.id,
    required this.name,
    this.sku = '',
    this.price = 0,
    this.distributorPrice = 0,
    this.sellingPrice = 0,
    this.isDefault = false,
    this.stock = 0,
  });

  double get wholesalePrice => distributorPrice;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? 'Default').toString(),
      sku: (json['sku'] ?? '').toString(),
      price: toDouble(json['price']),
      distributorPrice: toDouble(json['distributorPrice']),
      sellingPrice: toDouble(json['sellingPrice']),
      isDefault: json['isDefault'] == true,
      stock: toDouble(json['stock']),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String sku;
  final String unit;
  final double price;
  final double distributorPrice;
  final double sellingPrice;
  final double stock;
  final String colorHex;
  final String variantId;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.price,
    required this.distributorPrice,
    this.sellingPrice = 0,
    required this.stock,
    this.colorHex = '#6366F1',
    this.variantId = '',
    this.variants = const [],
  });

  double get wholesalePrice => distributorPrice;

  ProductVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    for (final v in variants) {
      if (v.isDefault) return v;
    }
    return variants.first;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVariants = (json['variants'] as List?) ?? const [];
    return Product(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      unit: (json['unit'] ?? 'unit').toString(),
      price: toDouble(json['price']),
      distributorPrice: toDouble(json['distributorPrice']),
      sellingPrice: toDouble(json['sellingPrice']),
      stock: toDouble(json['stock']),
      colorHex: (json['colorHex'] as String?)?.trim().isNotEmpty == true
          ? json['colorHex'] as String
          : '#6366F1',
      variantId: json['variantId']?.toString() ?? '',
      variants: rawVariants
          .whereType<Map>()
          .map((e) => ProductVariant.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// A billing line. Price and discount are captured per line so the distributor
/// can quote a custom price for a shop without changing his saved price list.
class CartLine {
  final Product product;
  final ProductVariant? variant;
  final int qty;
  final double unitPrice;
  final double discount;

  const CartLine({
    required this.product,
    this.variant,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
  });

  /// Stable key so the same product with different variants are separate lines.
  String get key => variant == null ? product.id : '${product.id}:${variant!.id}';

  String get displayName {
    if (variant == null) return product.name;
    // If the product has only 1 variant or the variant name is "Default", hide the variant name
    if (product.variants.length <= 1 ||
        variant!.name.trim().toLowerCase() == 'default') {
      return product.name;
    }
    return '${product.name} · ${variant!.name}';
  }

  double get gross => unitPrice * qty;

  /// Line total after the per-line discount (never below zero).
  double get lineTotal {
    final t = gross - discount;
    return t < 0 ? 0 : t;
  }

  double get effectiveUnitPrice => qty > 0 ? lineTotal / qty : 0;

  CartLine copyWith({int? qty, double? unitPrice, double? discount}) => CartLine(
        product: product,
        variant: variant,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
      );
}
