import 'package:jdatetime/jdatetime.dart';

class InventoryTransaction {
  int? id;
  int productId;
  int quantity;      // مثبت برای ورود، منفی برای خروج
  String type;       // 'in' یا 'out'
  String reason;     // دلیل (مثلاً خرید، فروش، مرجوعی و ...)
  JDateTime date;

  InventoryTransaction({
    this.id,
    required this.productId,
    required this.quantity,
    required this.type,
    required this.reason,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'type': type,
      'reason': reason,
      'date': date.toString(),
    };
  }

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'],
      productId: map['product_id'],
      quantity: map['quantity'] ?? 0,
      type: map['type'] ?? 'out',
      reason: map['reason'] ?? '',
      date: JDateTime.parse(map['date']),
    );
  }
}
