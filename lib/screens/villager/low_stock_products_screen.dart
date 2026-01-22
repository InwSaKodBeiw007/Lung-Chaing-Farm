import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/providers/low_stock_provider.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/services/audio_service.dart';
import 'package:lung_chaing_farm/services/notification_service.dart';
import 'package:lung_chaing_farm/widgets/product_transaction_history.dart';

class LowStockProductsScreen extends StatefulWidget {
  const LowStockProductsScreen({super.key});

  @override
  State<LowStockProductsScreen> createState() => _LowStockProductsScreenState();
}

class _LowStockProductsScreenState extends State<LowStockProductsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchLowStockProducts();
  }

  void _fetchLowStockProducts() {
    AudioService.playClickSound();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lowStockProvider = Provider.of<LowStockProvider>(
      context,
      listen: false,
    );

    if (authProvider.isAuthenticated &&
        authProvider.user?.role == 'VILLAGER' &&
        authProvider.user != null &&
        authProvider.user?.token != null) {
      lowStockProvider.fetchLowStockProducts(authProvider.user!.token);
    } else {
      lowStockProvider.clearLowStockData();
      NotificationService.showSnackBar(
        'Please login as a Villager to view low stock products.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Products'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLowStockProducts,
          ),
        ],
      ),
      body: Consumer<LowStockProvider>(
        builder: (context, lowStockProvider, child) {
          if (lowStockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (lowStockProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${lowStockProvider.errorMessage}'),
            );
          } else if (lowStockProvider.lowStockProducts.isEmpty) {
            return const Center(
              child: Text('No products currently low in stock.'),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: lowStockProvider.lowStockProducts.length,
              itemBuilder: (context, index) {
                final Product product =
                    lowStockProvider.lowStockProducts[index];
                final String formattedDate = product.lowStockSinceDate != null
                    ? DateFormat('MMM d, yyyy').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          product.lowStockSinceDate! * 1000,
                        ),
                      )
                    : 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text('Current Stock: ${product.stock}kg'),
                        Text(
                          'Low Stock Threshold: ${product.lowStockThreshold}kg',
                        ),
                        Text('Low Stock Since: $formattedDate'),
                        ExpansionTile(
                          title: const Text('View Transactions'),
                          children: [
                            ProductTransactionHistory(productId: product.id),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
