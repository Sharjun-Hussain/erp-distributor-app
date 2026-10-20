class Product {
  final String id;
  final String name;
  final String sku;
  final String unit;
  final double price;
  final double distributorPrice;
  final double stock;
  final String colorHex;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.price,
    required this.distributorPrice,
    required this.stock,
    this.colorHex = '#6366F1',
  });

  double get wholesalePrice => distributorPrice;
}

class CartLine {
  final Product product;
  final int qty;

  const CartLine({required this.product, required this.qty});

  double get lineTotal => product.distributorPrice * qty;
}

class Cart {
  final List<CartLine> lines;
  final String? shopId;

  const Cart({this.lines = const [], this.shopId});

  double get total =>
      lines.fold(0, (sum, line) => sum + line.lineTotal);

  int get itemCount => lines.fold(0, (sum, line) => sum + line.qty);

  int qtyOf(String productId) => lines
      .where((line) => line.product.id == productId)
      .fold(0, (sum, line) => sum + line.qty);
}
