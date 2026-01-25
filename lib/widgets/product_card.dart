import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:lung_chaing_farm/models/product.dart'; // Import Product model
import 'package:lung_chaing_farm/screens/auth/register_screen.dart'; // Import RegisterScreen
import 'package:lung_chaing_farm/screens/shared/product_detail_screen.dart'; // Import ProductDetailScreen
import 'package:lung_chaing_farm/services/audio_service.dart'; // Import AudioService
import 'package:lung_chaing_farm/widgets/shared/image_gallery_swiper.dart'; // Import ImageGallerySwiper
// Import QuickBuyModal

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(Product product) onSell; // Modified to accept Product object
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
    final String name = product.name;
    final double price = product.price;
    final double stock = product.stock;
    final int id = product.id;
    final String? category = product.category;
    final double lowStockThreshold = product.lowStockThreshold ?? 0.0;
    final int? lowStockSinceDate = product.lowStockSinceDate;

    // Retrieve imageUrls as a list
    final List<String> imageUrls = product.imageUrls;

    final bool isLowStock = stock <= lowStockThreshold;

    // Determine if the current user is a Villager
    final bool isVillager = userRole == 'VILLAGER';
    final bool isUser = userRole == 'USER';
    final bool isVisitor = userRole == null;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          AudioService.playClickSound(); // Play sound on tap
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
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
              if (product.farmName != null)
                Text(
                  'Farm: ${product.farmName}',
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              Text('Price: ฿${price.toStringAsFixed(2)}/kg'),
              if (category != null) Text('Category: $category'),
              Row(
                children: [
                  Text('Stock: ${stock.toStringAsFixed(2)} kg'),
                  if (isVillager)
                    Text(
                      ' (Threshold: ${lowStockThreshold.toStringAsFixed(2)} kg)',
                    ),
                  if (isLowStock)
                    Padding(
                      // Removed const
                      padding: const EdgeInsets.only(left: 4.0),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                ],
              ),
              if (isVillager && lowStockSinceDate != null)
                Text(
                  'Low Stock Since: ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(lowStockSinceDate * 1000))}',
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
                              if (isVisitor) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              } else {
                                onSell(
                                  product,
                                ); // Pass the entire product object
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
                        onEdit!();
                      },
                    ),
                  if (isVillager) // Only show Delete button for Villager
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        onDelete(id);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
