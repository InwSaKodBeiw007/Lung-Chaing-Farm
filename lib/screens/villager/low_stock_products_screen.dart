import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/low_stock_provider.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:intl/intl.dart'; // For date formatting

class LowStockProductsScreen extends StatelessWidget {
  const LowStockProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Products'),
        backgroundColor: Colors.red[700],
      ),
      body: Consumer<LowStockProvider>(
        builder: (context, lowStockProvider, child) {
          if (lowStockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (lowStockProvider.lowStockProducts.isEmpty) {
            return const Center(child: Text('No products currently low in stock.'));
          }

          return ListView.builder(
            itemCount: lowStockProvider.lowStockProducts.length,
            itemBuilder: (context, index) {
              final Product product = lowStockProvider.lowStockProducts[index];
              final String lowStockDate = product.lowStockSinceDate != null
                  ? DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(product.lowStockSinceDate! * 1000))
                  : 'N/A';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4.0,
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
                      Text('Threshold: ${product.lowStockThreshold}kg'),
                      Text('Low Stock Since: $lowStockDate'),
                      // TODO: Implement the expandable transaction history here (Phase 4)
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
