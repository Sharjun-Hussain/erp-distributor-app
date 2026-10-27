import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../models/shop.dart';

enum CartPurpose { shopOrder, directSale }

class CartState {
  final CartPurpose purpose;
  final Shop? shop;
  final List<CartLine> lines;
  final double billDiscount;

  const CartState({
    this.purpose = CartPurpose.shopOrder,
    this.shop,
    this.lines = const [],
    this.billDiscount = 0,
  });

  /// Gross before any discount.
  double get grossTotal => lines.fold(0, (sum, line) => sum + line.gross);

  double get lineDiscountTotal =>
      lines.fold(0, (sum, line) => sum + line.discount);

  double get discountTotal {
    final d = lineDiscountTotal + billDiscount;
    return d > grossTotal ? grossTotal : d;
  }

  /// Net payable after line discounts and the bill-level discount.
  double get total {
    final t = grossTotal - discountTotal;
    return t < 0 ? 0 : t;
  }

  int get itemCount => lines.fold(0, (sum, line) => sum + line.qty);

  int qtyOf(String lineKey) => lines
      .where((line) => line.key == lineKey)
      .fold(0, (sum, line) => sum + line.qty);

  /// Quantity of a product across all its variants (for catalog badges).
  int qtyOfProduct(String productId) => lines
      .where((line) => line.product.id == productId)
      .fold(0, (sum, line) => sum + line.qty);

  CartState copyWith({
    CartPurpose? purpose,
    Shop? shop,
    List<CartLine>? lines,
    double? billDiscount,
    bool clearShop = false,
  }) {
    return CartState(
      purpose: purpose ?? this.purpose,
      shop: clearShop ? null : (shop ?? this.shop),
      lines: lines ?? this.lines,
      billDiscount: billDiscount ?? this.billDiscount,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void setShop(Shop shop) {
    state = state.copyWith(shop: shop);
  }

  void setPurpose(CartPurpose purpose) {
    state = state.copyWith(purpose: purpose);
  }

  void startShopOrder(Shop shop) {
    state = CartState(purpose: CartPurpose.shopOrder, shop: shop);
  }

  void startDirectSale(Shop shop) {
    state = CartState(purpose: CartPurpose.directSale, shop: shop);
  }

  /// Add a product/variant at a given price. Merges into the existing line when
  /// the same variant is already present.
  void add(
    Product product, {
    ProductVariant? variant,
    int qty = 1,
    double? unitPrice,
  }) {
    final lines = List<CartLine>.from(state.lines);
    final price = unitPrice ?? _defaultPrice(product, variant);
    final key = variant == null ? product.id : '${product.id}:${variant.id}';
    final index = lines.indexWhere((l) => l.key == key);
    if (index == -1) {
      lines.add(CartLine(
        product: product,
        variant: variant,
        qty: qty,
        unitPrice: price,
      ));
    } else {
      lines[index] = lines[index].copyWith(qty: lines[index].qty + qty);
    }
    state = state.copyWith(lines: lines);
  }

  void setQty(String lineKey, int qty) {
    final lines = List<CartLine>.from(state.lines);
    final index = lines.indexWhere((l) => l.key == lineKey);
    if (index == -1) return;
    if (qty <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(qty: qty);
    }
    state = state.copyWith(lines: lines);
  }

  void setUnitPrice(String lineKey, double unitPrice) {
    final lines = List<CartLine>.from(state.lines);
    final index = lines.indexWhere((l) => l.key == lineKey);
    if (index == -1) return;
    lines[index] = lines[index].copyWith(unitPrice: unitPrice < 0 ? 0 : unitPrice);
    state = state.copyWith(lines: lines);
  }

  void setLineDiscount(String lineKey, double discount) {
    final lines = List<CartLine>.from(state.lines);
    final index = lines.indexWhere((l) => l.key == lineKey);
    if (index == -1) return;
    lines[index] = lines[index].copyWith(discount: discount < 0 ? 0 : discount);
    state = state.copyWith(lines: lines);
  }

  void setBillDiscount(double discount) {
    state = state.copyWith(billDiscount: discount < 0 ? 0 : discount);
  }

  void remove(String lineKey) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.key != lineKey).toList(),
    );
  }

  void clear() {
    state = state.copyWith(lines: const [], billDiscount: 0, clearShop: true);
  }

  static double _defaultPrice(Product product, ProductVariant? variant) {
    if (variant != null) {
      if (variant.sellingPrice > 0) return variant.sellingPrice;
      return variant.distributorPrice;
    }
    if (product.sellingPrice > 0) return product.sellingPrice;
    return product.distributorPrice;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
