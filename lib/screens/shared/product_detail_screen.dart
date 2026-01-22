import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/widgets/product_transaction_history.dart';
import 'package:lung_chaing_farm/widgets/shared/image_gallery_swiper.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/services/api_service.dart'; // Needed for fetching transactions

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String formattedDate = product.lowStockSinceDate != null
        ? DateFormat('MMM d, yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(
              product.lowStockSinceDate! * 1000,
            ),
          )
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.lightGreen,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final String? currentUserRole = authProvider.user?.role;
          final bool isVillager = currentUserRole == 'VILLAGER';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 250, // Fixed height for the image swiper
                  child: ImageGallerySwiper(imageUrls: product.imageUrls),
                ),
                const SizedBox(height: 16.0),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                if (product.farmName != null)
                  Text(
                    'Farm: ${product.farmName}',
                    style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                  ),
                const SizedBox(height: 8.0),
                Text(
                  'Price: ฿${product.price.toStringAsFixed(2)}/kg',
                  style: const TextStyle(fontSize: 18.0),
                ),
                Text(
                  'Current Stock: ${product.stock.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontSize: 18.0),
                ),
                if (product.category != null)
                  Text(
                    'Category: ${product.category}',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                if (product.lowStockThreshold != null)
                  Text(
                    'Low Stock Threshold: ${product.lowStockThreshold!.toStringAsFixed(2)} kg',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                if (product.lowStockSinceDate != null)
                  Text(
                    'Low Stock Since: $formattedDate',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                const SizedBox(height: 24.0),
                if (isVillager) ...[
                  const Text(
                    'Transaction History:',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ProductTransactionHistory(productId: product.id),
                ] else if (authProvider.isAuthenticated) ...[
                  const Text(
                    'Sales Summary:',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: ApiService.instance.getProductTransactions(
                      product.id,
                      days: 365,
                    ), // Fetch all transactions for a year
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error loading sales: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No sales recorded yet.');
                      } else {
                        double totalSold = 0;
                        for (var transaction in snapshot.data!) {
                          totalSold += (transaction['quantity_sold'] as num)
                              .toDouble();
                        }
                        return Text(
                          'Total Units Sold: ${totalSold.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 18.0),
                        );
                      }
                    },
                  ),
                ] else ...[
                  // For Visitors (not authenticated)
                  const Text(
                    'Sales Summary:',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Login to view sales summary.',
                    style: TextStyle(fontSize: 18.0, color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
