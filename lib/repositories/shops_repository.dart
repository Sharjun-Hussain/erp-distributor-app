import '../data/mock_data.dart';
import '../models/shop.dart';
import '../services/api_client.dart';

abstract class ShopsRepository {
  Future<List<Shop>> fetchShops();

  /// Persists a shop. Pass [isNew] when creating; defaults to inferring from
  /// whether the id already exists in the local list.
  Future<Shop> saveShop(Shop shop, {bool isNew = false});

  Future<void> deleteShop(String id);
}

class MockShopsRepository implements ShopsRepository {
  @override
  Future<List<Shop>> fetchShops() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.of(MockData.shops);
  }

  @override
  Future<Shop> saveShop(Shop shop, {bool isNew = false}) async {
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

/// Hits `GET/POST /dapp/shops` and `PATCH/DELETE /dapp/shops/:id`.
class ApiShopsRepository implements ShopsRepository {
  ApiShopsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Shop>> fetchShops() async {
    final data = await _client.get('/dapp/shops');
    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Shop.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Shop> saveShop(Shop shop, {bool isNew = false}) async {
    final payload = shop.toApiJson();
    final data = isNew
        ? await _client.post('/dapp/shops', data: payload)
        : await _client.patch('/dapp/shops/${shop.id}', data: payload);
    return Shop.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<void> deleteShop(String id) async {
    await _client.delete('/dapp/shops/$id');
  }
}

ShopsRepository buildShopsRepository(ApiClient client) =>
    useMockApis ? MockShopsRepository() : ApiShopsRepository(client);
