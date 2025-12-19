import 'package:flutter/material.dart';
import 'package:jdatetime/jdatetime.dart';
import '../db/database_helper.dart';
import '../models/product.dart';
import '../models/inventory_transaction.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final loaded = await DatabaseHelper.instance.getProducts();
    setState(() {
      products = loaded;
    });
  }

  Future<void> _addTransaction(Product product, String type) async {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'in' ? 'ورود کالا' : 'خروج کالا'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('کالا: ${product.name}'),
            Text('موجودی فعلی: ${product.quantity}'),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'تعداد'),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'دلیل (مثلاً خرید، مرجوعی، فروش دستی)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () {
              if (quantityController.text.isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );

    if (result == true) {
      final quantity = int.tryParse(quantityController.text) ?? 0;
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعداد باید بیشتر از صفر باشد')));
        return;
      }

      final transaction = InventoryTransaction(
        productId: product.id!,
        quantity: type == 'in' ? quantity : -quantity,
        type: type,
        reason: reasonController.text.isNotEmpty ? reasonController.text : (type == 'in' ? 'ورود دستی' : 'خروج دستی'),
        date: JDateTime.now(),
      );

      // ذخیره تراکنش و بروزرسانی موجودی
      await DatabaseHelper.instance.insertTransaction(transaction); // این متد رو بعداً به database_helper اضافه می‌کنیم

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تراکنش $type با موفقیت ثبت شد')));
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت انبار')),
      body: products.isEmpty
          ? const Center(child: Text('هنوز کالایی ثبت نشده'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final lowStock = product.isLowStock;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: lowStock ? Colors.orange[50] : null,
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text('موجودی: \( {product.quantity} عدد \){lowStock ? ' (کمبود!)' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: 'ورود کالا',
                          onPressed: () => _addTransaction(product, 'in'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          tooltip: 'خروج کالا',
                          onPressed: () => _addTransaction(product, 'out'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
