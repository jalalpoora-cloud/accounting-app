import 'package:flutter/material.dart';
import 'customer_list_page.dart';
import 'product_list_page.dart';
import 'invoice_list_page.dart';
import 'check_list_page.dart';
import 'inventory_page.dart';
import 'report_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // برای نمایش هشدار چک‌های نزدیک سررسید
  int nearDueChecksCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNearDueChecks();
  }

  Future<void> _loadNearDueChecks() async {
    // بعداً اینجا تعداد چک‌های نزدیک سررسید رو از دیتابیس می‌خونیم
    // فعلاً صفر نگه می‌داریم
    setState(() {
      nearDueChecksCount = 0; // placeholder
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابداری و انبارداری'),
        centerTitle: true,
        actions: [
          if (nearDueChecksCount > 0)
            Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$nearDueChecksCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _menuButton(context, Icons.people, 'مشتریان', const CustomerListPage()),
            _menuButton(context, Icons.inventory_2, 'کالاها', const ProductListPage()),
            _menuButton(context, Icons.receipt_long, 'فاکتورها', const InvoiceListPage()),
            _menuButton(context, Icons.account_balance_wallet, 'چک‌ها', const CheckListPage()),
            _menuButton(context, Icons.warehouse, 'انبارداری', const InventoryPage()),
            _menuButton(context, Icons.bar_chart, 'گزارش‌ها', const ReportPage()),
            _menuButton(context, Icons.settings, 'تنظیمات', const SettingsPage()),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, IconData icon, String title, Widget page) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
