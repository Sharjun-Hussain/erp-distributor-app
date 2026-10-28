import '../data/mock_data.dart';
import '../models/catalog.dart';
import '../models/orders.dart';
import '../models/shop.dart';
import '../services/api_client.dart';

abstract class OrdersRepository {
  Future<List<ShopOrder>> fetchShopOrders();
  Future<ShopOrder> createShopOrder(
    Shop shop,
    List<CartLine> lines, {
    double discount = 0,
    String? notes,
  });
  Future<ShopOrder> createDirectSale(
    Shop shop,
    List<CartLine> lines, {
    double discount = 0,
    String? notes,
    double cashAmount = 0,
    double bankAmount = 0,
    String? bankRef,
    double chequeAmount = 0,
    String? chequeNo,
    DateTime? chequeDate,
    String? chequeBank,
  });
  Future<ShopOrder> updateShopOrderStatus(
    String id,
    ShopOrderStatus status, {
    double? cashAmount,
    double? bankAmount,
    String? bankRef,
    double? chequeAmount,
    String? chequeNo,
    DateTime? chequeDate,
    String? chequeBank,
  });
}

class MockOrdersRepository implements OrdersRepository {
  int _shopSeq = 2211;
  int _invoiceSeq = 3389;

  @override
  Future<List<ShopOrder>> fetchShopOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = List.of(MockData.shopOrders);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  ShopOrder _buildShopOrder(
    Shop shop,
    List<CartLine> lines, {
    required bool invoice,
  }) {
    return ShopOrder(
      id: 'so-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: 'SO-${_shopSeq++}',
      shopId: shop.id,
      shopName: shop.name,
      shopAddress: shop.address,
      shopPhone: shop.phone,
      date: DateTime.now(),
      status: invoice ? ShopOrderStatus.delivered : ShopOrderStatus.collected,
      items: lines
          .map((l) => ShopOrderItem(
                productName: l.displayName,
                unit: l.product.unit,
                qty: l.qty,
                unitPrice: l.unitPrice,
                discount: l.discount,
              ))
          .toList(),
      placedBy: MockData.distributorUser.name,
      invoiceNumber: invoice ? 'INV-${_invoiceSeq++}' : null,
      paymentStatus: 'unpaid',
    );
  }

  @override
  Future<ShopOrder> createShopOrder(
    Shop shop,
    List<CartLine> lines, {
    double discount = 0,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final order = _buildShopOrder(shop, lines, invoice: false);
    MockData.shopOrders.insert(0, order);
    return order;
  }

  @override
  Future<ShopOrder> createDirectSale(
    Shop shop,
    List<CartLine> lines, {
    double discount = 0,
    String? notes,
    double cashAmount = 0,
    double bankAmount = 0,
    String? bankRef,
    double chequeAmount = 0,
    String? chequeNo,
    DateTime? chequeDate,
    String? chequeBank,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final order = _buildShopOrder(shop, lines, invoice: true);
    MockData.shopOrders.insert(0, order);
    return order;
  }

  @override
  Future<ShopOrder> updateShopOrderStatus(
    String id,
    ShopOrderStatus status, {
    double? cashAmount,
    double? bankAmount,
    String? bankRef,
    double? chequeAmount,
    String? chequeNo,
    DateTime? chequeDate,
    String? chequeBank,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = MockData.shopOrders.indexWhere((o) => o.id == id);
    if (index == -1) throw Exception('Order not found');
    final old = MockData.shopOrders[index];
    final updated = ShopOrder(
      id: old.id,
      orderNumber: old.orderNumber,
      shopId: old.shopId,
      shopName: old.shopName,
      shopAddress: old.shopAddress,
      shopPhone: old.shopPhone,
      date: old.date,
      status: status,
      items: old.items,
      placedBy: old.placedBy,
      invoiceNumber: status == ShopOrderStatus.cancelled
          ? old.invoiceNumber
          : old.invoiceNumber ?? 'INV-${_invoiceSeq++}',
      paymentStatus: old.paymentStatus,
    );
    MockData.shopOrders[index] = updated;
    return updated;
  }
}

/// Hits `GET/POST /dapp/shop-orders` and mutations under `/dapp/shop-orders`.
class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository(this._client);

  final ApiClient _client;

  Map<String, dynamic> _linePayload(CartLine l) => {
        'productId': l.product.id,
        if (l.variant != null) 'variantId': l.variant!.id,
        'qty': l.qty,
        'unitPrice': l.unitPrice,
        'discount': l.discount,
      };

  Map<String, dynamic> _body(
      Shop shop, List<CartLine> lines, double discount, String? notes) {
    return {
      'shopId': shop.id,
      'items': lines.map(_linePayload).toList(),
      if (discount > 0) 'discount': discount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
  }

  @override
  Future<List<ShopOrder>> fetchShopOrders() async {
    final data = await _client.get('/dapp/shop-orders');
    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => ShopOrder.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<ShopOrder> createShopOrder(
    Shop shop,
    List<CartLine> lines, {
    double discount = 0,
    String? notes,
  }) async {
    final data = await _client.post('/dapp/shop-orders',
        data: _body(shop, lines, discount, notes));
    return ShopOrder.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<ShopOrder> createDirectSale(
    Shop shop,
    List<CartLine> lines, {
    double discount = 0,
    String? notes,
    double cashAmount = 0,
    double bankAmount = 0,
    String? bankRef,
    double chequeAmount = 0,
    String? chequeNo,
    DateTime? chequeDate,
    String? chequeBank,
  }) async {
    final body = _body(shop, lines, discount, notes);
    if (cashAmount > 0) body['cashAmount'] = cashAmount;
    if (bankAmount > 0) {
      body['bankAmount'] = bankAmount;
      if (bankRef != null && bankRef.isNotEmpty) body['bankRef'] = bankRef;
    }
    if (chequeAmount > 0) {
      body['chequeAmount'] = chequeAmount;
      if (chequeNo != null && chequeNo.isNotEmpty) body['chequeNo'] = chequeNo;
      if (chequeDate != null) {
        body['chequeDate'] = chequeDate.toIso8601String().split('T')[0];
      }
      if (chequeBank != null && chequeBank.isNotEmpty) {
        body['chequeBank'] = chequeBank;
      }
    }

    final data = await _client.post('/dapp/shop-orders/direct-sale', data: body);
    return ShopOrder.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<ShopOrder> updateShopOrderStatus(
    String id,
    ShopOrderStatus status, {
    double? cashAmount,
    double? bankAmount,
    String? bankRef,
    double? chequeAmount,
    String? chequeNo,
    DateTime? chequeDate,
    String? chequeBank,
  }) async {
    final Map<String, dynamic> body = {'status': status.apiValue};
    if (cashAmount != null && cashAmount > 0) body['cashAmount'] = cashAmount;
    if (bankAmount != null && bankAmount > 0) {
      body['bankAmount'] = bankAmount;
      if (bankRef != null && bankRef.isNotEmpty) body['bankRef'] = bankRef;
    }
    if (chequeAmount != null && chequeAmount > 0) {
      body['chequeAmount'] = chequeAmount;
      if (chequeNo != null && chequeNo.isNotEmpty) body['chequeNo'] = chequeNo;
      if (chequeDate != null) {
        body['chequeDate'] = chequeDate.toIso8601String().split('T')[0];
      }
      if (chequeBank != null && chequeBank.isNotEmpty) {
        body['chequeBank'] = chequeBank;
      }
    }

    final data = await _client.patch(
      '/dapp/shop-orders/$id/status',
      data: body,
    );
    return ShopOrder.fromJson((data as Map).cast<String, dynamic>());
  }
}

OrdersRepository buildOrdersRepository(ApiClient client) =>
    useMockApis ? MockOrdersRepository() : ApiOrdersRepository(client);
