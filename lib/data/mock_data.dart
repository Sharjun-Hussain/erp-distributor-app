import '../models/auth.dart';
import '../models/catalog.dart';
import '../models/finance.dart';
import '../models/orders.dart';
import '../models/shop.dart';

/// When true the app routes through in-memory mock repositories; when false it
/// talks to the live `/dapp/*` backend. Flip to `true` for offline/demo builds.
const bool useMockApis = false;

DateTime _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days));

class MockData {
  static const distributorUser = DistributorUser(
    id: 'u-1',
    name: 'Kamal Perera',
    email: 'kamal@kamaltraders.lk',
    phone: '0771234567',
    role: 'Distributor',
    organizationId: 'org-1',
    distributor: DistributorInfo(
      id: 'd-1',
      name: 'Kamal Perera',
      company: 'Kamal Traders',
      phone: '0112456789',
      address: 'No. 88, Kandy Road, Kiribathgoda',
      creditLimit: 500000,
      balance: 99300,
    ),
  );

  static const products = <Product>[
    Product(
        id: 'p-1',
        name: 'Premium Basmati Rice 5kg',
        sku: 'RCE-005',
        unit: 'bag',
        price: 3250,
        distributorPrice: 2850,
        stock: 140,
        colorHex: '#F59E0B'),
    Product(
        id: 'p-2',
        name: 'Sunflower Cooking Oil 5L',
        sku: 'OIL-005',
        unit: 'bottle',
        price: 2750,
        distributorPrice: 2400,
        stock: 96,
        colorHex: '#F97316'),
    Product(
        id: 'p-3',
        name: 'Wheat Flour 10kg',
        sku: 'FLR-010',
        unit: 'bag',
        price: 1950,
        distributorPrice: 1690,
        stock: 72,
        colorHex: '#A16207'),
    Product(
        id: 'p-4',
        name: 'Ceylon Tea 500g',
        sku: 'TEA-500',
        unit: 'pack',
        price: 890,
        distributorPrice: 760,
        stock: 210,
        colorHex: '#16A34A'),
    Product(
        id: 'p-5',
        name: 'White Sugar 1kg',
        sku: 'SUG-001',
        unit: 'pack',
        price: 285,
        distributorPrice: 245,
        stock: 480,
        colorHex: '#64748B'),
    Product(
        id: 'p-6',
        name: 'Red Lentils 1kg',
        sku: 'LNT-001',
        unit: 'pack',
        price: 540,
        distributorPrice: 470,
        stock: 165,
        colorHex: '#DC2626'),
    Product(
        id: 'p-7',
        name: 'Coconut Milk 400ml',
        sku: 'CCM-400',
        unit: 'can',
        price: 420,
        distributorPrice: 360,
        stock: 300,
        colorHex: '#0D9488'),
    Product(
        id: 'p-8',
        name: 'Detergent Powder 2kg',
        sku: 'DET-002',
        unit: 'pack',
        price: 1150,
        distributorPrice: 985,
        stock: 84,
        colorHex: '#2563EB'),
    Product(
        id: 'p-9',
        name: 'Milk Powder 400g',
        sku: 'MLK-400',
        unit: 'pack',
        price: 1350,
        distributorPrice: 1175,
        stock: 130,
        colorHex: '#7C3AED'),
    Product(
        id: 'p-10',
        name: 'Salt 1kg',
        sku: 'SLT-001',
        unit: 'pack',
        price: 160,
        distributorPrice: 130,
        stock: 520,
        colorHex: '#0EA5E9'),
  ];

  static const shops = <Shop>[
    Shop(
      id: 's-1',
      name: 'Nimal Super Market',
      contactPerson: 'Nimal Silva',
      phone: '0774561230',
      email: 'nimal@nimalsuper.lk',
      address: '12 Galle Road, Colombo 03',
      creditLimit: 150000,
      balance: 42500,
    ),
    Shop(
      id: 's-2',
      name: 'Sunrise Stores',
      contactPerson: 'Anil Jayasuriya',
      phone: '0716549870',
      address: '45 Kandy Road, Kadawatha',
      creditLimit: 100000,
      balance: 0,
    ),
    Shop(
      id: 's-3',
      name: 'City Mart Kiribathgoda',
      contactPerson: 'Farhana Rizwan',
      phone: '0763338899',
      email: 'orders@citymart.lk',
      address: '3 Main Street, Kiribathgoda',
      creditLimit: 200000,
      balance: 88200,
    ),
    Shop(
      id: 's-4',
      name: 'Lanka Wholesale Point',
      contactPerson: 'Mohan Raj',
      phone: '0752224411',
      address: '78 Colombo Road, Kadawatha',
      creditLimit: 250000,
      balance: 120000,
    ),
    Shop(
      id: 's-5',
      name: 'Quick Stop Mini Mart',
      contactPerson: 'Dilshan Fernando',
      phone: '0728887766',
      address: '10 Station Road, Ragama',
      creditLimit: 75000,
      balance: 5300,
    ),
  ];

  static final shopOrders = <ShopOrder>[
    ShopOrder(
      id: 'so-1',
      orderNumber: 'SO-2210',
      shopId: 's-3',
      shopName: 'City Mart Kiribathgoda',
      shopAddress: '3 Main Street, Kiribathgoda',
      shopPhone: '0763338899',
      date: _daysAgo(0),
      status: ShopOrderStatus.collected,
      items: const [
        ShopOrderItem(
            productName: 'White Sugar 1kg', unit: 'pack', qty: 40, unitPrice: 310),
        ShopOrderItem(
            productName: 'Ceylon Tea 500g', unit: 'pack', qty: 12, unitPrice: 950),
      ],
      placedBy: 'Kamal Perera',
    ),
    ShopOrder(
      id: 'so-2',
      orderNumber: 'SO-2209',
      shopId: 's-1',
      shopName: 'Nimal Super Market',
      shopAddress: '12 Galle Road, Colombo 03',
      shopPhone: '0774561230',
      date: _daysAgo(1),
      status: ShopOrderStatus.processing,
      items: const [
        ShopOrderItem(
            productName: 'Sunflower Cooking Oil 5L', unit: 'bottle', qty: 10, unitPrice: 2650),
        ShopOrderItem(
            productName: 'Premium Basmati Rice 5kg', unit: 'bag', qty: 8, unitPrice: 3100),
      ],
      placedBy: 'Kamal Perera',
      invoiceNumber: 'INV-3388',
    ),
    ShopOrder(
      id: 'so-3',
      orderNumber: 'SO-2208',
      shopId: 's-4',
      shopName: 'Lanka Wholesale Point',
      shopAddress: '78 Colombo Road, Kadawatha',
      shopPhone: '0752224411',
      date: _daysAgo(2),
      status: ShopOrderStatus.loaded,
      items: const [
        ShopOrderItem(
            productName: 'Detergent Powder 2kg', unit: 'pack', qty: 15, unitPrice: 1090),
      ],
      placedBy: 'Ravi (Rep)',
      invoiceNumber: 'INV-3387',
    ),
    ShopOrder(
      id: 'so-4',
      orderNumber: 'SO-2207',
      shopId: 's-5',
      shopName: 'Quick Stop Mini Mart',
      shopAddress: '10 Station Road, Ragama',
      shopPhone: '0728887766',
      date: _daysAgo(3),
      status: ShopOrderStatus.delivered,
      items: const [
        ShopOrderItem(
            productName: 'Milk Powder 400g', unit: 'pack', qty: 6, unitPrice: 1280),
        ShopOrderItem(
            productName: 'Salt 1kg', unit: 'pack', qty: 20, unitPrice: 175),
      ],
      placedBy: 'Ravi (Rep)',
      invoiceNumber: 'INV-3385',
      paymentStatus: 'paid',
    ),
    ShopOrder(
      id: 'so-5',
      orderNumber: 'SO-2206',
      shopId: 's-2',
      shopName: 'Sunrise Stores',
      shopAddress: '45 Kandy Road, Kadawatha',
      shopPhone: '0716549870',
      date: _daysAgo(5),
      status: ShopOrderStatus.delivered,
      items: const [
        ShopOrderItem(
            productName: 'Wheat Flour 10kg', unit: 'bag', qty: 12, unitPrice: 1850),
      ],
      placedBy: 'Kamal Perera',
      invoiceNumber: 'INV-3382',
      paymentStatus: 'partially_paid',
    ),
  ];

  static const _company = InvoiceParty(
    name: 'Inzeedo Manufacturing (Pvt) Ltd',
    address: 'No. 15, Industrial Estate, Biyagama',
    phone: '0112408800',
  );

  static final invoices = <Invoice>[
    Invoice(
      id: 'inv-1',
      invoiceNumber: 'INV-3388',
      date: _daysAgo(1),
      shopId: 's-1',
      shopName: 'Nimal Super Market',
      shopAddress: '12 Galle Road, Colombo 03',
      shopPhone: '0774561230',
      items: const [
        InvoiceItem(
            productName: 'Sunflower Cooking Oil 5L', unit: 'bottle', qty: 10, unitPrice: 2650),
        InvoiceItem(
            productName: 'Premium Basmati Rice 5kg', unit: 'bag', qty: 8, unitPrice: 3100),
      ],
      status: InvoiceStatus.unpaid,
      company: _company,
      distributedBy: InvoiceParty(
        name: 'Kamal Traders',
        address: 'No. 88, Kandy Road, Kiribathgoda',
        phone: '0112456789',
      ),
    ),
    Invoice(
      id: 'inv-2',
      invoiceNumber: 'INV-3387',
      date: _daysAgo(2),
      shopId: 's-4',
      shopName: 'Lanka Wholesale Point',
      shopAddress: '78 Colombo Road, Kadawatha',
      shopPhone: '0752224411',
      items: const [
        InvoiceItem(
            productName: 'Detergent Powder 2kg', unit: 'pack', qty: 15, unitPrice: 1090),
      ],
      status: InvoiceStatus.unpaid,
      company: _company,
      distributedBy: InvoiceParty(
        name: 'Kamal Traders',
        address: 'No. 88, Kandy Road, Kiribathgoda',
        phone: '0112456789',
      ),
    ),
    Invoice(
      id: 'inv-3',
      invoiceNumber: 'INV-3385',
      date: _daysAgo(3),
      shopId: 's-5',
      shopName: 'Quick Stop Mini Mart',
      shopAddress: '10 Station Road, Ragama',
      shopPhone: '0728887766',
      items: const [
        InvoiceItem(
            productName: 'Milk Powder 400g', unit: 'pack', qty: 6, unitPrice: 1280),
        InvoiceItem(productName: 'Salt 1kg', unit: 'pack', qty: 20, unitPrice: 175),
      ],
      status: InvoiceStatus.paid,
      company: _company,
      distributedBy: InvoiceParty(
        name: 'Kamal Traders',
        address: 'No. 88, Kandy Road, Kiribathgoda',
        phone: '0112456789',
      ),
    ),
    Invoice(
      id: 'inv-4',
      invoiceNumber: 'INV-3382',
      date: _daysAgo(5),
      shopId: 's-2',
      shopName: 'Sunrise Stores',
      shopAddress: '45 Kandy Road, Kadawatha',
      shopPhone: '0716549870',
      items: const [
        InvoiceItem(
            productName: 'Wheat Flour 10kg', unit: 'bag', qty: 12, unitPrice: 1850),
      ],
      discount: 300,
      status: InvoiceStatus.partiallyPaid,
      company: _company,
      distributedBy: InvoiceParty(
        name: 'Kamal Traders',
        address: 'No. 88, Kandy Road, Kiribathgoda',
        phone: '0112456789',
      ),
    ),
  ];
}
