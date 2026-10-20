enum InvoiceStatus { unpaid, partiallyPaid, paid }

class InvoiceParty {
  final String name;
  final String address;
  final String phone;

  const InvoiceParty({
    this.name = '',
    this.address = '',
    this.phone = '',
  });
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
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get total => subtotal - discount;
}

enum PaymentParty { manufacturer, shop }

enum PaymentMethod { cash, bankTransfer, cheque, mobile }

class Payment {
  final String id;
  final DateTime date;
  final PaymentParty party;
  final String partyName;
  final double amount;
  final PaymentMethod method;
  final String reference;
  final String notes;

  const Payment({
    required this.id,
    required this.date,
    required this.party,
    required this.partyName,
    required this.amount,
    required this.method,
    this.reference = '',
    this.notes = '',
  });
}

class LedgerEntry {
  final String id;
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  const LedgerEntry({
    required this.id,
    required this.date,
    required this.description,
    this.debit = 0,
    this.credit = 0,
    this.balance = 0,
  });
}

class StockEntry {
  final String productId;
  final String productName;
  final String sku;
  final String unit;
  final double qty;
  final DateTime lastMovement;

  const StockEntry({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.qty,
    required this.lastMovement,
  });
}
