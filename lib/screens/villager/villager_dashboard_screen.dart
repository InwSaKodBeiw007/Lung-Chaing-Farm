// lib/screens/villager/villager_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/widgets/product_card.dart';
import 'package:lung_chaing_farm/screens/add_product_screen.dart';
import 'package:lung_chaing_farm/services/audio_service.dart';
import 'package:lung_chaing_farm/services/notification_service.dart'; // Import NotificationService

class VillagerDashboardScreen extends StatefulWidget {
  const VillagerDashboardScreen({super.key});

  @override
  State<VillagerDashboardScreen> createState() => _VillagerDashboardScreenState();
}

class _VillagerDashboardScreenState extends State<VillagerDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _villagerProductsFuture;

  @override
  void initState() {
    super.initState();
    _fetchVillagerProducts();
  }

  void _fetchVillagerProducts() {
    AudioService.playClickSound(); // Play sound on refresh
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.user?.role == 'VILLAGER') {
      setState(() {
        // This will need modification in ApiService to filter by owner_id
        // For now, it fetches all products, and we'll filter on the frontend.
        // A more efficient way will be to have a backend endpoint /products/my
        _villagerProductsFuture = ApiService.getProducts().then((allProducts) {
          return allProducts.where((product) =>
              product['owner_id'] == authProvider.user!.id).toList();
        });
      });
    } else {
      // If not authenticated or not a villager, clear products
      setState(() {
        _villagerProductsFuture = Future.value([]);
      });
    }
  }

  void _navigateToAddNewProduct() async {
    AudioService.playClickSound(); // Play sound on add button click
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true) {
      _fetchVillagerProducts(); // Refresh products if a new one was added
    }
  }

  void _editProduct(int productId) {
    AudioService.playClickSound();
    // TODO: Implement navigation to an EditProductScreen
    NotificationService.showSnackBar('Edit product functionality not yet implemented.'); // Use NotificationService
  }

  void _sellProduct(int productId, double currentStock) async {
    if (currentStock > 0) {
      try {
        // Fetch full product details to get existing image URLs and category
        final productDetails = await ApiService.getProductById(productId);
        final List<String> existingImageUrls = (productDetails['image_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final String? category = productDetails['category'];

        final response = await ApiService.updateProductStock(
          productId,
          currentStock - 1,
          category: category,
          existingImageUrls: existingImageUrls,
        );
        _fetchVillagerProducts(); // Refresh products after selling

        if (response['lowStockAlert'] == true) {
          NotificationService.showSnackBar(
            'Product "${response['productName']}" is low in stock! Current: ${response['currentStock']}kg, Threshold: ${response['threshold']}kg',
          );
        }
      } catch (e) {
        NotificationService.showSnackBar('Failed to sell product: ${e.toString()}', isError: true);
      }
    }
  }

  void _deleteProduct(int productId) async {
    try {
      await ApiService.deleteProduct(productId);
      _fetchVillagerProducts(); // Refresh products after deleting
    } catch (e) {
      NotificationService.showSnackBar('Failed to delete product: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String? currentUserRole = authProvider.user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farm Products'),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVillagerProducts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              AudioService.playClickSound();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _villagerProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products added yet.'));
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.75,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final product = snapshot.data![index];
                return ProductCard(
                  product: product,
                  onSell: _sellProduct,
                  onDelete: _deleteProduct,
                  userRole: currentUserRole,
                  onEdit: () => _editProduct(product['id']), // Pass onEdit callback
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddNewProduct,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
