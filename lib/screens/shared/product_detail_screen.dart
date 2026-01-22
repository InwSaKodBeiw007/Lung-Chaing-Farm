import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/widgets/product_transaction_history.dart';
import 'package:lung_chaing_farm/widgets/shared/image_gallery_swiper.dart';

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
      body: SingleChildScrollView(
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
            const Text(
              'Transaction History:',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            ProductTransactionHistory(productId: product.id),
          ],
        ),
      ),
    );
  }
}
