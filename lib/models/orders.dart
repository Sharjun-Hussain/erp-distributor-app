import '../utils/json.dart';

enum ShopOrderStatus {
  collected('Collected'),
  processing('Processing'),
  loaded('Loaded'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const ShopOrderStatus(this.label);

  static ShopOrderStatus fromApi(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'processing':
        return ShopOrderStatus.processing;
      case 'loaded':
        return ShopOrderStatus.loaded;
      case 'delivered':
        return ShopOrderStatus.delivered;
      case 'cancelled':
        return ShopOrderStatus.cancelled;
      case 'collected':
      default:
        return ShopOrderStatus.collected;
    }
  }

  /// Backend enum value (lowercase).
  String get apiValue => name;
}

class ShopOrderItem {
  final String productId;
  final String variantId;
  final String productName;
  final String unit;
  final int qty;
  final double unitPrice;
  final double discount;

  const ShopOrderItem({
    this.productId = '',
    this.variantId = '',
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    this.discount = 0,
  });

  double get lineTotal {
    final t = qty * unitPrice - discount;
    return t < 0 ? 0 : t;
  }

  factory ShopOrderItem.fromJson(Map<String, dynamic> json) {
    return ShopOrderItem(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      productName: (json['productName'] ?? '').toString(),
      unit: (json['unit'] ?? 'unit').toString(),
      qty: toInt(json['qty']),
      unitPrice: toDouble(json['unitPrice']),
      discount: toDouble(json['discount']),
    );
  }
}

class ShopOrder {
  final String id;
  final String orderNumber;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final DateTime date;
  final ShopOrderStatus status;
  final List<ShopOrderItem> items;
  final String placedBy;
  final String? invoiceNumber;
  final String paymentStatus;
  final double subtotal;
  final double discount;
  final String notes;
  final double? serverTotal;

  const ShopOrder({
    required this.id,
    required this.orderNumber,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.date,
    required this.status,
    required this.items,
    this.placedBy = '',
    this.invoiceNumber,
    this.paymentStatus = 'unpaid',
    this.subtotal = 0,
    this.discount = 0,
    this.notes = '',
    this.serverTotal,
  });

  /// Net total: prefer the server value, otherwise gross subtotal minus discount.
  double get total {
    if (serverTotal != null && serverTotal! > 0) return serverTotal!;
    final gross = subtotal > 0
        ? subtotal
        : items.fold(0.0, (sum, item) => sum + item.lineTotal);
    final net = gross - discount;
    return net < 0 ? 0 : net;
  }

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return ShopOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: (json['orderNumber'] ?? '').toString(),
      shopId: (json['shopId'] ?? '').toString(),
      shopName: (json['shopName'] ?? '').toString(),
      shopAddress: (json['shopAddress'] ?? '').toString(),
      shopPhone: (json['shopPhone'] ?? '').toString(),
      date: toDate(json['date']),
      status: ShopOrderStatus.fromApi(json['status'] as String?),
      items: rawItems
          .whereType<Map>()
          .map((e) => ShopOrderItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      placedBy: (json['placedBy'] ?? '').toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      paymentStatus: (json['paymentStatus'] ?? 'unpaid').toString(),
      subtotal: toDouble(json['subtotal']),
      discount: toDouble(json['discount']),
      notes: (json['notes'] ?? '').toString(),
      serverTotal:
          json.containsKey('total') ? toDouble(json['total']) : null,
    );
  }
}
