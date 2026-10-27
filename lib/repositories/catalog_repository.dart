import '../data/mock_data.dart';
import '../models/catalog.dart';
import '../services/api_client.dart';

abstract class CatalogRepository {
  Future<List<Product>> fetchProducts({String query = ''});
}

class MockCatalogRepository implements CatalogRepository {
  @override
  Future<List<Product>> fetchProducts({String query = ''}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.of(MockData.products);
    return MockData.products
        .where((p) =>
            p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q))
        .toList();
  }
}

/// Hits `GET /api/v1/dapp/products?q=`.
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Product>> fetchProducts({String query = ''}) async {
    final data = await _client.get(
      '/dapp/products',
      query: query.trim().isEmpty ? null : {'q': query.trim()},
    );
    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Product.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

CatalogRepository buildCatalogRepository(ApiClient client) =>
    useMockApis ? MockCatalogRepository() : ApiCatalogRepository(client);
