import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../db/database_helper.dart';
import '../models/product.dart';
import 'add_edit_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> products = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    List<Product> allProducts = await DatabaseHelper.instance.getProducts();
    if (searchQuery.isNotEmpty) {
      allProducts = allProducts.where((p) =>
          p.name.contains(searchQuery) ||
          (p.barcode != null && p.barcode!.contains(searchQuery))).toList();
    }
    setState(() {
      products = allProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کالاها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch(context: context, delegate: _ProductSearchDelegate(products));
              if (query != null && query.isNotEmpty) {
                searchQuery = query;
                _loadProducts();
              }
            },
          ),
        ],
      ),
      body: products.isEmpty
          ? const Center(child: Text('هنوز کالایی ثبت نشده'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final bool lowStock = product.isLowStock;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: lowStock ? Colors.red[50] : null,
                  child: ListTile(
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.barcode != null) Text('بارکد: ${product.barcode}'),
                        Text('قیمت: ${product.price.toStringAsFixed(0)} تومان'),
                        Text('موجودی: \( {product.quantity} عدد \){lowStock ? ' (کمبود!)' : ''}'),
                      ],
                    ),
                    trailing: product.barcode != null
                        ? IconButton(
                            icon: const Icon(Icons.qr_code),
                            onPressed: () => _showBarcodeDialog(context, product),
                          )
                        : null,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditProductPage(product: product)),
                      );
                      _loadProducts();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductPage()),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add_box),
      ),
    );
  }

  void _showBarcodeDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: BarcodeWidget(
          barcode: Barcode.code128(),
          data: product.barcode ?? product.id.toString(),
          width: 200,
          height: 100,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
        ],
      ),
    );
  }
}

class _ProductSearchDelegate extends SearchDelegate<String> {
  final List<Product> products;

  _ProductSearchDelegate(this.products);

  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products.where((p) => p.name.contains(query) || (p.barcode?.contains(query) ?? false)).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          title: Text(product.name),
          subtitle: product.barcode != null ? Text('بارکد: ${product.barcode}') : null,
          onTap: () => close(context, query),
        );
      },
    );
  }
}
