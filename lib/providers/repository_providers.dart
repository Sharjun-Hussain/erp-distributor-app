import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/finance_repository.dart';
import '../repositories/orders_repository.dart';
import '../repositories/price_list_repository.dart';
import '../repositories/shops_repository.dart';
import '../services/api_client.dart';

/// Single Dio-backed client shared by every API repository.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => buildAuthRepository(ref.watch(apiClientProvider)));

final catalogRepositoryProvider = Provider<CatalogRepository>(
    (ref) => buildCatalogRepository(ref.watch(apiClientProvider)));

final ordersRepositoryProvider = Provider<OrdersRepository>(
    (ref) => buildOrdersRepository(ref.watch(apiClientProvider)));

final shopsRepositoryProvider = Provider<ShopsRepository>(
    (ref) => buildShopsRepository(ref.watch(apiClientProvider)));

final financeRepositoryProvider = Provider<FinanceRepository>(
    (ref) => buildFinanceRepository(ref.watch(apiClientProvider)));

final priceListRepositoryProvider = Provider<PriceListRepository>(
    (ref) => buildPriceListRepository(ref.watch(apiClientProvider)));
