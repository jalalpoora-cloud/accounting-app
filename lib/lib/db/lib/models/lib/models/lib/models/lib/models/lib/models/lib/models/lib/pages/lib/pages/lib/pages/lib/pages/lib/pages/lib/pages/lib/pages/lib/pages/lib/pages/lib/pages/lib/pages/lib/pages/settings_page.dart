import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../db/database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _headerController = TextEditingController(text: 'فاکتور فروش');
  final TextEditingController _footerController = TextEditingController(text: 'با تشکر از خرید شما');
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _headerController.text = prefs.getString('invoice_header') ?? 'فاکتور فروش';
    _footerController.text = prefs.getString('invoice_footer') ?? 'با تشکر از خرید شما';
    _logoPath = prefs.getString('invoice_logo');
    setState(() {});
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoice_header', _headerController.text);
    await prefs.setString('invoice_footer', _footerController.text);
    if (_logoPath != null) {
      await prefs.setString('invoice_logo', _logoPath!);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تنظیمات ذخیره شد')));
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _logoPath = picked.path;
      });
    }
  }

  Future<void> _backupDatabase() async {
    final backupPath = await DatabaseHelper.instance.backup();
    await Share.shareXFiles([XFile(backupPath)], text: 'پشتیبان دیتابیس حسابداری');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پشتیبان گرفته شد و آماده ارسال است')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('ویرایش فرمت فاکتور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _headerController,
              decoration: const InputDecoration(labelText: 'متن بالای فاکتور (هدر)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _footerController,
              decoration: const InputDecoration(labelText: 'متن پایین فاکتور (فوتر)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(_logoPath == null ? 'لوگو انتخاب نشده' : 'لوگو انتخاب شده')),
                ElevatedButton(onPressed: _pickLogo, child: const Text('انتخاب لوگو')),
              ],
            ),
            if (_logoPath != null) ...[
              const SizedBox(height: 16),
              Image.file(File(_logoPath!), height: 100),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('ذخیره تنظیمات فاکتور'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const Text('پشتیبان‌گیری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: _backupDatabase,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('گرفتن پشتیبان از دیتابیس'),
            ),
            const SizedBox(height: 16),
            const Text('پشتیبان به صورت فایل .db ذخیره و قابل ارسال می‌شود. برای بازیابی در اپ جدید کپی کنید.'),
          ],
        ),
      ),
    );
  }
}
