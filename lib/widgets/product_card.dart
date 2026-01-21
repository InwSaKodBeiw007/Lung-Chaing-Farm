// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
// Ensure this is imported
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService
import 'package:lung_chaing_farm/screens/auth/register_screen.dart'; // Import RegisterScreen
import 'package:lung_chaing_farm/widgets/shared/image_gallery_swiper.dart'; // Import ImageGallerySwiper

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(int id, double currentStock) onSell;
  final Function(int id) onDelete;
  final Function()? onEdit; // Add onEdit callback
  final String? userRole; // Add userRole here

  const ProductCard({
    super.key,
    required this.product,
    required this.onSell,
    required this.onDelete,
    this.onEdit, // Initialize onEdit
    this.userRole, // Initialize userRole
  });

  @override
  Widget build(BuildContext context) {
    final String name = product['name'];
    final double price = (product['price'] as num).toDouble();
    final double stock = (product['stock'] as num).toDouble();
    final int id = product['id'];

    // Retrieve imageUrls as a list
    final List<String> imageUrls =
        (product['image_urls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final bool isLowStock = stock < 5;

    // Determine if the current user is a Villager
    final bool isVillager = userRole == 'VILLAGER';
    final bool isUser = userRole == 'USER';
    final bool isVisitor = userRole == null;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ImageGallerySwiper(imageUrls: imageUrls)),
            const SizedBox(height: 8.0),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (product['farm_name'] != null)
              Text(
                'Farm: ${product['farm_name']}',
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
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
                if (isUser ||
                    isVillager ||
                    isVisitor) // Show Sell/Buy button for all roles
                  ElevatedButton(
                    onPressed: stock > 0
                        ? () {
                            AudioService.playClickSound(); // Play sound on sell/buy
                            if (isVisitor) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            } else {
                              onSell(id, stock);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isVisitor ? 'Buy' : 'Sell 1kg'),
                  ),
                if (isVillager &&
                    onEdit != null) // Only show Edit button for Villager
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      AudioService.playClickSound(); // Play sound on edit
                      onEdit!();
                    },
                  ),
                if (isVillager) // Only show Delete button for Villager
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
