import 'package:flutter/material.dart';
import 'package:jdatetime/jdatetime.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../db/database_helper.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/inventory_transaction.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  Customer? selectedCustomer;
  List<Customer> customers = [];
  List<Product> products = [];
  List<InvoiceItem> items = [];
  double paidAmount = 0.0;
  final TextEditingController _paidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    customers = await DatabaseHelper.instance.getCustomers();
    products = await DatabaseHelper.instance.getProducts();
    if (customers.isNotEmpty) selectedCustomer = customers.first;
    setState(() {});
  }

  void _addProduct(Product product, int quantity) {
    if (product.quantity < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('موجودی کافی نیست! موجودی فعلی: ${product.quantity}')),
      );
      return;
    }
    setState(() {
      items.add(InvoiceItem(
        product: product,
        quantity: quantity,
        priceAtSale: product.price,
      ));
    });
  }

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  double get remaining => (selectedCustomer?.previousBalance ?? 0) + totalAmount - paidAmount;

  Future<void> _scanBarcode() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('اسکن بارکد کالا')),
          body: MobileScanner(
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  final product = await DatabaseHelper.instance.getProductByBarcode(code);
                  if (product != null) {
                    _showQuantityDialog(product);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کالا یافت نشد')));
                  }
                  Navigator.pop(context);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'تعداد'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 1;
              if (qty > 0) _addProduct(product, qty);
              Navigator.pop(ctx);
            },
            child: const Text('اضافه'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndPrintInvoice() async {
    if (selectedCustomer == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مشتری و کالا انتخاب کنید')));
      return;
    }

    final invoice = Invoice(
      customerId: selectedCustomer!.id!,
      items: items,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      previousBalance: selectedCustomer!.previousBalance,
      date: JDateTime.now(),
    );

    // ذخیره فاکتور (متد بعداً اضافه می‌شه)
    // await DatabaseHelper.instance.insertInvoice(invoice);

    // کاهش موجودی انبار
    for (var item in items) {
      final transaction = InventoryTransaction(
        productId: item.product.id!,
        quantity: -item.quantity,
        type: 'out',
        reason: 'فروش فاکتور',
        date: JDateTime.now(),
      );
      // await DatabaseHelper.instance.insertTransaction(transaction);
      item.product.updateQuantity(item.quantity, isIncoming: false);
      await DatabaseHelper.instance.updateProduct(item.product);
    }

    // بروزرسانی مانده مشتری
    selectedCustomer!.updateBalance(totalAmount, isPayment: false);
    selectedCustomer!.updateBalance(paidAmount, isPayment: true);
    await DatabaseHelper.instance.updateCustomer(selectedCustomer!);

    // تولید PDF و چاپ/ارسال
    final pdfPath = await _generatePdf(invoice);
    await Printing.layoutPdf(onLayout: (_) => File(pdfPath).readAsBytesSync());

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فاکتور با موفقیت ذخیره و چاپ شد')));
    if (mounted) Navigator.pop(context);
  }

  Future<String> _generatePdf(Invoice invoice) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('فاکتور فروش', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('مشتری: ${selectedCustomer!.name}'),
            pw.Text('تاریخ: ${invoice.date.toString()}'),
            pw.Text('مانده قبلی: ${invoice.previousBalance.toStringAsFixed(0)} تومان'),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['ردیف', 'کالا', 'تعداد', 'قیمت', 'مجموع'],
              data: List.generate(items.length, (i) {
                final item = items[i];
                return [
                  (i + 1).toString(),
                  item.product.name,
                  item.quantity.toString(),
                  item.priceAtSale.toStringAsFixed(0),
                  item.total.toStringAsFixed(0),
                ];
              }),
            ),
            pw.SizedBox(height: 20),
            pw.Text('مجموع فاکتور: ${totalAmount.toStringAsFixed(0)} تومان'),
            pw.Text('پرداخت شده: ${paidAmount.toStringAsFixed(0)} تومان'),
            pw.Text('مانده جدید: ${remaining.toStringAsFixed(0)} تومان', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text('با تشکر از خرید شما'),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('\( {dir.path}/invoice_ \){invoice.date.toString().replaceAll('/', '-')}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> _shareInvoice() async {
    // مشابه _generatePdf بعد share
    final pdfPath = await _generatePdf(Invoice(
      customerId: selectedCustomer!.id!,
      items: items,
      totalAmount: totalAmount,
      paidAmount:
