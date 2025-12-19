import 'package:flutter/material.dart';
import 'package:jdatetime/jdatetime.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../db/database_helper.dart';
import '../models/invoice.dart';
import '../models/check.dart';
import '../models/inventory_transaction.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  JDateTime selectedDate = JDateTime.now();
  double dailySales = 0.0;
  double dailyPayments = 0.0;
  List<Invoice> dailyInvoices = [];
  List<Check> nearDueChecks = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    // placeholder – متدها بعداً کامل می‌شن
    dailySales = 0.0; // مجموع فروش امروز
    dailyPayments = 0.0; // مجموع پرداخت‌های امروز
    dailyInvoices = [];
    nearDueChecks = [];

    setState(() {});
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['گزارش روزانه ${selectedDate.toString()}'];

    sheet.appendRow([
      'نوع',
      'توضیح',
      'مبلغ',
      'تاریخ',
    ]);

    // اضافه کردن فاکتورها
    for (var inv in dailyInvoices) {
      sheet.appendRow([
        'فروش',
        'فاکتور مشتری',
        inv.totalAmount,
        inv.date.toString(),
      ]);
    }

    // اضافه کردن پرداخت‌ها
    sheet.appendRow([
      'پرداخت نقدی',
      'از مشتریان',
      dailyPayments,
      selectedDate.toString(),
    ]);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('\( {dir.path}/report_ \){selectedDate.toString().replaceAll('/', '-')}.xlsx');
    await file.writeAsBytes(excel.encode()!);

    await Share.shareXFiles([XFile(file.path)], text: 'گزارش حسابداری ${selectedDate.toString()}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گزارش به اکسل صادر و آماده ارسال شد')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'خروجی اکسل',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('تاریخ گزارش: ${selectedDate.toString()}', style: const TextStyle(fontSize: 18)),
                IconButton(onPressed: () async {
                  // انتخاب تاریخ ساده
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.toDateTime(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = JDateTime.fromDateTime(picked);
                    });
                    _loadReport();
                  }
                }, icon: const Icon(Icons.calendar_today)),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('فروش روزانه: ${dailySales.toStringAsFixed(0)} تومان', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('پرداخت دریافتی: ${dailyPayments.toStringAsFixed(0)} تومان', style: const TextStyle(fontSize: 18)),
                    Text('سود خالص تقریبی: ${(dailySales - dailyPayments).toStringAsFixed(0)} تومان', style: const TextStyle(fontSize: 18, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('چک‌های نزدیک سررسید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: nearDueChecks.isEmpty
                  ? const Center(child: Text('چک نزدیک سررسید وجود ندارد'))
                  : ListView.builder(
                      itemCount: nearDueChecks.length,
                      itemBuilder: (context, index) {
                        final check = nearDueChecks[index];
                        return ListTile(
                          title: Text('چک \( {check.checkNumber} - \){check.amount.toStringAsFixed(0)} تومان'),
                          subtitle: Text('سررسید: ${check.dueDate.toString()}'),
                          trailing: const Icon(Icons.warning, color: Colors.orange),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
