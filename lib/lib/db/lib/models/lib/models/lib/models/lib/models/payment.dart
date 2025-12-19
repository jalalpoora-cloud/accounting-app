import 'package:jdatetime/jdatetime.dart';

class Payment {
  int? id;
  int customerId;
  double amount;
  String paymentType;  // cash, check, installment
  JDateTime date;
  String description;  // توضیح اختیاری، مثلاً شماره قسط یا شماره چک

  Payment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.paymentType,
    required this.date,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_type': paymentType,
      'date': date.toString(),
      'description': description,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      customerId: map['customer_id'],
      amount: map['amount'] ?? 0.0,
      paymentType: map['payment_type'] ?? 'cash',
      date: JDateTime.parse(map['date']),
      description: map['description'] ?? '',
    );
  }
}
