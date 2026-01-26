import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/widgets/product_card.dart';
import 'package:lung_chaing_farm/widgets/quick_buy_modal.dart'; // Import QuickBuyModal

class ProductListSection extends StatefulWidget {
  final String category;
  final String title;

  const ProductListSection({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends State<ProductListSection> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final apiService = ApiService();
    // Assuming getProducts can filter by category
    final List<Map<String, dynamic>> productMaps = await apiService.getProducts(
      category: widget.category,
    );
    return productMaps.map((map) => Product.fromJson(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen.shade800,
            ),
          ),
          const SizedBox(height: 16.0),
          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No products found in this category.'),
                );
              } else {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two columns
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75, // Adjust as needed
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final product = snapshot.data![index];
                    return ProductCard(
                      product: product,
                      onSell: (productToSell) {
                        // Changed signature
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return QuickBuyModal(
                              product: productToSell,
                              onConfirmPurchase: (productId, quantity) {
                                // TODO: Implement actual purchase logic here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Confirmed purchase of ${productToSell.name} (ID: $productId, Qty: $quantity)',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      onDelete: (productId) {
                        // TODO: Implement delete logic later
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Deleting ${product.name} (ID: $productId)',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
