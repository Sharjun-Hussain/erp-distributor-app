import '../data/mock_data.dart';
import '../models/finance.dart';
import '../services/api_client.dart';

abstract class FinanceRepository {
  Future<List<Invoice>> fetchInvoices();
  Future<Invoice?> fetchInvoice(String id);
}

class MockFinanceRepository implements FinanceRepository {
  @override
  Future<List<Invoice>> fetchInvoices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = List.of(MockData.invoices);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<Invoice?> fetchInvoice(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return MockData.invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Hits `GET /dapp/invoices` and `GET /dapp/invoices/:id`.
class ApiFinanceRepository implements FinanceRepository {
  ApiFinanceRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Invoice>> fetchInvoices() async {
    final data = await _client.get('/dapp/invoices');
    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Invoice.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Invoice?> fetchInvoice(String id) async {
    try {
      final data = await _client.get('/dapp/invoices/$id');
      return Invoice.fromJson((data as Map).cast<String, dynamic>());
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}

FinanceRepository buildFinanceRepository(ApiClient client) =>
    useMockApis ? MockFinanceRepository() : ApiFinanceRepository(client);
