import 'package:flutter/material.dart';
import 'package:jdatetime/jdatetime.dart';
import '../db/database_helper.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'create_invoice_page.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Invoice> invoices = [];
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    customers = await DatabaseHelper.instance.getCustomers();
    // invoices = await DatabaseHelper.instance.getInvoices(); // بعداً اضافه می‌کنیم
    setState(() {
      invoices = []; // placeholder
    });
  }

  String _getCustomerName(int customerId) {
    try {
      return customers.firstWhere((c) => c.id == customerId).name;
    } catch (e) {
      return 'مشتری حذف شده';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست فاکتورها'),
      ),
      body: invoices.isEmpty
          ? const Center(child: Text('هنوز فاکتوری صادر نشده'))
          : ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                final customerName = _getCustomerName(invoice.customerId);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text('فاکتور برای $customerName'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تاریخ: ${invoice.date.toString()}'),
                        Text('مجموع: ${invoice.totalAmount.toStringAsFixed(0)} تومان'),
                        Text('پرداخت شده: ${invoice.paidAmount.toStringAsFixed(0)} تومان'),
                        Text(
                          'مانده: ${invoice.newBalance.toStringAsFixed(0)} تومان',
                          style: TextStyle(
                            color: invoice.newBalance > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () {
                            // بعداً چاپ PDF
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('چاپ فاکتور (در نسخه نهایی)')));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // بعداً ارسال PDF
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ارسال فاکتور (در نسخه نهایی)')));
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // جزئیات فاکتور یا ویرایش
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (customers.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا مشتری ثبت کنید')));
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoicePage()),
          );
          _loadData();
        },
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
