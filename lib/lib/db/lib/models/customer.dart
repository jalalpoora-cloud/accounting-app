class Customer {
  int? id;
  String name;
  String phone;
  double previousBalance;  // بدهی مثبت، طلب منفی

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.previousBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'previous_balance': previousBalance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      previousBalance: map['previous_balance'] ?? 0.0,
    );
  }

  // محاسبه مانده جدید بعد از پرداخت یا فاکتور
  void updateBalance(double amount, {bool isPayment = false}) {
    if (isPayment) {
      previousBalance -= amount;  // پرداخت مشتری → کاهش بدهی
    } else {
      previousBalance += amount;  // فاکتور جدید → افزایش بدهی
    }
  }
}
