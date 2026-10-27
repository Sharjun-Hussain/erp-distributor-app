import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../models/finance.dart';
import '../models/orders.dart';
import '../models/shop.dart';
import '../repositories/price_list_repository.dart';
import 'repository_providers.dart';

/// Search box state for the catalog (owned here so the provider can react).
final productSearchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<Product>>((ref) {
  final query = ref.watch(productSearchQueryProvider);
  return ref.watch(catalogRepositoryProvider).fetchProducts(query: query);
});

final shopOrdersProvider = FutureProvider<List<ShopOrder>>(
    (ref) => ref.watch(ordersRepositoryProvider).fetchShopOrders());

final shopsProvider = FutureProvider<List<Shop>>(
    (ref) => ref.watch(shopsRepositoryProvider).fetchShops());

final invoicesProvider = FutureProvider<List<Invoice>>(
    (ref) => ref.watch(financeRepositoryProvider).fetchInvoices());

final priceListProvider = FutureProvider<List<PriceEntry>>(
    (ref) => ref.watch(priceListRepositoryProvider).fetchPriceList());
