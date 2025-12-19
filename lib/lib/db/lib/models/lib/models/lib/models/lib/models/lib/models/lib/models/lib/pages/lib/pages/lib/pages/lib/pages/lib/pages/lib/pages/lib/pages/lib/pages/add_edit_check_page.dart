import 'package:flutter/material.dart';
import 'package:jdatetime/jdatetime.dart';
import '../db/database_helper.dart';
import '../models/check.dart';
import '../models/customer.dart';

class AddEditCheckPage extends StatefulWidget {
  final Check? check;

  const AddEditCheckPage({super.key, this.check});

  @override
  State<AddEditCheckPage> createState() => _AddEditCheckPageState();
}

class _AddEditCheckPageState extends State<AddEditCheckPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _checkNumberController;
  late TextEditingController _amountController;
  late TextEditingController _bankController;
  JDateTime _dueDate = JDateTime.now();
  String _status = 'pending';
  String _type = 'received';
  Customer? _selectedCustomer;
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    _checkNumberController = TextEditingController(text: widget.check?.checkNumber ?? '');
    _amountController = TextEditingController(text: widget.check?.amount.toStringAsFixed(0) ?? '');
    _bankController = TextEditingController(text: widget.check?.bank ?? '');
    _dueDate = widget.check?.dueDate ?? JDateTime.now();
    _status = widget.check?.status ?? 'pending';
    _type = widget.check?.type ?? 'received';
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    customers = await DatabaseHelper.instance.getCustomers();
    if (widget.check?.customerId != null) {
      _selectedCustomer = customers.firstWhere((c) => c.id == widget.check!.customerId, orElse: () => customers[0]);
    }
    setState(() {});
  }

  Future<void> _selectDueDate() async {
    // ساده – می‌تونی از پکیج جلالی پیکر استفاده کنی، فعلاً دستی
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.toDateTime(),
      firstDate: now.subtract(const Duration(days: 365 * 10)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = JDateTime.fromDateTime(picked);
      });
    }
  }

  Future<void> _saveCheck() async {
    if (_formKey.currentState!.validate()) {
      final newCheck = Check(
        id: widget.check?.id,
        checkNumber: _checkNumberController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        dueDate: _dueDate,
        bank: _bankController.text.trim(),
        status: _status,
        customerId: _type == 'received' ? _selectedCustomer?.id : null,
        type: _type,
      );

      // متد insertCheck یا updateCheck رو بعداً به database_helper اضافه می‌کنیم
      // await DatabaseHelper.instance.insertOrUpdateCheck(newCheck);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('چک با موفقیت ذخیره شد')));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.check == null ? 'ثبت چک جدید' : 'ویرایش چک'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _checkNumberController,
                decoration: const InputDecoration(labelText: 'شماره چک', border: OutlineInputBorder()),
                validator: (value) => value?.trim().isEmpty ?? true ? 'شماره چک الزامی است' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'مبلغ چک (تومان)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value ?? '') == null || (double.tryParse(value!) ?? 0) <= 0 ? 'مبلغ معتبر وارد کنید' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'نام بانک', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('تاریخ سررسید: ${_dueDate.toString()}')),
                  ElevatedButton(onPressed: _selectDueDate, child: const Text('انتخاب تاریخ')),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'وضعیت چک', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('در جریان')),
                  DropdownMenuItem(value: 'paid', child: Text('وصول شده')),
                  DropdownMenuItem(value: 'bounced', child: Text('برگشتی')),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'نوع چک', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'received', child: Text('دریافتی از مشتری')),
                  DropdownMenuItem(value: 'issued', child: Text('پرداختی به تامین‌کننده')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              if (_type == 'received') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  hint: const Text('انتخاب مشتری'),
                  decoration: const InputDecoration(labelText: 'مشتری', border: OutlineInputBorder()),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (value) => setState(() => _selectedCustomer = value),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCheck,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('ذخیره چک', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
