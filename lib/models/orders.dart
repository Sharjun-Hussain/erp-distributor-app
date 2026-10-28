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

class DistributorPaymentItem {
  final String id;
  final String? orderId;
  final String receiptNumber;
  final String paymentType;
  final double amount;
  final String chequeNo;
  final DateTime? chequeDate;
  final String chequeBank;
  final String chequeStatus;
  final String bankRef;
  final String collectedBy;
  final DateTime? collectedAt;
  final String notes;

  const DistributorPaymentItem({
    required this.id,
    this.orderId,
    required this.receiptNumber,
    required this.paymentType,
    required this.amount,
    this.chequeNo = '',
    this.chequeDate,
    this.chequeBank = '',
    this.chequeStatus = 'pending',
    this.bankRef = '',
    this.collectedBy = '',
    this.collectedAt,
    this.notes = '',
  });

  bool get isCash => paymentType.toLowerCase() == 'cash';
  bool get isCheque => paymentType.toLowerCase() == 'cheque';
  bool get isBankTransfer =>
      paymentType.toLowerCase() == 'bank_transfer' ||
      paymentType.toLowerCase() == 'bank';

  factory DistributorPaymentItem.fromJson(Map<String, dynamic> json) {
    return DistributorPaymentItem(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      receiptNumber: (json['receiptNumber'] ?? json['receipt_number'] ?? '').toString(),
      paymentType: (json['paymentType'] ?? json['payment_type'] ?? 'cash').toString(),
      amount: toDouble(json['amount']),
      chequeNo: (json['chequeNo'] ?? json['cheque_no'] ?? '').toString(),
      chequeDate: json['chequeDate'] != null || json['cheque_date'] != null
          ? toDate(json['chequeDate'] ?? json['cheque_date'])
          : null,
      chequeBank: (json['chequeBank'] ?? json['cheque_bank'] ?? '').toString(),
      chequeStatus: (json['chequeStatus'] ?? json['cheque_status'] ?? 'pending').toString(),
      bankRef: (json['bankRef'] ?? json['bank_ref'] ?? '').toString(),
      collectedBy: (json['collectedBy'] ?? json['collected_by'] ?? '').toString(),
      collectedAt: json['collectedAt'] != null || json['collected_at'] != null
          ? toDate(json['collectedAt'] ?? json['collected_at'])
          : null,
      notes: (json['notes'] ?? '').toString(),
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
  final List<DistributorPaymentItem> payments;
  final String workflow;
  final String placedBy;
  final String? invoiceNumber;
  final String paymentStatus;
  final double subtotal;
  final double discount;
  final double cashAmount;
  final double bankAmount;
  final String bankRef;
  final double chequeAmount;
  final String chequeNo;
  final DateTime? chequeDate;
  final String chequeBank;
  final String chequeStatus;
  final double paidAmount;
  final double balanceDue;
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
    this.payments = const [],
    this.workflow = 'collect',
    this.placedBy = '',
    this.invoiceNumber,
    this.paymentStatus = 'unpaid',
    this.subtotal = 0,
    this.discount = 0,
    this.cashAmount = 0,
    this.bankAmount = 0,
    this.bankRef = '',
    this.chequeAmount = 0,
    this.chequeNo = '',
    this.chequeDate,
    this.chequeBank = '',
    this.chequeStatus = 'pending',
    this.paidAmount = 0,
    this.balanceDue = 0,
    this.notes = '',
    this.serverTotal,
  });

  bool get isDirectSale => workflow == 'direct_sale';
  bool get isCollect => !isDirectSale;
  bool get hasCheque => chequeAmount > 0;
  bool get isPaidInFull => paymentStatus.toLowerCase() == 'paid';
  bool get isPartiallyPaid => paymentStatus.toLowerCase() == 'partially_paid';

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
    final rawPayments = (json['payments'] as List?) ?? const [];
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
      payments: rawPayments
          .whereType<Map>()
          .map((e) => DistributorPaymentItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      workflow: (json['workflow'] ?? 'collect').toString(),
      placedBy: (json['placedBy'] ?? '').toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      paymentStatus: (json['paymentStatus'] ?? 'unpaid').toString(),
      subtotal: toDouble(json['subtotal']),
      discount: toDouble(json['discount']),
      cashAmount: toDouble(json['cashAmount'] ?? json['cash_amount']),
      bankAmount: toDouble(json['bankAmount'] ?? json['bank_amount']),
      bankRef: (json['bankRef'] ?? json['bank_ref'] ?? '').toString(),
      chequeAmount: toDouble(json['chequeAmount'] ?? json['cheque_amount']),
      chequeNo: (json['chequeNo'] ?? json['cheque_no'] ?? '').toString(),
      chequeDate: json['chequeDate'] != null || json['cheque_date'] != null
          ? toDate(json['chequeDate'] ?? json['cheque_date'])
          : null,
      chequeBank: (json['chequeBank'] ?? json['cheque_bank'] ?? '').toString(),
      chequeStatus: (json['chequeStatus'] ?? json['cheque_status'] ?? 'pending').toString(),
      paidAmount: toDouble(json['paidAmount'] ?? json['paid_amount']),
      balanceDue: toDouble(json['balanceDue'] ?? json['balance_due']),
      notes: (json['notes'] ?? '').toString(),
      serverTotal:
          json.containsKey('total') ? toDouble(json['total']) : null,
    );
  }
}
