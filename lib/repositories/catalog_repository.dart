import '../data/mock_data.dart';
import '../models/catalog.dart';

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

CatalogRepository buildCatalogRepository() => MockCatalogRepository();

// TODO(api): replace with ApiCatalogRepository hitting GET /api/v1/dapp/products.
