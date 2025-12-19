import 'package:jdatetime/jdatetime.dart';

class Check {
  int? id;
  String checkNumber;     // شماره چک
  double amount;          // مبلغ چک
  JDateTime dueDate;      // تاریخ سررسید
  String bank;            // نام بانک
  String status;          // pending (در جریان), paid (وصول شده), bounced (برگشتی)
  int? customerId;        // مشتری مرتبط (برای چک دریافتی)
  String type;            // received (دریافتی از مشتری), issued (صادر شده به تامین‌کننده)

  Check({
    this.id,
    required this.checkNumber,
    required this.amount,
    required this.dueDate,
    required this.bank,
    this.status = 'pending',
    this.customerId,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'check_number': checkNumber,
      'amount': amount,
      'due_date': dueDate.toString(),
      'bank': bank,
      'status': status,
      'customer_id': customerId,
      'type': type,
    };
  }

  factory Check.fromMap(Map<String, dynamic> map) {
    return Check(
      id: map['id'],
      checkNumber: map['check_number'] ?? '',
      amount: map['amount'] ?? 0.0,
      dueDate: JDateTime.parse(map['due_date']),
      bank: map['bank'] ?? '',
      status: map['status'] ?? 'pending',
      customerId: map['customer_id'],
      type: map['type'] ?? 'received',
    );
  }

  // آیا چک سررسید شده؟
  bool get isOverdue {
    return JDateTime.now().isAfter(dueDate);
  }

  // آیا چک نزدیک سررسید است؟ (مثلاً ۳ روز مانده)
  bool get isNearDue {
    final daysLeft = dueDate.difference(JDateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 3;
  }
}
