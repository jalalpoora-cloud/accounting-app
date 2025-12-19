import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/customer.dart';
import 'add_edit_customer_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<Customer> customers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    List<Customer> allCustomers = await DatabaseHelper.instance.getCustomers();
    if (searchQuery.isNotEmpty) {
      allCustomers = allCustomers.where((c) =>
          c.name.contains(searchQuery) || c.phone.contains(searchQuery)).toList();
    }
    setState(() {
      customers = allCustomers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت مشتریان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: _CustomerSearchDelegate(customers),
              );
              if (query != null && query.isNotEmpty) {
                setState(() {
                  searchQuery = query;
                });
                _loadCustomers();
              }
            },
          ),
        ],
      ),
      body: customers.isEmpty
          ? const Center(child: Text('هنوز مشتری ثبت نشده'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('تلفن: \( {customer.phone}\nمانده حساب: \){customer.previousBalance.toStringAsFixed(0)} تومان'),
                    isThreeLine: true,
                    trailing: Icon(
                      customer.previousBalance > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: customer.previousBalance > 0 ? Colors.red : Colors.green,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditCustomerPage(customer: customer),
                        ),
                      );
                      _loadCustomers();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCustomerPage()),
          );
          _loadCustomers();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// جستجوی ساده
class _CustomerSearchDelegate extends SearchDelegate<String> {
  final List<Customer> customers;

  _CustomerSearchDelegate(this.customers);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = customers
        .where((c) => c.name.contains(query) || c.phone.contains(query))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final customer = suggestions[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: Text(customer.phone),
          onTap: () => close(context, query),
        );
      },
    );
  }
}
