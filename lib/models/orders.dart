enum ManufacturerOrderStatus {
  submitted('Submitted'),
  confirmed('Confirmed'),
  partiallyDelivered('Partially Delivered'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const ManufacturerOrderStatus(this.label);
}

class ManufacturerOrderItem {
  final String productName;
  final String unit;
  final int qty;
  final double unitPrice;

  const ManufacturerOrderItem({
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
  });

  double get lineTotal => qty * unitPrice;
}

class ManufacturerOrder {
  final String id;
  final String orderNumber;
  final DateTime date;
  final ManufacturerOrderStatus status;
  final List<ManufacturerOrderItem> items;
  final String notes;

  const ManufacturerOrder({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.items,
    this.notes = '',
  });

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);
}

enum ShopOrderStatus {
  collected('Collected'),
  processing('Processing'),
  loaded('Loaded'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const ShopOrderStatus(this.label);
}

class ShopOrderItem {
  final String productName;
  final String unit;
  final int qty;
  final double unitPrice;

  const ShopOrderItem({
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
  });

  double get lineTotal => qty * unitPrice;
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
  });

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);
}
