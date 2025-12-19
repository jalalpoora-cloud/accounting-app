import 'package:flutter/material.dart';
import 'package:jdatetime/jdatetime.dart';
import '../db/database_helper.dart';
import '../models/check.dart';
import '../models/customer.dart';
import 'add_edit_check_page.dart';

class CheckListPage extends StatefulWidget {
  const CheckListPage({super.key});

  @override
  State<CheckListPage> createState() => _CheckListPageState();
}

class _CheckListPageState extends State<CheckListPage> {
  List<Check> checks = [];

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    // فعلاً placeholder – متد getChecks رو بعداً به database_helper اضافه می‌کنیم
    // checks = await DatabaseHelper.instance.getChecks();
    setState(() {
      checks = []; // برای حالا خالی
    });
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'وصول شده';
      case 'bounced':
        return 'برگشتی';
      default:
        return 'در جریان';
    }
  }

  Color _getStatusColor(String status, bool isOverdue, bool isNearDue) {
    if (isOverdue) return Colors.red;
    if (isNearDue) return Colors.orange;
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'bounced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت چک‌ها'),
      ),
      body: checks.isEmpty
          ? const Center(child: Text('هنوز چکی ثبت نشده'))
          : ListView.builder(
              itemCount: checks.length,
              itemBuilder: (context, index) {
                final check = checks[index];
                final bool overdue = check.isOverdue;
                final bool nearDue = check.isNearDue;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: overdue ? Colors.red[50] : (nearDue ? Colors.orange[50] : null),
                  child: ListTile(
                    title: Text('چک \( {check.checkNumber} - \){check.amount.toStringAsFixed(0)} تومان'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('بانک: ${check.bank}'),
                        Text('سررسید: \( {check.dueDate.toString()} \){overdue ? '(سررسید گذشته!)' : (nearDue ? '(نزدیک سررسید)' : '')}'),
                        Text('وضعیت: ${_getStatusText(check.status)}'),
                        if (check.customerId != null) Text('مشتری مرتبط: مشتری ID ${check.customerId}'),
                        Text('نوع: ${check.type == 'received' ? 'دریافتی' : 'پرداختی'}'),
                      ],
                    ),
                    trailing: Icon(Icons.cheque, color: _getStatusColor(check.status, overdue, nearDue)),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditCheckPage(check: check)),
                      );
                      _loadChecks();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCheckPage()),
          );
          _loadChecks();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
