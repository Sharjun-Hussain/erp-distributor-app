import '../data/mock_data.dart';
import '../services/api_client.dart';

/// One distributor-defined selling price for a product variant.
class PriceEntry {
  final String productId;
  final String variantId;
  final double sellingPrice;

  const PriceEntry({
    required this.productId,
    required this.variantId,
    required this.sellingPrice,
  });

  factory PriceEntry.fromJson(Map<String, dynamic> json) => PriceEntry(
        productId: (json['productId'] ?? '').toString(),
        variantId: (json['variantId'] ?? '').toString(),
        sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      );
}

abstract class PriceListRepository {
  Future<List<PriceEntry>> fetchPriceList();
  Future<void> savePrices(List<PriceEntry> prices);
}

class MockPriceListRepository implements PriceListRepository {
  final Map<String, double> _prices = {};

  @override
  Future<List<PriceEntry>> fetchPriceList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _prices.entries
        .map((e) => PriceEntry(
              productId: e.key.split(':').first,
              variantId: e.key.split(':').last,
              sellingPrice: e.value,
            ))
        .toList();
  }

  @override
  Future<void> savePrices(List<PriceEntry> prices) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final p in prices) {
      _prices['${p.productId}:${p.variantId}'] = p.sellingPrice;
    }
  }
}

/// Hits `GET/PUT /dapp/price-list`.
class ApiPriceListRepository implements PriceListRepository {
  ApiPriceListRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<PriceEntry>> fetchPriceList() async {
    final data = await _client.get('/dapp/price-list');
    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => PriceEntry.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> savePrices(List<PriceEntry> prices) async {
    if (prices.isEmpty) return;
    await _client.put('/dapp/price-list', data: {
      'prices': prices
          .map((p) => {
                'productId': p.productId,
                'variantId': p.variantId,
                'sellingPrice': p.sellingPrice,
              })
          .toList(),
    });
  }
}

PriceListRepository buildPriceListRepository(ApiClient client) =>
    useMockApis ? MockPriceListRepository() : ApiPriceListRepository(client);
