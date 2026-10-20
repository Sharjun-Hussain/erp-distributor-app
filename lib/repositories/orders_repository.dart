import '../data/mock_data.dart';
import '../models/catalog.dart';
import '../models/orders.dart';
import '../models/shop.dart';

abstract class OrdersRepository {
  Future<List<ManufacturerOrder>> fetchManufacturerOrders();
  Future<ManufacturerOrder> submitManufacturerOrder(
      List<CartLine> lines, String notes);

  Future<List<ShopOrder>> fetchShopOrders();
  Future<ShopOrder> createShopOrder(Shop shop, List<CartLine> lines);
  Future<ShopOrder> createDirectSale(Shop shop, List<CartLine> lines);
  Future<ShopOrder> updateShopOrderStatus(String id, ShopOrderStatus status);
}

class MockOrdersRepository implements OrdersRepository {
  int _mfrSeq = 1043;
  int _shopSeq = 2211;
  int _invoiceSeq = 3389;

  @override
  Future<List<ManufacturerOrder>> fetchManufacturerOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = List.of(MockData.manufacturerOrders);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<ManufacturerOrder> submitManufacturerOrder(
      List<CartLine> lines, String notes) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final order = ManufacturerOrder(
      id: 'mo-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: 'MO-${_mfrSeq++}',
      date: DateTime.now(),
      status: ManufacturerOrderStatus.submitted,
      items: lines
          .map((l) => ManufacturerOrderItem(
                productName: l.product.name,
                unit: l.product.unit,
                qty: l.qty,
                unitPrice: l.product.distributorPrice,
              ))
          .toList(),
      notes: notes,
    );
    MockData.manufacturerOrders.insert(0, order);
    return order;
  }

  @override
  Future<List<ShopOrder>> fetchShopOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = List.of(MockData.shopOrders);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  ShopOrder _buildShopOrder(Shop shop, List<CartLine> lines,
      {ShopOrderStatus status = ShopOrderStatus.collected, bool invoice = false}) {
    return ShopOrder(
      id: 'so-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: 'SO-${_shopSeq++}',
      shopId: shop.id,
      shopName: shop.name,
      shopAddress: shop.address,
      shopPhone: shop.phone,
      date: DateTime.now(),
      status: status,
      items: lines
          .map((l) => ShopOrderItem(
                productName: l.product.name,
                unit: l.product.unit,
                qty: l.qty,
                unitPrice: l.product.distributorPrice,
              ))
          .toList(),
      placedBy: MockData.distributorUser.name,
      invoiceNumber: invoice ? 'INV-${_invoiceSeq++}' : null,
      paymentStatus: invoice ? 'unpaid' : 'unpaid',
    );
  }

  @override
  Future<ShopOrder> createShopOrder(Shop shop, List<CartLine> lines) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final order = _buildShopOrder(shop, lines);
    MockData.shopOrders.insert(0, order);
    return order;
  }

  @override
  Future<ShopOrder> createDirectSale(Shop shop, List<CartLine> lines) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final order = _buildShopOrder(shop, lines,
        status: ShopOrderStatus.delivered, invoice: true);
    MockData.shopOrders.insert(0, order);
    return order;
  }

  @override
  Future<ShopOrder> updateShopOrderStatus(
      String id, ShopOrderStatus status) async {
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

OrdersRepository buildOrdersRepository() => MockOrdersRepository();

// TODO(api): replace with ApiOrdersRepository hitting GET/POST /api/v1/dapp/orders
// and /api/v1/dapp/shop-orders.
