import '../data/mock_data.dart';
import '../models/shop.dart';

abstract class ShopsRepository {
  Future<List<Shop>> fetchShops();
  Future<Shop> saveShop(Shop shop);
  Future<void> deleteShop(String id);
}

class MockShopsRepository implements ShopsRepository {
  @override
  Future<List<Shop>> fetchShops() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.of(MockData.shops);
  }

  @override
  Future<Shop> saveShop(Shop shop) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = MockData.shops.indexWhere((s) => s.id == shop.id);
    if (index == -1) {
      MockData.shops.add(shop);
      return shop;
    }
    MockData.shops[index] = shop;
    return shop;
  }

  @override
  Future<void> deleteShop(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    MockData.shops.removeWhere((s) => s.id == id);
  }
}

ShopsRepository buildShopsRepository() => MockShopsRepository();

// TODO(api): replace with ApiShopsRepository hitting GET/POST/PUT/DELETE
// /api/v1/dapp/shops.
