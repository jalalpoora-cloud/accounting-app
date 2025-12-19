import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../db/database_helper.dart';
import '../models/product.dart';
import 'dart:math';

class AddEditProductPage extends StatefulWidget {
  final Product? product;

  const AddEditProductPage({super.key, this.product});

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _thresholdController;
  late TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toStringAsFixed(0) ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '0');
    _thresholdController = TextEditingController(text: widget.product?.lowStockThreshold.toString() ?? '10');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // تولید بارکد تصادفی (عدد ۱۲ رقمی)
  String _generateBarcode() {
    Random random = Random();
    return List.generate(12, (_) => random.nextInt(10)).join();
  }

  Future<void> _scanBarcode() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('اسکن بارکد')),
          body: MobileScanner(
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? '';
                final existing = await DatabaseHelper.instance.getProductByBarcode(code);
                if (existing != null && existing.id != widget.product?.id) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('این بارکد قبلاً برای کالای دیگری ثبت شده!')),
                  );
                } else {
                  setState(() {
                    _barcodeController.text = code;
                  });
                }
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        lowStockThreshold: int.tryParse(_thresholdController.text) ?? 10,
      );

      if (widget.product == null) {
        await DatabaseHelper.instance.insertProduct(product);
      } else {
        await DatabaseHelper.instance.updateProduct(product);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'اضافه کردن کالا' : 'ویرایش کالا'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'نام کالا', border: OutlineInputBorder()),
                validator: (value) => value?.trim().isEmpty ?? true ? 'نام کالا الزامی است' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'قیمت (تومان)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value ?? '') == null ? 'قیمت معتبر وارد کنید' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'موجودی اولیه', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                decoration: const InputDecoration(labelText: 'حداقل موجودی برای هشدار', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'بارکد', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                    tooltip: 'اسکن بارکد',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => _barcodeController.text = _generateBarcode()),
                    tooltip: 'تولید بارکد جدید',
                  ),
                ],
              ),
              if (_barcodeController.text.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: _barcodeController.text,
                    width: 250,
                    height: 100,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('ذخیره', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
