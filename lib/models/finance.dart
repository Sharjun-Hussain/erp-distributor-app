import '../utils/json.dart';

enum InvoiceStatus {
  unpaid,
  partiallyPaid,
  paid;

  static InvoiceStatus fromApi(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'paid':
      case 'settled':
        return InvoiceStatus.paid;
      case 'partial':
      case 'partially_paid':
      case 'partiallypaid':
        return InvoiceStatus.partiallyPaid;
      case 'unpaid':
      default:
        return InvoiceStatus.unpaid;
    }
  }
}

class InvoiceParty {
  final String name;
  final String address;
  final String phone;

  const InvoiceParty({
    this.name = '',
    this.address = '',
    this.phone = '',
  });

  factory InvoiceParty.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const InvoiceParty();
    return InvoiceParty(
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

class InvoiceItem {
  final String productName;
  final String unit;
  final int qty;
  final double unitPrice;

  const InvoiceItem({
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
  });

  double get lineTotal => qty * unitPrice;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productName: (json['productName'] ?? '').toString(),
      unit: (json['unit'] ?? 'unit').toString(),
      qty: toInt(json['qty']),
      unitPrice: toDouble(json['unitPrice']),
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final List<InvoiceItem> items;
  final double discount;
  final InvoiceStatus status;
  final InvoiceParty company;
  final InvoiceParty distributedBy;

  final double? serverSubtotal;
  final double? serverTotal;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
    required this.items,
    this.discount = 0,
    this.status = InvoiceStatus.unpaid,
    this.company = const InvoiceParty(),
    this.distributedBy = const InvoiceParty(),
    this.serverSubtotal,
    this.serverTotal,
  });

  double get subtotal => serverSubtotal != null && serverSubtotal! > 0
      ? serverSubtotal!
      : items.fold(0, (sum, item) => sum + item.lineTotal);

  double get total => serverTotal != null && serverTotal! > 0
      ? serverTotal!
      : (subtotal - discount < 0 ? 0 : subtotal - discount);

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      date: toDate(json['date']),
      shopId: (json['shopId'] ?? '').toString(),
      shopName: (json['shopName'] ?? '').toString(),
      shopAddress: (json['shopAddress'] ?? '').toString(),
      shopPhone: (json['shopPhone'] ?? '').toString(),
      items: rawItems
          .whereType<Map>()
          .map((e) => InvoiceItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      discount: toDouble(json['discount']),
      status: InvoiceStatus.fromApi(json['status'] as String?),
      company: InvoiceParty.fromJson(
          (json['company'] as Map?)?.cast<String, dynamic>()),
      distributedBy: InvoiceParty.fromJson(
          (json['distributedBy'] as Map?)?.cast<String, dynamic>()),
      serverSubtotal:
          json.containsKey('subtotal') ? toDouble(json['subtotal']) : null,
      serverTotal: json.containsKey('total') ? toDouble(json['total']) : null,
    );
  }
}
