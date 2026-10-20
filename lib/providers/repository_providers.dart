import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/finance_repository.dart';
import '../repositories/orders_repository.dart';
import '../repositories/shops_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => buildAuthRepository());

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => buildCatalogRepository());

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => buildOrdersRepository());

final shopsRepositoryProvider =
    Provider<ShopsRepository>((ref) => buildShopsRepository());

final financeRepositoryProvider =
    Provider<FinanceRepository>((ref) => buildFinanceRepository());
