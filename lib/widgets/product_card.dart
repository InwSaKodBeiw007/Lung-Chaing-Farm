// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/services/api_service.dart'; // Ensure this is imported
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(int id, double currentStock) onSell;
  final Function(int id) onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onSell,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = product['name'];
    final double price = (product['price'] as num).toDouble();
    final double stock = (product['stock'] as num).toDouble();
    final String? imagePath = product['imagePath'];
    final int id = product['id'];

    final bool isLowStock = stock < 5;
    // Construct the full image URL
    final String imageUrl = imagePath != null
        ? '${ApiService.baseUrl}/${imagePath.replaceAll('\\', '/')}' // Replace backslashes for URL
        : '';

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imagePath != null && imagePath.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    )
                  : const Center(
                      child: Icon(Icons.photo, size: 50, color: Colors.grey)),
            ),
            const SizedBox(height: 8.0),
            Text(
              name,
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('Price: ฿${price.toStringAsFixed(2)}/kg'),
            Row(
              children: [
                Text('Stock: ${stock.toStringAsFixed(2)} kg'),
                if (isLowStock)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.warning, color: Colors.red, size: 18),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: stock > 0 ? () {
                    AudioService.playClickSound(); // Play sound on sell
                    onSell(id, stock);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sell 1kg'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    AudioService.playClickSound(); // Play sound on delete
                    onDelete(id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
