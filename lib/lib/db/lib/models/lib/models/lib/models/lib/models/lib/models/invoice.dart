import 'package:jdatetime/jdatetime.dart';
import 'product.dart';

class InvoiceItem {
  Product product;
  int quantity;
  double priceAtSale;  // قیمت در زمان فروش (برای تاریخچه قیمت)

  InvoiceItem({
    required this.product,
    required this.quantity,
    required this.priceAtSale,
  });

  double get total => quantity * priceAtSale;
}

class Invoice {
  int? id;
  int customerId;
  List<InvoiceItem> items;
  double totalAmount;
  double paidAmount;       // پرداخت نقدی در زمان فاکتور
  double previousBalance;  // مانده قبلی مشتری
  JDateTime date;

  Invoice({
    this.id,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.paidAmount,
    required this.previousBalance,
    required this.date,
  });

  // مانده جدید مشتری بعد از این فاکتور
  double get newBalance => previousBalance + totalAmount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'items': items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price_at_sale': item.priceAtSale,
      }).toList(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'previous_balance': previousBalance,
      'date': date.toString(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, List<Product> allProducts) {
    List<dynamic> itemsList = map['items'];
    List<InvoiceItem> loadedItems = itemsList.map((itemMap) {
      Product product = allProducts.firstWhere(
        (p) => p.id == itemMap['product_id'],
        orElse: () => Product(name: 'نامشخص', price: itemMap['price_at_sale']),
      );
      return InvoiceItem(
        product: product,
        quantity: itemMap['quantity'],
        priceAtSale: itemMap['price_at_sale'],
      );
    }).toList();

    return Invoice(
      id: map['id'],
      customerId: map['customer_id'],
      items: loadedItems,
      totalAmount: map['total_amount'],
      paidAmount: map['paid_amount'],
      previousBalance: map['previous_balance'],
      date: JDateTime.parse(map['date']),
    );
  }
}
