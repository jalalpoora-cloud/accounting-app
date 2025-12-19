class Product {
  int? id;
  String? barcode;  // بارکد منحصر به فرد (اختیاری)
  String name;
  double price;
  int quantity;
  int lowStockThreshold;  // حداقل موجودی برای هشدار

  Product({
    this.id,
    this.barcode,
    required this.name,
    required this.price,
    this.quantity = 0,
    this.lowStockThreshold = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'] ?? '',
      price: map['price'] ?? 0.0,
      quantity: map['quantity'] ?? 0,
      lowStockThreshold: map['low_stock_threshold'] ?? 10,
    );
  }

  // چک کردن کمبود موجودی
  bool get isLowStock => quantity < lowStockThreshold;

  // بروزرسانی موجودی
  void updateQuantity(int change, {bool isIncoming = true}) {
    if (isIncoming) {
      quantity += change;
    } else {
      quantity -= change;
    }
  }
}
