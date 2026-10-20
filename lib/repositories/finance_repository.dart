import '../data/mock_data.dart';
import '../models/finance.dart';

abstract class FinanceRepository {
  Future<List<Invoice>> fetchInvoices();
  Future<Invoice?> fetchInvoice(String id);
  Future<List<Payment>> fetchPayments();
  Future<Payment> addPayment(Payment payment);
  Future<List<LedgerEntry>> fetchLedger();
  Future<List<StockEntry>> fetchStock();
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

  @override
  Future<List<Payment>> fetchPayments() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = List.of(MockData.payments);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<Payment> addPayment(Payment payment) async {
    await Future.delayed(const Duration(milliseconds: 500));
    MockData.payments.insert(0, payment);
    return payment;
  }

  @override
  Future<List<LedgerEntry>> fetchLedger() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = List.of(MockData.ledger);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<StockEntry>> fetchStock() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.of(MockData.stock);
  }
}

FinanceRepository buildFinanceRepository() => MockFinanceRepository();

// TODO(api): replace with ApiFinanceRepository hitting
// /api/v1/dapp/invoices, /dapp/payments, /dapp/ledger, /dapp/stock.
