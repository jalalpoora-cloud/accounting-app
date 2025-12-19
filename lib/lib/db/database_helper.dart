import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:jdatetime/jdatetime.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/check.dart';
import '../models/inventory_transaction.dart';
import '../models/payment.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._privateConstructor();

  static DatabaseHelper get instance => _instance ??= DatabaseHelper._privateConstructor();

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'accounting.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        previous_balance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        low_stock_threshold INTEGER DEFAULT 10
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        items TEXT,
        total_amount REAL,
        paid_amount REAL,
        previous_balance REAL,
        date TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        check_number TEXT,
        amount REAL,
        due_date TEXT,
        bank TEXT,
        status TEXT DEFAULT 'pending',  -- pending, paid, bounced
        customer_id INTEGER,
        type TEXT,  -- received or issued
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        amount REAL,
        payment_type TEXT,  -- cash, check, installment
        date TEXT,
        description TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        type TEXT,  -- in or out
        reason TEXT,
        date TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // ==== Customers ====
  Future<int> insertCustomer(Customer customer) async {
    Database db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getCustomers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<int> updateCustomer(Customer customer) async {
    Database db = await database;
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  // ==== Products ====
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    Database db = await database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  // ==== Invoices, Checks, Payments, Inventory ====
  // (متدهای دیگه مثل insertInvoice, insertCheck, insertPayment, insertTransaction و ... رو در فایل‌های بعدی اضافه می‌کنیم)

  // پشتیبان‌گیری ساده
  Future<String> backup() async {
    var dbPath = join(await getDatabasesPath(), 'accounting.db');
    var backupDir = await getApplicationDocumentsDirectory();
    var backupPath = join(backupDir.path, 'backup_${JDateTime.now().toString().replaceAll('/', '-')}.db');
    await File(dbPath).copy(backupPath);
    return backupPath;
  }
}
