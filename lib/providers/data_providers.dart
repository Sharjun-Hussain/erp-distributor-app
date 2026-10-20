import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../models/finance.dart';
import '../models/orders.dart';
import '../models/shop.dart';
import 'repository_providers.dart';

/// Search box state for the catalog (owned here so the provider can react).
final productSearchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<Product>>((ref) {
  final query = ref.watch(productSearchQueryProvider);
  return ref.watch(catalogRepositoryProvider).fetchProducts(query: query);
});

final manufacturerOrdersProvider = FutureProvider<List<ManufacturerOrder>>(
    (ref) => ref.watch(ordersRepositoryProvider).fetchManufacturerOrders());

final shopOrdersProvider = FutureProvider<List<ShopOrder>>(
    (ref) => ref.watch(ordersRepositoryProvider).fetchShopOrders());

final shopsProvider = FutureProvider<List<Shop>>(
    (ref) => ref.watch(shopsRepositoryProvider).fetchShops());

final invoicesProvider = FutureProvider<List<Invoice>>(
    (ref) => ref.watch(financeRepositoryProvider).fetchInvoices());

final paymentsProvider = FutureProvider<List<Payment>>(
    (ref) => ref.watch(financeRepositoryProvider).fetchPayments());

final ledgerProvider = FutureProvider<List<LedgerEntry>>(
    (ref) => ref.watch(financeRepositoryProvider).fetchLedger());

final stockProvider = FutureProvider<List<StockEntry>>(
    (ref) => ref.watch(financeRepositoryProvider).fetchStock());
