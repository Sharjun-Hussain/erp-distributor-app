import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../models/shop.dart';

enum CartPurpose { manufacturer, shopOrder, directSale }

class CartState {
  final CartPurpose purpose;
  final Shop? shop;
  final List<CartLine> lines;

  const CartState({
    this.purpose = CartPurpose.manufacturer,
    this.shop,
    this.lines = const [],
  });

  double get total => lines.fold(0, (sum, line) => sum + line.lineTotal);
  int get itemCount => lines.fold(0, (sum, line) => sum + line.qty);

  int qtyOf(String productId) => lines
      .where((line) => line.product.id == productId)
      .fold(0, (sum, line) => sum + line.qty);

  CartState copyWith({
    CartPurpose? purpose,
    Shop? shop,
    List<CartLine>? lines,
    bool clearShop = false,
  }) {
    return CartState(
      purpose: purpose ?? this.purpose,
      shop: clearShop ? null : (shop ?? this.shop),
      lines: lines ?? this.lines,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void startManufacturerOrder() {
    state = const CartState(purpose: CartPurpose.manufacturer);
  }

  void startShopOrder(Shop shop) {
    state = CartState(purpose: CartPurpose.shopOrder, shop: shop);
  }

  void startDirectSale(Shop shop) {
    state = CartState(purpose: CartPurpose.directSale, shop: shop);
  }

  void add(Product product, {int qty = 1}) {
    final lines = List<CartLine>.from(state.lines);
    final index = lines.indexWhere((l) => l.product.id == product.id);
    if (index == -1) {
      lines.add(CartLine(product: product, qty: qty));
    } else {
      lines[index] = CartLine(product: product, qty: lines[index].qty + qty);
    }
    state = state.copyWith(lines: lines);
  }

  void setQty(String productId, int qty) {
    final lines = List<CartLine>.from(state.lines);
    final index = lines.indexWhere((l) => l.product.id == productId);
    if (index == -1) return;
    if (qty <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = CartLine(product: lines[index].product, qty: qty);
    }
    state = state.copyWith(lines: lines);
  }

  void remove(String productId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.product.id != productId).toList(),
    );
  }

  void clear() {
    state = state.copyWith(lines: const [], clearShop: true);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
